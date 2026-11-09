// ============================================================================
// Link Tank laser turret.
// ============================================================================
class VampireTank3TertiaryTurret extends ONSWeapon;

var() sound LinkedFireSound;

var class<ONSTurretBeamEffect> BeamEffectClass[2];
var float LinkMultiplier;
var VampireTank3 BaseTank; // set on first use via Instigator (the weapon pawn): Instigator replicates to every client, Owner only to the gunner

static function StaticPrecache(LevelInfo L)
{
    L.AddPrecacheMaterial(Material'TurretParticles.Beams.TurretBeam5');
    L.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.PlasmaMuzzleBlue');
    L.AddPrecacheMaterial(Material'EpicParticles.Flares.SoftFlare');
    L.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.PlasmaStar2');
    L.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.SmokePanels1');
    L.AddPrecacheMaterial(Material'XEffectMat.shock_flare_a');
    L.AddPrecacheMaterial(Material'XEffectMat.Shock_ring_b');
    L.AddPrecacheMaterial(Material'XEffectMat.Shock.shock_mark_heat');
    L.AddPrecacheMaterial(Material'XEffectMat.shock_core');
}

simulated function UpdatePrecacheMaterials()
{
    Level.AddPrecacheMaterial(Material'TurretParticles.Beams.TurretBeam5');
    Level.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.PlasmaMuzzleBlue');
    Level.AddPrecacheMaterial(Material'EpicParticles.Flares.SoftFlare');
    Level.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.PlasmaStar2');
    Level.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.SmokePanels1');
    Level.AddPrecacheMaterial(Material'XEffectMat.shock_flare_a');
    Level.AddPrecacheMaterial(Material'XEffectMat.Shock_ring_b');
    Level.AddPrecacheMaterial(Material'XEffectMat.Shock.shock_mark_heat');
    Level.AddPrecacheMaterial(Material'XEffectMat.shock_core');

    Super.UpdatePrecacheMaterials();
}

//do effects (muzzle flash, force feedback, etc) immediately for the weapon's owner (don't wait for replication)
simulated event OwnerEffects()
{
	if (!bIsRepeatingFF)
	{
		if (bIsAltFire)
			ClientPlayForceFeedback( AltFireForce );
		else
			ClientPlayForceFeedback( FireForce );
	}
    ShakeView();

	if (Role < ROLE_Authority)
	{
		if (BaseTank == None && ONSWeaponPawn(Instigator) != None)
			BaseTank = VampireTank3(ONSWeaponPawn(Instigator).VehicleBase);

		// Swap out fire sound
		if (BaseTank != None && BaseTank.Links > 0)
			FireSoundClass = LinkedFireSound;
		else
			FireSoundClass = default.FireSoundClass;


		if (bIsAltFire)
			FireCountdown = AltFireInterval;
		else
			FireCountdown = FireInterval;

		AimLockReleaseTime = Level.TimeSeconds + FireCountdown * FireIntervalAimLock;

		if (AmbientEffectEmitter != None)
			AmbientEffectEmitter.SetEmitterStatus(true);

        // Play firing noise
        if (!bAmbientFireSound)
        {
            if (bIsAltFire)
                PlaySound(AltFireSoundClass, SLOT_None, FireSoundVolume/255.0,, AltFireSoundRadius,, false);
            else
                PlaySound(FireSoundClass, SLOT_None, FireSoundVolume/255.0,, FireSoundRadius,, false);
        }
	}
}

function TraceFire(Vector Start, Rotator Dir)
{
    local Vector X, End, HitLocation, HitNormal;
    local Actor Other;
    local int Damage;
    local int NumLinks;

	// BaseTank is set in Fire, which always runs first
	if (BaseTank != None)
		NumLinks = BaseTank.Links;

    X = Vector(Dir);
    End = Start + TraceRange * X;

    //skip past vehicle driver
    if (ONSVehicle(Instigator) != None && ONSVehicle(Instigator).Driver != None)
    {
      	ONSVehicle(Instigator).Driver.bBlockZeroExtentTraces = False;
       	Other = Trace(HitLocation, HitNormal, End, Start, True);
       	ONSVehicle(Instigator).Driver.bBlockZeroExtentTraces = true;
    }
    else
       	Other = Trace(HitLocation, HitNormal, End, Start, True);

    if (Other != None)
    {
	if (!Other.bWorldGeometry)
        {
            Damage = (DamageMin + Rand(DamageMax - DamageMin));
            Other.TakeDamage(AdjustLinkDamage(NumLinks,Damage), Instigator, HitLocation, Momentum*X, DamageType);
            HitNormal = vect(0,0,0);
        }
    }
    else
    {
        HitLocation = End;
        HitNormal = Vect(0,0,0);
    }

    HitCount++;
    LastHitLocation = HitLocation;
    // Replicate HitCount/LastHitLocation this frame instead of on the next scheduled update (10 per second while manned).
    // Clients spawn the beam when HitCount changes, so a late update delays the beam and a quick tap can lose it entirely.
    NetUpdateTime = Level.TimeSeconds - 1;
    SpawnHitEffects(Other, HitLocation, HitNormal);
}

