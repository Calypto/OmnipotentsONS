// ============================================================================
// LinkFlyer                                                        ItsMeAgain
// Main Class, Combo of Starbolt and LinkTank
//
// Do no damage after owner death

//log("Current Rotation="$WeaponFireRotation$" My Flag="$bMyFlag);
//
// ============================================================================
class ONSLinkFlyer extends ONSAttackCraft;

#exec OBJ LOAD FILE=..\textures\LinkFlyer_Tex.utx

// ============================================================================
// Consts
// ============================================================================
const LINK_DECAY_TIME=0.25;             // How long after the last teammate heal we keep counting linkers
const AI_HEAL_SEARCH=4096.0;            // Radius for bots to search for damaged actors while driving

// ============================================================================
// Internal Properties
// ============================================================================
var() array<Material> LinkSkin_Gold, LinkSkin_Green, LinkSkin_Red, LinkSkin_Blue;

// ============================================================================
// Internal vars
// ============================================================================
var float LastLinkedTime;               // Last time a teammate's link beam healed us
var int Links;
var bool bLinking;                      // True if we're linking a vehicle/node/player
var bool bBeaming;                      // True if utilizing alt-fire
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

//var bool bBotHealing;
//var LinkAttachment.ELinkColor OldLinkColor;

// ============================================================================
// Replication
// ============================================================================
replication
    {
    unreliable if (Role==ROLE_Authority && bNetDirty)
        Links, bLinking, Beam, bBeaming;
    }

    // ============================================================================
    // HealDamage
    // When someone links the Flyer, record it and add it to the Linkers
    // After a certain time period passes, remove that linker if they aren't linking anymore
    // ============================================================================
    /*
	function bool HealDamage(int Amount, Controller Healer, class<DamageType> DamageType)
        {
        local int i;
        local bool bFound;

        if (Healer==None||Healer.bDeleteMe)
            return false;

        // If allied teammate, possibly add them to a link list
        if (TeamLink(Healer.GetTeamNum()) && Healer != Controller)
            {
            for (i=0; i<Linkers.Length; i++)
                {
                if (Linkers[i].LinkingController!=None && Linkers[i].LinkingController==Healer)
                    {
                    bFound=true;
                    Linkers[i].LastLinkTime=Level.TimeSeconds;

                    // If other players are linking that pawn, record it
                    if ((Linkers[i].LinkingController.Pawn!=None)&&(Linkers[i].LinkingController.Pawn.Weapon!=None)&&(LinkGun(Linkers[i].LinkingController.Pawn.Weapon)!=None))
                        Linkers[i].NumLinks=LinkGun(Linkers[i].LinkingController.Pawn.Weapon).Links;
                    else
                        Linkers[i].NumLinks=0;
                    }
                }

            if (!bFound)
                {
                Linkers.Insert(0, 1);
                Linkers[0].LinkingController=Healer;
                Linkers[0].LastLinkTime=Level.TimeSeconds;

                // If other players are linking that pawn, record it
                if ((Linkers[i].LinkingController.Pawn!=None)&&(Linkers[i].LinkingController.Pawn.Weapon!=None)&&(LinkGun(Linkers[i].LinkingController.Pawn.Weapon)!=None))
                    Linkers[0].NumLinks=LinkGun(Linkers[0].LinkingController.Pawn.Weapon).Links;
                else
                    Linkers[0].NumLinks=0;
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
    //local float EnginePitch;
    //local KRigidBodyState BodyState;
    //local KarmaParams KP;
    //local bool bOnGround;
    //local int i;

    //Super.Tick(DT);

    // cp from HoverTank -- all we care about is not wildly varying the ambientsound of the beam
    //KGetRigidBodyState(BodyState);

    //if (Level.NetMode!=NM_DedicatedServer)
    //    {
    //    if (!bBeaming)
    //        {
    //        EnginePitch=64.0+VSize(Velocity)/MaxPitchSpeed * 64.0;
    //        SoundPitch=FClamp(EnginePitch, 64, 128);
    //        }
    //    else
    //        SoundPitch=64.0;
    //    }

    Super(ONSAttackCraft).Tick(DT);

    //if (bBotHealing)
    //    AltFire();

    if (Role==ROLE_Authority)
        ResetLinks();

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

    // ============================================================================
    //simulated function ClientKDriverLeave(PlayerController PC)
    //    {
    //    Super.ClientKDriverLeave(PC);

    //    bBeaming=false;
    //    //bWeaponIsAltFiring=false;
    //    PC.EndZoom();
    //    }

    // ============================================================================
    //function bool RecommendLongRangedAttack()
    //    {
    //    return true;
    //    }

    // ============================================================================
    // Precache
    // ============================================================================
    static function StaticPrecache(LevelInfo L)
        {
        Super.StaticPrecache(L);

        L.AddPrecacheMaterial(Material'LinkFlyer_Tex.LinkFlyer.LinkFlyerBodyRed');
        L.AddPrecacheMaterial(Material'LinkFlyer_Tex.LinkFlyer.LinkFlyerBodyBlue');

        L.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerGreen');
        L.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerRed');
        L.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerBlue');
        L.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerYellow');
        }

    // ============================================================================
    simulated function UpdatePrecacheStaticMeshes()
        {
        Super.UpdatePrecacheStaticMeshes();
        }

    // ============================================================================
    simulated function UpdatePrecacheMaterials()
        {
        Level.AddPrecacheMaterial(Material'LinkFlyer_Tex.LinkFlyer.LinkFlyerBodyRed');
        Level.AddPrecacheMaterial(Material'LinkFlyer_Tex.LinkFlyer.LinkFlyerBodyBlue');

        Level.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerGreen');
        Level.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerRed');
        Level.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerBlue');
        Level.AddPrecacheMaterial(Material'UT2004Weapons.NewWeaps.LinkPowerYellow');

        Super.UpdatePrecacheMaterials();
        }



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




    // ============================================================================
    // defaultproperties
    // ============================================================================

defaultproperties
{
     MaxPitchSpeed=2200.000000
     MaxThrustForce=170.000000
     MaxStrafeForce=130.000000
     MaxRiseForce=150.000000
     MaxYawRate=2.300000
     DriverWeapons(0)=(WeaponClass=Class'ONSLinkFlyer.LinkFlyerWeapon')
     RedSkin=Combiner'LinkFlyer_Tex.LinkFlyer.LinkFlyerCombinerRed'
     BlueSkin=Combiner'LinkFlyer_Tex.LinkFlyer.LinkFlyerCombinerBlue'
     DisintegrationEffectClass=None
     DisintegrationHealth=0.000000
     VehiclePositionString="in a Chupacabra"
     VehicleNameString="Chupacabra 1.52"
     GroundSpeed=2200.000000
     Health=325.00000
     HealthMax=350.000000
     Mesh=SkeletalMesh'LinkFlyer_Mesh.LinkFlyer.LinkFinal'
     CollisionRadius=130.000000
     Begin Object Class=KarmaParamsRBFull Name=KParams0
         KInertiaTensor(0)=1.000000
         KInertiaTensor(3)=3.000000
         KInertiaTensor(5)=3.500000
         KCOMOffset=(X=-0.250000)
         KLinearDamping=0.000000
         KAngularDamping=0.000000
         KStartEnabled=True
         bKNonSphericalInertia=True
         KActorGravScale=0.000000
         KMaxSpeed=2100.000000
         bHighDetailOnly=False
         bClientOnly=False
         bKDoubleTickRate=True
         bKStayUpright=True
         bKAllowRotate=True
         bDestroyOnWorldPenetrate=True
         bDoSafetime=True
         KFriction=0.500000
         KImpactThreshold=800.000000
     End Object
     KParams=KarmaParamsRBFull'ONSLinkFlyer.ONSLinkFlyer.KParams0'

}
