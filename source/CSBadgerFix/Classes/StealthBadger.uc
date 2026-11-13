//=============================================================================
// StealthBadger.
//=============================================================================
class StealthBadger extends Badger;

// "Stealth" badger that becomes invisible when not moving or firing.

var(Stealth) Material InvisibleMaterial;	// Material applied to vehicle when invisible
var(Stealth) Float MinVelocityForInvis;		// Minimum velocity to consider the vehicle "stopped"
var(Stealth) Float FireVisibleTime;			// How long after firing to stay visible
var(Stealth) Sound CloakSound;				// Sound played when cloaking
var(Stealth) Sound UnCloakSound;			// Sound played when decloaking
var(Stealth) Float StealthCheckInterval;	// How often (seconds) the cloak state is re-checked while occupied

// Internal vars
var bool bInvisible;
var float InvisiFireTime;
var Emitter MutantFX;

// Replication Block
replication
{
	// When we become invisible, server sets bInvisible to true and replicates to client.
	// Client sets invisibility skins in PostNetReceive after being updated on bInvisible.
	unreliable if (Role == ROLE_Authority && bNetDirty)
		bInvisible;
}

// SetInvisibility
// Turns visibility on or off. Sets bInvisible and applies necessary skins.
function SetInvisibility(bool bInvis)
{
	// Only do this as ROLE_Authority.
	// bInvisible will replicate to clients and they will update skins with PostNetReceive.
	if (Role < ROLE_Authority)
		return;

	if (bInvis != bInvisible)
	{
		bInvisible = bInvis;
		if (bInvis == true)
		{
			Visibility = 0;
//			AmbientSound = None;
			PlaySound(CloakSound);
			SoundVolume = 32;
			Skins[0] = InvisibleMaterial;
			WeaponPawns[0].Visibility = 0;
			WeaponPawns[0].Gun.Skins[0] = InvisibleMaterial;
			Weapons[0].Skins[0] = InvisibleMaterial;
			Weapons[0].RepSkin = InvisibleMaterial;
            //bDrawVehicleShadow=false;
		}
		else
		{
			Visibility = default.Visibility;
			WeaponPawns[0].Visibility = WeaponPawns[0].default.Visibility;
//			AmbientSound = IdleSound;
			SoundVolume = 255;
			PlaySound(UncloakSound);
		    if (Team == 0 && RedSkin != None)
			{
	    	    Skins[0] = RedSkin;
				WeaponPawns[0].Gun.Skins[0] = RedSkin;
				Weapons[0].Skins[0] = RedSkin;
				Weapons[0].RepSkin = RedSkin;
			}
		    else if (Team == 1 && BlueSkin != None)
			{
	    	    Skins[0] = BlueSkin;
				WeaponPawns[0].Gun.Skins[0] = BlueSkin;
				Weapons[0].Skins[0] = BlueSkin;
				Weapons[0].RepSkin = BlueSkin;
			}
            //bDrawVehicleShadow=true;
		}
	}
}

// PostNetReceive
// Net clients receive bInvisible and update skins accordingly.
simulated event PostNetReceive()
{
	if (bInvisible)
	{
		Skins[0] = InvisibleMaterial;
		WeaponPawns[0].Gun.Skins[0] = InvisibleMaterial;
//		Weapons[0].Skins[0] = InvisibleMaterial;
	}
	else
	{
	    if (Team == 0 && RedSkin != None)
		{
    	    Skins[0] = RedSkin;
			WeaponPawns[0].Gun.Skins[0] = RedSkin;
//			Weapons[0].Skins[0] = RedSkin;
		}
	    else if (Team == 1 && BlueSkin != None)
		{
    	    Skins[0] = BlueSkin;
			WeaponPawns[0].Gun.Skins[0] = BlueSkin;
//			Weapons[0].Skins[0] = BlueSkin;
		}
	}
}

// KDriverEnter
// Driver seat taken: start the stealth checks.
function KDriverEnter(Pawn P)
{
	Super.KDriverEnter(P);
	OccupantEntered();
}

// OccupantEntered
// Called when someone takes the driver seat or the gunner seat (StealthBadgerTurretPawn).
// Starts the stealth checks and updates the cloak right away.
function OccupantEntered()
{
	SetTimer(StealthCheckInterval, true);
	Timer();
}

// Died
// Stop the stealth checks and turn visible again when the vehicle is destroyed.
// Must happen before Super: ONSVehicle.Died empties WeaponPawns.
function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	SetTimer(0.0, false);
	if (bInvisible)
		SetInvisibility(false);
	Super.Died(Killer, damageType, HitLocation);
}

// WeaponFired
// Called by this vehicle's weapons. Stay visible while firing.
function WeaponFired()
{
	InvisiFireTime = Level.TimeSeconds;
	if (bInvisible)
		SetInvisibility(false);
}

