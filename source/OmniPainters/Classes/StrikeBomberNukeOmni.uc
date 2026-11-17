class StrikeBomberNukeOmni extends ONSAutoBomber;

var Controller InstigatorController;	// painter's Controller; survives pawn death / vehicle entry

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if ( Role == ROLE_Authority && Instigator != None )
		InstigatorController = Instigator.Controller;
}

// ONSAutoBomber.Timer, but hands the painter's Controller and team to each bomb:
// Projectile.PostBeginPlay only reads them from Instigator, which may have no Controller by now.
function Timer()
{
	local Controller C;
	local Projectile P;

	if (FRand() < 0.5)
	{
		//high skill enemies who don't have anything else to shoot at will try to shoot bomber down
		for (C = Level.ControllerList; C != None; C = C.NextController)
			if ( AIController(C) != None && C.Pawn != None && C.GetTeamNum() != Team && AIController(C).Skill >= 5.0
			     && !C.Pawn.IsFiring() && (C.Enemy == None || !C.LineOfSightTo(C.Enemy)) && C.Pawn.CanAttack(self) )
			{
				C.Focus = self;
				C.FireWeaponAt(self);
			}
	}

	if (VSize(Location - BombTargetCenter) < BombRange)
	{
		//drop a bomb
		P = spawn(BombClass,,, Location - ((CollisionHeight + BombClass.default.CollisionHeight) * vect(0,0,2)), rotator(vect(0,0,-1)));
		if ( P != None )
		{
			P.InstigatorController = InstigatorController;
			if ( RedeemerProjectile(P) != None )
				RedeemerProjectile(P).Team = Team;
		}
		Velocity = Normal(Velocity) * MinSpeed;
		Acceleration = vect(0,0,0);
	}
}

// Actor.HurtRadius plus Projectile-style delayed instigator handling (used when shot down).
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local Actor Victims;
	local float damageScale, dist;
	local vector dir;
	local Controller DelayedC, DriverC;

	if ( bHurtEntry )
		return;

	if ( Instigator != None && Instigator.Controller != None )
		DriverC = Instigator.Controller;
	else
	{
		DelayedC = InstigatorController;
		DriverC = DelayedC;
	}

	bHurtEntry = true;
	foreach VisibleCollidingActors( class'Actor', Victims, DamageRadius, HitLocation )
	{
		if ( (Victims != self) && (Victims.Role == ROLE_Authority) && !Victims.IsA('FluidSurfaceInfo') )
		{
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
			if ( DelayedC != None )
				Victims.SetDelayedDamageInstigatorController(DelayedC);
			Victims.TakeDamage
			(
				damageScale * DamageAmount,
				Instigator,
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				(damageScale * Momentum * dir),
				DamageType
			);
			if ( DriverC != None && Vehicle(Victims) != None && Vehicle(Victims).Health > 0 )
				Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, DriverC, DamageType, Momentum, HitLocation);
		}
	}
	bHurtEntry = false;
}

defaultproperties
{
     BombRange=330.000000
     BombClass=Class'OmniPainters.NuclearBombOmni'
}
