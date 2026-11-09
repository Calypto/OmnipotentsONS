//=============================================================================
// LinkBadger2.
//=============================================================================
class LinkBadger extends MyBadger;

// Green -- Combiner'UT2004Weapons.Shaders.Combiner12'
// Blue -- Combiner'UT2004Weapons.Shaders.Combiner15'
// Red -- Combiner'UT2004Weapons.RedLink.Combiner12'
// Gold -- Combiner'UT2004Weapons.Shaders.Combiner17'

// ============================================================================
// Consts
// ============================================================================
const LINK_DECAY_TIME = 0.250000;			// How long after the last teammate heal we keep counting linkers

// ============================================================================
// Properties
// ============================================================================

// 0 = Red, 1 = Blue
var() array<Material> LinkSkin_Gold, LinkSkin_Green, LinkSkin_Red, LinkSkin_Blue;

// ============================================================================
// Internal vars
// ============================================================================

var float LastLinkedTime;					// Last time a teammate's link beam healed us
var int Links;
var bool bLinking;							// True if we're linking a vehicle/node/player
var bool bBotHealing;
var bool bBeaming;							// True if utilizing alt-fire

var LinkAttachment.ELinkColor OldLinkColor;

var LinkBeamEffect Beam;

// Last button pressed wins vars
enum EFirePriority
{
    FP_None,
    FP_Primary,
    FP_Alt
};
var EFirePriority FirePriority;
var bool bPrimaryWasDown;
var bool bAltWasDown;

var int ExportLinks; // Links our link target is credited with

replication
{
    unreliable if (Role == ROLE_Authority && bNetDirty)
        Links, bLinking, Beam, bBeaming;
}

simulated function PostNetBeginPlay()
{
    PassengerWeapons.Length = 0;
    super.PostNetBeginPlay();
}

// ============================================================================
// ============================================================================
simulated function UpdateLinkColor( LinkAttachment.ELinkColor Color )
{
	local int i;

	// Don't waste cycles continually switching out for the same skin
	if (Color != OldLinkColor)
	{
		switch ( Color )
		{
			case LC_Gold	:	Skins[0] = LinkSkin_Gold[Team];		break;
			case LC_Green	:	Skins[0] = LinkSkin_Green[Team];	break;
			case LC_Red		: 	Skins[0] = LinkSkin_Red[Team];		break;
			case LC_Blue	: 	Skins[0] = LinkSkin_Blue[Team];		break;
		}
		OldLinkColor = Color;
	}

	// Update weapon colors too
	for (i = 0; i < Weapons.Length; i++)
		if (ONSLinkTankWeapon(Weapons[i]) != None)
			ONSLinkTankWeapon(Weapons[i]).UpdateLinkColor(Color);
}

// ============================================================================
// HealDamage
// When someone links the tank, record it and add it to the Linkers
// After a certain time period passes, remove that linker if they aren't linking anymore
// ============================================================================
/*
function bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType)
{
	local int i;
	local bool bFound;
	
	if (Healer == None || Healer.bDeleteMe)
		return false;

	// If allied teammate, possibly add them to a link list
	if (TeamLink(Healer.GetTeamNum()))
	{
		for (i = 0; i < Linkers.Length; i++)
		{
			if (Linkers[i].LinkingController != None && Linkers[i].LinkingController == Healer)
			{
				bFound = true;
				Linkers[i].LastLinkTime = Level.TimeSeconds;
				// If other players are linking that pawn, record it
				if ( (Linkers[i].LinkingController.Pawn != None) && (Linkers[i].LinkingController.Pawn.Weapon != None) && (LinkGun(Linkers[i].LinkingController.Pawn.Weapon) != None) )
					Linkers[i].NumLinks = LinkGun(Linkers[i].LinkingController.Pawn.Weapon).Links;
				else
					Linkers[i].NumLinks = 0;
			}
		}
		if (!bFound)
		{
			Linkers.Insert(0,1);
			Linkers[0].LinkingController = Healer;
			Linkers[0].LastLinkTime = Level.TimeSeconds;
			// If other players are linking that pawn, record it
			if ( (Linkers[i].LinkingController.Pawn != None) && (Linkers[i].LinkingController.Pawn.Weapon != None) && (LinkGun(Linkers[i].LinkingController.Pawn.Weapon) != None) )
				Linkers[0].NumLinks = LinkGun(Linkers[0].LinkingController.Pawn.Weapon).Links;
			else
				Linkers[0].NumLinks = 0;
		}
	}

	return super.HealDamage(Amount, Healer, DamageType);
}
*/

