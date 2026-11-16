//=============================================================================
// DamTypeIonBadgerBlast
// Ion Plasma Badger beam blast. bDelayedDamage lets Pawn/Vehicle/PowerCore
// TakeDamage and TeamGame.ReduceDamage fall back to the victim's
// DelayedDamageInstigatorController when the beam's Instigator (the vehicle)
// no longer has a Controller (driver exited/died, vehicle destroyed).
//=============================================================================
class DamTypeIonBadgerBlast extends DamTypeIonTankBlast
	abstract;

defaultproperties
{
     VehicleClass=Class'CSBadgerFix.IonPlasmaBadger'
     bDelayedDamage=True
}
