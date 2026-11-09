// ============================================================================
// Link Tank projectile.
// ============================================================================
class HospitalerLinkPlasma extends PROJ_LinkTurret_Plasma;

var Actor Hull; // the firing vehicle, kept in our Owner chain so we fly through it

replication
{
    reliable if (bNetInitial && Role == ROLE_Authority)
        Hull;
}

// ============================================================================

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	// Server: Owner is the firing link turret (clients have none yet). Native line checks, projectile movement
	// included, skip every actor in the mover's Owner chain, so owning the bolt by the gun's vehicle lets it
	// pass through its own hull at no per-tick cost.
	if (Owner != None && Owner.Base != None)
	{
		Hull = Owner.Base;
		SetOwner(Hull);
	}
}

simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	// Clients: Owner only replicates to the owning connection, so join the hull to our Owner chain locally
	if (Hull != None && Owner != Hull)
		SetOwner(Hull);
}

// ============================================================================

defaultproperties
{
     Speed=5000.000000
     MaxSpeed=5000.000000
     Damage=55.000000
     DamageRadius=300.000000
     MomentumTransfer=5000.000000
     MyDamageType=Class'HospitalerV3Omni.DamTypeHospitalerLinkPlasma'
}