// Teammates' link beams heal us every fire interval, so a recent heal means
// someone is linking us and ResetLinks has something to count
function bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType)
{
    if (Healer == None || Healer.bDeleteMe)
        return false;

    if (Healer != Controller && TeamLink(Healer.GetTeamNum()))
        LastLinkedTime = Level.TimeSeconds;

    return super.HealDamage(Amount, Healer, DamageType);
}

// ============================================================================
// GetLinks
// Returns number of linkers
// ============================================================================
function int GetLinks()
{
	return Links;
}

// ============================================================================
// ResetLinks
// Recount our linkers from the live link beams, called during tick
// ============================================================================
function ResetLinks()
{
    if (Level.TimeSeconds - LastLinkedTime > LINK_DECAY_TIME)
    {
        Links = 0;
        ExportLinks = 0;
    }
    else
        Links = CountLinkers(ExportLinks);
}

// ============================================================================
// CountLinkers
// Copy of LinkVehiclesOmni.LinkChain.CountLinkers so this package stays
// independent. Returns how many distinct pawns beam into us, directly or
// through a chain; each pawn counts once, so beams that loop back cannot
// inflate the count. Export receives the same count minus the pawns that only
// reach us through our own link target, which already counts those itself.
// ============================================================================
function int CountLinkers(out int Export)
{
    local LinkBeamEffect B;
    local Pawn S, D, Target;
    local Pawn Src[32], Dst[32], Seen[33];
    local byte ViaTarget[33];
    local int NumEdges, NumSeen, NumVia, Head, i;

    foreach DynamicActors(class'LinkBeamEffect', B)
    {
        D = B.LinkedPawn;
        if (D == None)
            continue;

        // Vehicle beams are owned by the vehicle (or passenger seat), infantry beams by the player
        S = Pawn(B.Owner);
        if (S == None)
            S = B.Instigator;
        if (S == None)
            continue;
        if (S.DrivenVehicle != None)
            S = S.DrivenVehicle;

        // A link onto a driver or a passenger seat counts for the vehicle itself
        if (D.DrivenVehicle != None)
            D = D.DrivenVehicle;
        if (ONSWeaponPawn(D) != None && ONSWeaponPawn(D).VehicleBase != None)
            D = ONSWeaponPawn(D).VehicleBase;

        if (S == self)
        {
            Target = D;
            continue;
        }

        // A pawn links a single target, so another beam from the same source is the same edge
        for (i = 0; i < NumEdges; i++)
            if (Src[i] == S)
                break;
        if (i < NumEdges || NumEdges == ArrayCount(Src))
            continue;

        Src[NumEdges] = S;
        Dst[NumEdges] = D;
        NumEdges++;
    }

    // Walk the beams backwards from us. Each source has one edge and our own
    // beam is left out, so every pawn is reached exactly once.
    Seen[0] = self;
    NumSeen = 1;
    for (Head = 0; Head < NumSeen; Head++)
    {
        for (i = 0; i < NumEdges; i++)
        {
            if (Dst[i] == Seen[Head])
            {
                Seen[NumSeen] = Src[i];
                if (ViaTarget[Head] != 0 || Src[i] == Target)
                {
                    ViaTarget[NumSeen] = 1;
                    NumVia++;
                }
                NumSeen++;
            }
        }
    }

    Export = NumSeen - 1 - NumVia;
    return NumSeen - 1;
}

// ============================================================================
// Tick
// Recount our linkers every tick
// ============================================================================
simulated event Tick(float DT)
{
	Super.Tick(DT);

	if (bBotHealing)
		AltFire();

	if (Role == ROLE_Authority)
		ResetLinks();
	//else
	//	log(Level.TimeSeconds@Self@"Beam Effect:"@Beam,'KDebug');

	//log(self@"tick links"@links,'KDebug');

	//log(Level.TimeSeconds@Self@"TICK -- Linking"@bLinking,'KDebug');
	// When linked, always show gold link panels
	if (Links > 0)
		UpdateLinkColor(LC_Gold);
	// If linking a vehicle/player/node, show team-colored link panels
	else if (bLinking && Team == 0)
		UpdateLinkColor(LC_Red);
	else if (bLinking && Team == 1)
		UpdateLinkColor(LC_Blue);
	// Show regular green link panels
	else
		UpdateLinkColor(LC_Green);

	if (Controller == None)
	{
		bPrimaryWasDown = false;
		bAltWasDown = false;
		FirePriority = FP_None;
	}
	else
	{
		if (Controller.bFire == 0)
			bPrimaryWasDown = false;

		if (Controller.bAltFire == 0)
			bAltWasDown = false;

		// If one button was released, transfer priority to whichever button is still held
		if (Controller.bFire == 0 && Controller.bAltFire == 0)
			FirePriority = FP_None;
		else if (Controller.bFire != 0 && Controller.bAltFire == 0)
			FirePriority = FP_Primary;
		else if (Controller.bFire == 0 && Controller.bAltFire != 0)
			FirePriority = FP_Alt;
	}
}

