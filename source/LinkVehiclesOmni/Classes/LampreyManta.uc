
class LampreyManta extends ONSHoverBike


    placeable;

#exec OBJ LOAD FILE=..\textures\VMVehicles-TX.utx

var bool bLinking;
var int Links;
var int ExportLinks;		// Links our link target is credited with
var float LastLinkedTime;	// Last time a teammate's link beam healed us

const LINK_DECAY_TIME = 0.250000;	// How long after the last teammate heal we keep counting linkers



replication
{
    unreliable if (Role == ROLE_Authority)
        bLinking, Links;
}


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

simulated function Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);

    if (Role == ROLE_Authority)
        ResetLinks();
}

// Recount our linkers from the live link beams
function ResetLinks()
{
    if (Level.TimeSeconds - LastLinkedTime > LINK_DECAY_TIME)
    {
        Links = 0;
        ExportLinks = 0;
    }
    else
        Links = class'LinkChain'.static.CountLinkers(self, ExportLinks);
}



defaultproperties
{
	/* Props from flying manta eg. based on ONSAttackCraft
	  bDrawMeshInFP=False
		 bCanFly = True
		 bFollowLookDir=True
     bCanHover=True
     bPCRelativeFPRotation=False
      TrailEffectPositions(0)=(X=-82.000000,Y=-24.000000,Z=40.000000)
     TrailEffectPositions(1)=(X=-82.000000,Y=24.000000,Z=40.000000)
     StreamerEffectOffset(0)=(X=-20.000000,Y=-28.000000,Z=-28.000000)
     StreamerEffectOffset(1)=(X=-20.000000,Y=28.000000,Z=-28.000000)
     StreamerEffectOffset(2)=(Y=-56.000000,Z=-16.000000)
     StreamerEffectOffset(3)=(Y=56.000000,Z=-16.000000)
     
   */  
   
   // Manta props modified
   // Manta defaults.
    //JumpDuration=0.220000
    // JumpForceMag=100.000000
    // JumpDelay=3.000000
   //     DuckForceMag=150.000000
   //RollTorqueTurnFactor=450.000000
    // RollTorqueStrafeFactor=50.000000
    // RollTorqueMax=12.500000
    // RollDamping=30.000000
     
     MaxPitchSpeed=800.000000
     JumpDuration=0.230000
     JumpForceMag=100.000000
     JumpDelay=3.1000
     DuckForceMag=150.000000
     RollTorqueStrafeFactor=50.000000
     RollTorqueMax=14.000000
     
     
     
     
     DriverWeapons(0)=(WeaponClass=Class'LampreyGun',WeaponBone="PlasmaGunAttachment")
     bHasAltFire=True
     
     
     RedSkin=Shader'LinkTank3Tex.Lamprey.LampreyChassisRED'
     BlueSkin=Shader'LinkTank3Tex.Lamprey.LampreyChassisBLUE'
        
        
     
     DriverDamageMult=0.000000
     VehiclePositionString="in a Lamprey Manta"
     VehicleNameString="Lamprey Manta 3.47"
     GroundSpeed=1450.000000
     // GroundSpeed=2000 //manta
     HealthMax=266.000000
     Health=200
     Mesh=SkeletalMesh'ONSVehicles-A.HoverBike'
     
     
     
   

}
