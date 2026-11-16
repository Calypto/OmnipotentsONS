//=============================================================================
// IonPlasmaBadgerBeamFire
// The Ion beam deals its damage over ~1.8s from this server-only actor, whose
// Instigator is the vehicle. If the driver exits or dies (or the vehicle is
// destroyed) during that time the vehicle has no Controller, so stock code
// gave no kill credit, skipped team damage protection and logged kills as
// suicides. Remember the firing Controller and hand it to victims the same
// way Projectile.HurtRadius does.
//=============================================================================
class IonPlasmaBadgerBeamFire extends ONSHoverTank_IonPlasma_BeamFire;

var Controller InstigatorController;

function PostBeginPlay()
{
	// Instigator (copied from the spawning weapon) is valid here; reflected
	// beams have it cleared right after spawning, so don't wait for AimAt.
	if (Instigator != None)
		InstigatorController = Instigator.Controller;
}

simulated function HurtRadius(float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
	local Actor Victims;
	local float damageScale, dist;
	local vector dir;
	local bool bLostInstigator;

	if (bHurtEntry)
		return;

	bHurtEntry = true;
	bLostInstigator = Instigator == None || Instigator.Controller == None;
	foreach VisibleCollidingActors(class'Actor', Victims, DamageRadius, HitLocation)
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if (Victims != Instigator && Victims != self && Victims.Role == ROLE_Authority && !Victims.IsA('FluidSurfaceInfo'))
		{
			dir = Victims.Location - HitLocation;
			dist = FMax(1, VSize(dir));
			dir = dir / dist;
			damageScale = 1 - FMax(0, (dist - Victims.CollisionRadius) / DamageRadius);
			if (bLostInstigator)
				Victims.SetDelayedDamageInstigatorController(InstigatorController);
			Victims.TakeDamage
			(
				damageScale * DamageAmount,
				Instigator,
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				damageScale * Momentum * dir,
				DamageType
			);
			if (Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
				Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, InstigatorController, DamageType, Momentum, HitLocation);
		}
	}
	bHurtEntry = false;
}

defaultproperties
{
     DamageType=Class'CSBadgerFix.DamTypeIonBadgerBlast'
}