function Fire(optional float F)
{
    if (!bPrimaryWasDown)
    {
        bPrimaryWasDown = true;
        SetFirePriority(FP_Primary);
    }

    if (FirePriority == FP_Primary)
        Super.Fire(F);
}

function AltFire(optional float F)
{
    if (!bAltWasDown)
    {
        bAltWasDown = true;
        SetFirePriority(FP_Alt);
    }

    if (FirePriority == FP_Alt)
        Super(ONSVehicle).AltFire(F);
}

simulated function SetFirePriority(EFirePriority NewPriority)
{
    if (FirePriority == NewPriority)
        return;

    FirePriority = NewPriority;

    if (FirePriority == FP_Primary)
    {
        if (bWeaponIsAltFiring)
        {
            if (Role == ROLE_Authority)
                VehicleCeaseFire(true);
            if (Level.NetMode != NM_DedicatedServer)
                ClientVehicleCeaseFire(true);
        }
    }
    else if (FirePriority == FP_Alt)
    {
        if (bWeaponIsFiring)
        {
            if (Role == ROLE_Authority)
                VehicleCeaseFire(false);
            if (Level.NetMode != NM_DedicatedServer)
                ClientVehicleCeaseFire(false);
        }
    }
}

function VehicleCeaseFire(bool bWasAltFire)
{
    Super(ONSVehicle).VehicleCeaseFire(bWasAltFire);

    if (bWasAltFire && Weapons.Length > 0 && Weapons[0] != None)
        Weapons[0].WeaponCeaseFire(Controller, true);
}

simulated function ClientVehicleCeaseFire(bool bWasAltFire)
{
    Super(ONSVehicle).ClientVehicleCeaseFire(bWasAltFire);

    if (bWasAltFire && Weapons.Length > 0 && Weapons[0] != None)
        Weapons[0].WeaponCeaseFire(Controller, true);
}

static function StaticPrecache(LevelInfo L)
{
    Default.PassengerWeapons.Length = 0;
    super(ONSTreadCraft).StaticPrecache(L);

//	L.AddPrecacheMaterial(Material'ONSToys1Tex.LinkTankTex.LinkTankBodyBlue');
//	L.AddPrecacheMaterial(Material'ONSToys1Tex.LinkTankTex.LinkTankTread');
	L.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerGreen');
	L.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerRed');
	L.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerBlue');
	L.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerYellow');
//	L.AddPrecacheMaterial(Material'AS_Weapons_TX.LinkTurret.LinkTurret_skin1');
//	L.AddPrecacheMaterial(Material'AS_Weapons_TX.LinkTurret.LinkTurret_skin2');

	// FX
}

simulated function UpdatePrecacheStaticMeshes()
{
//	Level.AddPrecacheStaticMesh( StaticMesh'AW-2004Particles.Weapons.PlasmaSphere' );

	super.UpdatePrecacheStaticMeshes();
}

simulated function UpdatePrecacheMaterials()
{
//	Level.AddPrecacheMaterial(Material'ONSToys1Tex.LinkTankTex.LinkTankBodyBlue');
//	Level.AddPrecacheMaterial(Material'ONSToys1Tex.LinkTankTex.LinkTankTread');
	Level.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerGreen');
	Level.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerRed');
	Level.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerBlue');
	Level.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerYellow');
//	Level.AddPrecacheMaterial(Material'AS_Weapons_TX.LinkTurret.LinkTurret_skin1');
//	Level.AddPrecacheMaterial(Material'AS_Weapons_TX.LinkTurret.LinkTurret_skin2');

	// FX

	super(ONSTreadCraft).UpdatePrecacheMaterials();
}

function bool RecommendLongRangedAttack()
{
	return true;
}

