//===========================================================
// IonCannon that keeps crediting the painter after the painting
// pawn dies or enters a vehicle (both clear Pawn.Controller).
//===========================================================
class IonCannonOmni extends IonCannon;

var Controller InstigatorController;	// painter's Controller, captured when the strike is triggered

// Take over the designer-set properties of a stock (usually map-placed) cannon being replaced.
function CopyFrom(IonCannon C)
{
	FireSound = C.FireSound;
	IonEffectClass = C.IonEffectClass;
	Damage = C.Damage;
	MomentumTransfer = C.MomentumTransfer;
	DamageRadius = C.DamageRadius;
	if ( C.DamageType != class'DamTypeIonBlast' )
		DamageType = C.DamageType;
	ShakeRotMag = C.ShakeRotMag;
	ShakeRotRate = C.ShakeRotRate;
	ShakeRotTime = C.ShakeRotTime;
	ShakeOffsetMag = C.ShakeOffsetMag;
	ShakeOffsetRate = C.ShakeOffsetRate;
	ShakeOffsetTime = C.ShakeOffsetTime;
	TransientSoundVolume = C.TransientSoundVolume;
	TransientSoundRadius = C.TransientSoundRadius;
}

auto state Ready
{
	function bool CheckMark(Pawn Aimer, Vector TestMark, bool bFire)
	{
		// set before Super, which switches to FireSequence on success
		if ( bFire && Aimer != None )
			InstigatorController = Aimer.Controller;
		return Super.CheckMark(Aimer, TestMark, bFire);
	}
}

// Actor.HurtRadius plus Projectile-style delayed instigator handling.
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
	DamageType=Class'OmniPainters.DamTypeIonBlastOmni'
}
