//=============================================================================
// StealthBadgerTurretPawn.
//=============================================================================
class StealthBadgerTurretPawn extends BadgerTurretPawn;

// KDriverEnter
// Gunner seat taken: start the StealthBadger's stealth checks, so it also
// cloaks with only a gunner inside.
function KDriverEnter(Pawn P)
{
	local StealthBadger SB;

	Super.KDriverEnter(P);

	SB = StealthBadger(VehicleBase);
	if (SB != None)
		SB.OccupantEntered();
}

defaultproperties
{
     GunClass=Class'CSBadgerFix.StealthBadgerTurret'
     VehiclePositionString="in a Stealth Badger Turret"
     VehicleNameString="Stealth Badger Turret"
}
