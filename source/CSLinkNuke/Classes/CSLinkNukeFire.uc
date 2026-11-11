class CSLinkNukeFire extends ProjectileFire;

//#exec AUDIO IMPORT FILE=Sounds\ohyeahhats.wav

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Projectile P;

    if (ProjectileClass != None)
        P = Weapon.Spawn(ProjectileClass, Owner,, Start, Dir);

    if (P == None && Instigator != None)
        P = Weapon.Spawn(ProjectileClass, Owner,, Instigator.Location, Dir);

    if (P == None)
    {
        Weapon.Spawn(class'SmallRedeemerExplosion');

        // Replace the stock Redeemer-sized fallback with this:
        if (Instigator != None)
        {
            Weapon.HurtRadius
            (
                ProjectileClass.default.Damage,
                ProjectileClass.default.DamageRadius,
                ProjectileClass.default.MyDamageType,
                ProjectileClass.default.MomentumTransfer,
                Instigator.Location
            );
        }

		CSLinkNuke(Weapon).HealFallbackRadius
		(
			ProjectileClass.default.DamageRadius,
			Instigator.Location
		);

        return None;
    }

    P.Damage *= DamageAtten;
    return P;
}

defaultproperties
{
     ProjSpawnOffset=(X=100.000000,Z=0.000000)
     bSplashDamage=True
     bRecommendSplashDamage=True
     TransientSoundVolume=1.000000
     FireSound=Sound'WeaponSounds.Misc.redeemer_shoot'
     FireForce="redeemer_shoot"
     FireRate=1.000000
     AmmoClass=Class'CSLinkNuke.CSLinkNukeAmmo'
     AmmoPerFire=1
     ShakeRotTime=2.000000
     ShakeOffsetMag=(X=-20.000000)
     ShakeOffsetRate=(X=-1000.000000)
     ShakeOffsetTime=2.000000
     ProjectileClass=Class'CSLinkNuke.CSLinkNukeProjectile'
     BotRefireRate=0.500000
}