// show linker count on the HUD pooty 12/2023
simulated function DrawHUD(Canvas C)
{
	local PlayerController PC;
	local HudCTeamDeathMatch PlayerHud;

	//Hax. :P
    Super.DrawHUD(C);
	PC = PlayerController(Controller);
	if (Health < 1 || PC == None || PC.myHUD == None || PC.MyHUD.bShowScoreboard)
		return;
		
	PlayerHud=HudCTeamDeathMatch(PC.MyHud);
	
	if ( Links > 0 )
	{
		PlayerHud.totalLinks.value = Links;
		PlayerHud.DrawSpriteWidget (C, PlayerHud.LinkIcon);
		PlayerHud.DrawNumericWidget (C, PlayerHud.totalLinks, PlayerHud.DigitsBigPulse);
		PlayerHud.totalLinks.value = Links;
	}
}



defaultproperties
{
     LinkSkin_Gold(0)=Texture'MoreBadgers.LinkBadger.LinkBadgerRed'
     LinkSkin_Gold(1)=Texture'MoreBadgers.LinkBadger.LinkBadgerBlue'
     LinkSkin_Green(0)=Texture'MoreBadgers.LinkBadger.LinkBadgerRed'
     LinkSkin_Green(1)=Texture'MoreBadgers.LinkBadger.LinkBadgerBlue'
     LinkSkin_Red(0)=Texture'MoreBadgers.LinkBadger.LinkBadgerRed'
     LinkSkin_Blue(1)=Texture'MoreBadgers.LinkBadger.LinkBadgerBlue'
     DriverWeapons(0)=(WeaponClass=Class'CSBadgerFix.ONSLinkBadgerWeapon',WeaponBone="TurretSpawn")
     PassengerWeapons(0)=(WeaponPawnClass=Class'CSBadgerFix.BadgerMinigun',WeaponBone="MinigunSpawn")

     RedSkin=Texture'MoreBadgers.LinkBadger.LinkBadgerRed'
     BlueSkin=Texture'MoreBadgers.LinkBadger.LinkBadgerBlue'
     Begin Object Class=SVehicleWheel Name=SVehicleWheel32
         bPoweredWheel=True
         bHandbrakeWheel=True
         BoneName="RightRearTIRe"
         BoneRollAxis=AXIS_Y
         BoneOffset=(X=-20.000000)
         WheelRadius=26.000000
         SupportBoneName="RightRearSTRUT"
     End Object
     Wheels(0)=SVehicleWheel'CSBadgerFix.SVehicleWheel32'

     Begin Object Class=SVehicleWheel Name=SVehicleWheel33
         bPoweredWheel=True
         bHandbrakeWheel=True
         BoneName="LeftRearTIRE"
         BoneRollAxis=AXIS_Y
         BoneOffset=(X=-20.000000)
         WheelRadius=26.000000
         SupportBoneName="LeftRearSTRUT"
     End Object
     Wheels(1)=SVehicleWheel'CSBadgerFix.SVehicleWheel33'

     Begin Object Class=SVehicleWheel Name=SVehicleWheel34
         bPoweredWheel=True
         SteerType=VST_Steered
         BoneName="RightFrontTIRE"
         BoneRollAxis=AXIS_Y
         BoneOffset=(X=20.000000)
         WheelRadius=26.000000
         SupportBoneName="RightFrontSTRUT"
     End Object
     Wheels(2)=SVehicleWheel'CSBadgerFix.SVehicleWheel34'

     Begin Object Class=SVehicleWheel Name=SVehicleWheel35
         bPoweredWheel=True
         SteerType=VST_Steered
         BoneName="LeftFrontTIRE"
         BoneRollAxis=AXIS_Y
         BoneOffset=(X=20.000000)
         WheelRadius=26.000000
         SupportBoneName="LeftFrontSTRUT"
     End Object
     Wheels(3)=SVehicleWheel'CSBadgerFix.SVehicleWheel35'

     VehiclePositionString="in a Link Badger"
     VehicleNameString="Link Badger"
     HealthMax=700.000000
     Health=700
     Begin Object Class=KarmaParamsRBFull Name=KarmaParamsRBFull8
         KInertiaTensor(0)=1.000000
         KInertiaTensor(3)=3.000000
         KInertiaTensor(5)=3.500000
         KLinearDamping=0.050000
         KAngularDamping=0.050000
         KStartEnabled=True
         bKNonSphericalInertia=True
         bHighDetailOnly=False
         bClientOnly=False
         bKDoubleTickRate=True
         bDestroyOnWorldPenetrate=True
         bDoSafetime=True
         KFriction=0.500000
         KImpactThreshold=500.000000
         KCOMOffset=(X=0.0,Y=0.0,Z=-1.35)
     End Object
     KParams=KarmaParamsRBFull'CSBadgerFix.KarmaParamsRBFull8'

}
