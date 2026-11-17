//===========================================================
// Ion blast damage type for IonCannonOmni.
// bDelayedDamage lets victims fall back to the painter's Controller
// (DelayedDamageInstigatorController) once the painting pawn has
// died or entered a vehicle.
//===========================================================
class DamTypeIonBlastOmni extends DamTypeIonBlast
	abstract;

defaultproperties
{
	WeaponClass=Class'OmniPainters.IonPainterOmni'
	bDelayedDamage=True
}