// Timer
// Update visibility while anyone is in either seat. A Timer is used rather than Tick:
// Vehicle disables Tick whenever the driver seat is empty (DrivingStatusChanged), so a
// Tick never runs with only a gunner inside, and this doesn't need to run every frame.
event Timer()
{
	local bool bInvis;

	// Nobody in either seat: uncloak and stop checking until someone gets in.
	// Done here rather than on exit because a seat switch empties the old seat
	// before filling the new one, which would uncloak and re-cloak.
	if (Driver == None && WeaponPawns[0].Driver == None)
	{
		SetTimer(0.0, false);
		if (bInvisible)
			SetInvisibility(false);
		return;
	}

	// Stay visible a set period of time after firing.
	if (InvisiFireTime > 0 && Level.TimeSeconds - InvisiFireTime < FireVisibleTime)
		return;

	bInvis = VSize(Velocity) <= MinVelocityForInvis;
	if (bInvis != bInvisible)
		SetInvisibility(bInvis);
}

defaultproperties
{
     InvisibleMaterial=Shader'MoreBadgers.Stealth.InvisiBadger'
     MinVelocityForInvis=999999.000000
     FireVisibleTime=1.000000
     StealthCheckInterval=0.100000
     CloakSound=Sound'ONSBPSounds.ShockTank.ShieldActivate'
     UnCloakSound=Sound'ONSBPSounds.ShockTank.ShieldOff'
     GearRatios(0)=-1.000000
     GearRatios(1)=0.800000
     GearRatios(2)=1.000000
     GearRatios(3)=1.200000
     GearRatios(4)=1.600000
     DustSlipRate=0.000000
     DustSlipThresh=0.000000
     bMakeBrakeLights=False
     DaredevilThreshInAirTime=1.200000
     DriverWeapons(0)=(WeaponClass=Class'CSBadgerFix.StealthBadgerMinigun')
     PassengerWeapons(0)=(WeaponPawnClass=Class'CSBadgerFix.StealthBadgerTurretPawn')
     RedSkin=Texture'MoreBadgers.Stealth.DarkBadger_Red'
     BlueSkin=Texture'MoreBadgers.Stealth.DarkBadger_Blue'
     HeadlightCoronaMaterial=None
     HeadlightProjectorMaterial=None
     HeadlightProjectorScale=0.000000
     Begin Object Class=SVehicleWheel Name=SVehicleWheel12
         bPoweredWheel=True
         bHandbrakeWheel=True
         BoneName="RightRearTIRe"
         BoneRollAxis=AXIS_Y
         BoneOffset=(X=-20.000000)
         WheelRadius=26.000000
         SupportBoneName="RightRearSTRUT"
     End Object
     Wheels(0)=SVehicleWheel'CSBadgerFix.SVehicleWheel12'

     Begin Object Class=SVehicleWheel Name=SVehicleWheel13
         bPoweredWheel=True
         bHandbrakeWheel=True
         BoneName="LeftRearTIRE"
         BoneRollAxis=AXIS_Y
         BoneOffset=(X=-20.000000)
         WheelRadius=26.000000
         SupportBoneName="LeftRearSTRUT"
     End Object
     Wheels(1)=SVehicleWheel'CSBadgerFix.SVehicleWheel13'

     Begin Object Class=SVehicleWheel Name=SVehicleWheel14
         bPoweredWheel=True
         SteerType=VST_Steered
         BoneName="RightFrontTIRE"
         BoneRollAxis=AXIS_Y
         BoneOffset=(X=20.000000)
         WheelRadius=26.000000
         SupportBoneName="RightFrontSTRUT"
     End Object
     Wheels(2)=SVehicleWheel'CSBadgerFix.SVehicleWheel14'

     Begin Object Class=SVehicleWheel Name=SVehicleWheel15
         bPoweredWheel=True
         SteerType=VST_Steered
         BoneName="LeftFrontTIRE"
         BoneRollAxis=AXIS_Y
         BoneOffset=(X=20.000000)
         WheelRadius=26.000000
         SupportBoneName="LeftFrontSTRUT"
     End Object
     Wheels(3)=SVehicleWheel'CSBadgerFix.SVehicleWheel15'

     VehicleMass=5.000000
     VehicleNameString="Stealth Badger"
     HealthMax=450.000000
     Health=450
     SoundVolume=255
     SoundPitch=48
     SoundRadius=100.000000
     TransientSoundVolume=0.100000
     TransientSoundRadius=300.000000
     bNetNotify=True
     bDrawVehicleShadow=false
     Begin Object Class=KarmaParamsRBFull Name=KarmaParamsRBFull4
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
         KCOMOffset=(X=0.0,Y=0.0,Z=-0.9)

     End Object
     KParams=KarmaParamsRBFull'CSBadgerFix.KarmaParamsRBFull4'

}
