//-----------------------------------------------------------
//
//-----------------------------------------------------------
class HospitalerShieldCannonProjectile extends ShockProjectile;

var ONSShockBall ONSShockBallEffect;
var HospitalerShieldCannon Cannon; // server only: the firing cannon (Owner is switched to its vehicle)
var Actor Hull;                    // the firing vehicle, kept in our Owner chain so we fly through it

replication
{
    reliable if (bNetInitial && Role == ROLE_Authority)
        Hull;
}

simulated function PostBeginPlay()
{
	Super(Projectile).PostBeginPlay();

    // Server: Owner is the firing cannon (clients have none yet). Native line checks, projectile movement
    // included, skip every actor in the mover's Owner chain, so owning the ball by the gun's vehicle lets it
    // pass through its own hull at no per-tick cost.
    if (Owner != None && Owner.Base != None)
    {
        Cannon = HospitalerShieldCannon(Owner);
        Hull = Owner.Base;
        SetOwner(Hull);
    }

    if ( Level.NetMode != NM_DedicatedServer )
	{
        ONSShockBallEffect = Spawn(class'ONSShockBall', self);
        ONSShockBallEffect.SetBase(self);
	}

	Velocity = Speed * Vector(Rotation); // starts off slower so combo can be done closer

    tempStartLoc = Location;
}

simulated function PostNetBeginPlay()
{
    Super.PostNetBeginPlay();

    // Clients: Owner only replicates to the owning connection, so join the hull to our Owner chain locally
    if (Hull != None && Owner != Hull)
        SetOwner(Hull);
}

simulated function Destroyed()
{
    if (ONSShockBallEffect != None)
    {
		if ( bNoFX )
			ONSShockBallEffect.Destroy();
		else
			ONSShockBallEffect.Kill();
	}

	Super.Destroyed();
}

simulated function DestroyTrails()
{
    if (ONSShockBallEffect != None)
        ONSShockBallEffect.Destroy();
}

simulated function ProcessTouch (Actor Other, vector HitLocation)
{
    if (Cannon != None && Other == Cannon.ShockShield)
        ProximityExplode();
    else
        Super.ProcessTouch(Other, HitLocation);
}

simulated singular function HitWall(vector HitNormal, actor Wall)
{
	local PlayerController PC;

    if (Cannon != None && Wall == Cannon.ShockShield)
        ProximityExplode();
    else
    {
        if ( Role == ROLE_Authority )
    	{
    		if ( !Wall.bStatic && !Wall.bWorldGeometry )
    		{
    			if ( Instigator == None || Instigator.Controller == None )
    				Wall.SetDelayedDamageInstigatorController( InstigatorController );
    			Wall.TakeDamage( Damage, instigator, Location, MomentumTransfer * Normal(Velocity), MyDamageType);
    			if (DamageRadius > 0 && Vehicle(Wall) != None && Vehicle(Wall).Health > 0)
    				Vehicle(Wall).DriverRadiusDamage(Damage, DamageRadius, InstigatorController, MyDamageType, MomentumTransfer, Location);
    			HurtWall = Wall;
    		}
    		MakeNoise(1.0);
    	}
    	Explode(Location + ExploWallOut * HitNormal, HitNormal);
    	if ( (ExplosionDecal != None) && (Level.NetMode != NM_DedicatedServer)  )
    	{
    		if ( ExplosionDecal.Default.CullDistance != 0 )
    		{
    			PC = Level.GetLocalPlayerController();
    			if ( !PC.BeyondViewDistance(Location, ExplosionDecal.Default.CullDistance) )
    				Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
    			else if ( (Instigator != None) && (PC == Instigator.Controller) && !PC.BeyondViewDistance(Location, 2*ExplosionDecal.Default.CullDistance) )
    				Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
    		}
    		else
    			Spawn(ExplosionDecal,self,,Location, rotator(-HitNormal));
    	}
    	HurtWall = None;
    }
}

simulated function Explode(vector HitLocation,vector HitNormal)
{
    SuperExplosion();
}

function ProximityExplode()
{
//	 log(self@"ProximityExplode Called");
    PlaySound(ComboSound, SLOT_None,1.0,,800);
    Cannon.ProximityExplosion();
    Destroy();
}

function SuperExplosion()
{
	local actor HitActor;
	local vector HitLocation, HitNormal;
 
//log(self@":SuperExplosion-JustbeforeHurtRadius");

	HurtRadius(ComboDamage, ComboRadius, class'DamTypeShockTankShockBall', ComboMomentumTransfer, Location );

	Spawn(class'ONSShockTankShockExplosion');
	if ( (Level.NetMode != NM_DedicatedServer) && EffectIsRelevant(Location,false) )
	{
		HitActor = Trace(HitLocation, HitNormal,Location - Vect(0,0,120), Location,false);
		if ( HitActor != None )
			Spawn(class'ComboDecal',self,,HitLocation, rotator(vect(0,0,-1)));
	}
	PlaySound(ComboSound, SLOT_None,1.0,,800);
    DestroyTrails();
    Destroy();
}



defaultproperties
{
     ComboSound=Sound'ONSBPSounds.ShockTank.ShockBallExplosion'
     ComboRadius=450.000000
     ComboMomentumTransfer=500000.000000
          
     Speed=11000.000000
     MaxSpeed=11000.000000
     Damage=175.000000
     DamageRadius=275.000000
     DrawType=DT_None
     AmbientSound=Sound'ONSBPSounds.ShockTank.ShockBallAmbient'
     Texture=None
     DrawScale=3.000000
     Skins(0)=None
     CollisionRadius=0.000000
     CollisionHeight=0.000000
     

}