// ============================================================================
// AdjustLinkDamage
// Return adjusted damage based on number of links
// Takes a NumLinks argument instead of an actual LinkGun
// ============================================================================
simulated function float AdjustLinkDamage( int NumLinks, float Damage )
{
	Damage = Damage * ((LinkMultiplier*NumLinks)+1);
	return Damage;
}


state InstantFireMode
{
    function Fire(Controller C)
    {
		if (BaseTank == None && ONSWeaponPawn(Instigator) != None)
			BaseTank = VampireTank3(ONSWeaponPawn(Instigator).VehicleBase);

		// Swap out fire sound
		if (BaseTank != None && BaseTank.Links > 0)
			FireSoundClass = LinkedFireSound;
		else
			FireSoundClass = default.FireSoundClass;

        if (AmbientEffectEmitter != None)
        {
            AmbientEffectEmitter.SetEmitterStatus(true);
        }

        // Play firing noise
        if (bAmbientFireSound)
            AmbientSound = FireSoundClass;
        else
            PlayOwnedSound(FireSoundClass, SLOT_None, FireSoundVolume/255.0,, FireSoundRadius, FireSoundPitch, False);

        TraceFire(WeaponFireLocation, WeaponFireRotation);
    }

	simulated function SpawnHitEffects(actor HitActor, vector HitLocation, vector HitNormal)
	{
		local ONSTurretBeamEffect Beam;
		local int BeamColor;
		local vector BeamDir;
		local Range BeamRange;

		if (Level.NetMode != NM_DedicatedServer)
		{
			if (BaseTank == None && ONSWeaponPawn(Instigator) != None)
				BaseTank = VampireTank3(ONSWeaponPawn(Instigator).VehicleBase);

			// Gold beam while linked
			if (BaseTank != None && BaseTank.Links > 0)
				BeamColor = 1;

			if (Role < ROLE_Authority)
			{
				CalcWeaponFire();
				DualFireOffset *= -1;
			}

            if (!Level.bDropDetail && Level.DetailMode != DM_Low)
            {
    			if (DualFireOffset < 0)
    				PlayAnim('RightFire');
    			else
    				PlayAnim('LeftFire');
    		}

			BeamDir = HitLocation - WeaponFireLocation;
			BeamRange.Min = VSize(BeamDir);
			BeamRange.Max = BeamRange.Min;
			Beam = Spawn(BeamEffectClass[BeamColor],,, WeaponFireLocation, rotator(BeamDir));
			BeamEmitter(Beam.Emitters[0]).BeamDistanceRange = BeamRange;
			BeamEmitter(Beam.Emitters[1]).BeamDistanceRange = BeamRange;
			Beam.SpawnEffects(HitLocation, HitNormal);
		}
	}
}

function byte BestMode()
{
	return 0;
}

// ============================================================================

defaultproperties
{
     LinkedFireSound=Sound'WeaponSounds.LinkGun.BLinkedFire'
     BeamEffectClass(0)=Class'LinkVehiclesOmni.Link3TurretBeamEffectGreen'
     BeamEffectClass(1)=Class'LinkVehiclesOmni.Link3TurretBeamEffectGold'
     YawBone="Object01"
     PitchBone="Object02"
     PitchUpLimit=12500
     PitchDownLimit=59500
     WeaponFireAttachmentBone="Object02"
     WeaponFireOffset=85.000000
     DualFireOffset=5.000000
     RotationsPerSecond=2.000000
     bInstantRotation=True
     bInstantFire=True
     RedSkin=Texture'LinkTank3Tex.LinkTankTex.LinkTankLaserRed'
     BlueSkin=Texture'LinkTank3Tex.LinkTankTex.LinkTankLaserBlue'
     FireInterval=0.150000
     FireSoundClass=Sound'WeaponSounds.Misc.instagib_rifleshot'
     AmbientSoundScaling=1.300000
     FireForce="Laser01"
     DamageType=Class'LinkVehiclesOmni.DamTypeLink3TurretBeam'
     DamageMin=25
     DamageMax=35
     AIInfo(0)=(bInstantHit=True,aimerror=750.000000)
     Mesh=SkeletalMesh'ONSWeapons-A.TankMachineGun'
     LinkMultiplier = 1.1
}
