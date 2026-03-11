class NovaWebProjectile extends ONSRVWebProjectile;

// The two functions below fix webs not attributing credit to the player after they die

// Called the exact moment a player or vehicle runs into the web trap
simulated function ProcessTouch(Actor Other, Vector HitLocation)
{
    // Restore the Instigator before checking team allegiance
    if (Role == ROLE_Authority && Instigator == None && InstigatorController != None)
    {
        Instigator = InstigatorController.Pawn;
    }
    
    Super.ProcessTouch(Other, HitLocation);
}

// Called the exact moment the web blows up to apply area damage
simulated function HurtRadius(float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
    // Restore the Instigator right before the damage goes out
    if (Role == ROLE_Authority && Instigator == None && InstigatorController != None)
    {
        Instigator = InstigatorController.Pawn;
    }
    
    Super.HurtRadius(DamageAmount, DamageRadius, DamageType, Momentum, HitLocation);
}

defaultproperties
{
     BeamSubEmitterIndex=1
     ExplodeDelay=1.000000
     Speed=2000.000000
     MaxSpeed=10000.000000
     Damage=75.000000
     MomentumTransfer=15000.000000
}