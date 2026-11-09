//-----------------------------------------------------------
//
//-----------------------------------------------------------
class HospitalerRearGun extends ONSWeapon;

#exec OBJ LOAD FILE=..\Animations\ONSWeapons-A.ukx

var class<ONSChargeBeamEffect> BeamEffectClass;
var float StartHoldTime;
var float MaxHoldTime; //wait this long between shots for full damage
var float DamageScale, MinDamageScale;
var bool bHoldingFire;
var sound ChargingSound, ChargedLoop;

static function StaticPrecache(LevelInfo L)
{
    L.AddPrecacheMaterial(Material'EpicParticles.Flares.SoftFlare');
    L.AddPrecacheMaterial(Material'AW-2004Particles.Energy.BeamBolt1a');
    L.AddPrecacheMaterial(Material'XEffectMat.shock_flare_a');
    L.AddPrecacheMaterial(Material'XEffectMat.Shock_ring_b');
    L.AddPrecacheMaterial(Material'XEffectMat.Shock.shock_mark_heat');
    L.AddPrecacheMaterial(Material'XEffectMat.shock_core');
    L.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.PlasmaFlare');
    L.AddPrecacheMaterial(Material'EpicParticles.Beams.HotBolt04aw');
    L.AddPrecacheMaterial(Material'AW-2004Particles.Energy.BurnFlare');
}

simulated function UpdatePrecacheMaterials()
{
    Level.AddPrecacheMaterial(Material'EpicParticles.Flares.SoftFlare');
    Level.AddPrecacheMaterial(Material'AW-2004Particles.Energy.BeamBolt1a');
    Level.AddPrecacheMaterial(Material'XEffectMat.shock_flare_a');
    Level.AddPrecacheMaterial(Material'XEffectMat.Shock_ring_b');
    Level.AddPrecacheMaterial(Material'XEffectMat.Shock.shock_mark_heat');
    Level.AddPrecacheMaterial(Material'XEffectMat.shock_core');
    Level.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.PlasmaFlare');
    Level.AddPrecacheMaterial(Material'EpicParticles.Beams.HotBolt04aw');
    Level.AddPrecacheMaterial(Material'AW-2004Particles.Energy.BurnFlare');

    Super.UpdatePrecacheMaterials();
}

simulated function SetFireRateModifier(float Modifier)
{
	Super.SetFireRateModifier(Modifier);

	MaxHoldTime = default.MaxHoldTime / Modifier;
}

simulated function float ChargeBar()
{
	if (bHoldingFire)
		return (FMin(Level.TimeSeconds - StartHoldTime, MaxHoldTime) / MaxHoldTime);
	else
		return 0;
}

function SpawnBeamEffect(Vector Start, Rotator Dir, Vector HitLocation, Vector HitNormal, int ReflectNum)
{
	local ONSChargeBeamEffect Beam;

	if (ReflectNum == 0)
		Start = WeaponFireLocation;

	Beam = spawn(BeamEffectClass,,, Start, Dir);
	Beam.SetDrawScale(DamageScale);
	Beam.HitLocation = HitLocation;

	if (Level.NetMode != NM_DedicatedServer)
		Beam.SetupBeam();
}

// Stock ONSWeapon.TraceFire, traced from the vehicle the gun is bone-attached to (Base). Native line checks
// skip their source actor, so the beam passes through the Hospitaler's own hull (bDoOffsetTrace only cleared
// it within 1.5x CollisionRadius). Not reflective, and turret drivers have no collision, so the stock reflect
// loop and driver toggle are dropped: one trace per shot instead of two.
function TraceFire(Vector Start, Rotator Dir)
{
	local Vector X, End, HitLocation, HitNormal;
	local Actor Other, Tracer;

	MaxRange();
	X = Vector(Dir);
	End = Start + TraceRange * X;

	Tracer = Base;
	if (Tracer == None)
		Tracer = self;
	Other = Tracer.Trace(HitLocation, HitNormal, End, Start, true);

	if (Other == None)
	{
		HitLocation = End;
		HitNormal = vect(0,0,0);
		HitCount++;
		LastHitLocation = HitLocation;
	}
	else if (Other.bWorldGeometry)
	{
		HitCount++;
		LastHitLocation = HitLocation;
		SpawnHitEffects(Other, HitLocation, HitNormal);
	}
	else
	{
		if (Vehicle(Other) != None || Pawn(Other) == None)
		{
			HitCount++;
			LastHitLocation = HitLocation;
			SpawnHitEffects(Other, HitLocation, HitNormal);
		}
		Other.TakeDamage(DamageMin + Rand(DamageMax - DamageMin), Instigator, HitLocation, Momentum * X, DamageType);
		HitNormal = vect(0,0,0);
	}

	SpawnBeamEffect(Start, Dir, HitLocation, HitNormal, 0);
	NetUpdateTime = Level.TimeSeconds - 1;
}

// Stock ONSWeapon.CanAttack (instant hit), with the friendly-in-the-way trace run from the vehicle (Base)
// so bots don't treat their own hull as a teammate blocking the shot.
function bool CanAttack(Actor Other)
{
	local Vector HitLocation, HitNormal;
	local Actor HitActor, Tracer;

	if (Instigator == None || Instigator.Controller == None || VSize(Instigator.Location - Other.Location) > MaxRange()
		|| !Instigator.Controller.LineOfSightTo(Other))
		return false;

	CalcWeaponFire();
	Tracer = Base;
	if (Tracer == None)
		Tracer = self;
	HitActor = Tracer.Trace(HitLocation, HitNormal, Other.Location + Other.CollisionHeight * vect(0,0,0.8), WeaponFireLocation, true);

	return HitActor == None || HitActor == Other || Pawn(HitActor) == None || Pawn(HitActor).Controller == None
		|| !Instigator.Controller.SameTeamAs(Pawn(HitActor).Controller);
}

simulated function InitEffects()
{
	Super.InitEffects();

	if (FlashEmitter != None)
		FlashEmitter.Trigger(self, Instigator);
}

state InstantFireMode
{
	simulated function OwnerEffects()
	{
		if (Role < ROLE_Authority && !bHoldingFire)
		{
			bHoldingFire = true;
			StartHoldTime = Level.TimeSeconds;
			if (FlashEmitter != None)
				FlashEmitter.Reset();
		}
	}

	simulated function ClientStopFire(Controller C, bool bWasAltFire)
	{
		Super.ClientStopFire(C, bWasAltFire);

		if (FireCountdown <= 0)
		{
			ClientPlayForceFeedback(FireForce);
			ShakeView();
		}

		if (Role < ROLE_Authority)
		{
			bHoldingFire = false;
			if (FireCountdown <= 0)
			{
				if (bIsAltFire)
					FireCountdown = AltFireInterval;
				else
					FireCountdown = FireInterval;

		        FlashMuzzleFlash();

		        if (!bIsAltFire)
                    PlaySound(FireSoundClass, SLOT_None, FireSoundVolume/255.0,, FireSoundRadius,, false);
		    }
		}

	}

	function Fire(Controller C)
	{
		if (!bHoldingFire)
		{
			StartHoldTime = Level.TimeSeconds;
			bHoldingFire = true;
			if (FlashEmitter != None)
				FlashEmitter.Reset();
			bClientTrigger = !bClientTrigger;
			AmbientSound = ChargingSound;
			SetTimer(MaxHoldTime, False);
		}
	}

    function Timer()
    {
        if (bHoldingFire)
            AmbientSound = ChargedLoop;
    }

	function CeaseFire(Controller C)
	{
		if (!bHoldingFire)
			return;

		ClientPlayForceFeedback(FireForce);

		AmbientSound = None;

		CalcWeaponFire();

		if (bCorrectAim)
			WeaponFireRotation = AdjustAim(false);

		DamageScale = FClamp((Level.TimeSeconds - StartHoldTime) / MaxHoldTime, MinDamageScale, 1.0);
		DamageMin = default.DamageMin * DamageScale;
		DamageMax = default.DamageMax * DamageScale;
		Momentum = default.Momentum * DamageScale;
		FireSoundPitch = 2.0 - DamageScale;

		Super.Fire(C);
		FireCountdown = FireInterval;
		bHoldingFire = false;
	}

	simulated function ClientTrigger()
	{
		if (Instigator != None && !Instigator.IsLocallyControlled() && FlashEmitter != None)
			FlashEmitter.Reset();
	}
}

defaultproperties
{
     BeamEffectClass=Class'Onslaught.ONSChargeBeamEffect'
     MaxHoldTime=2.250000
     MinDamageScale=0.150000
     ChargingSound=Sound'ONSVehicleSounds-S.PRV.PRVChargeUp'
     ChargedLoop=Sound'ONSVehicleSounds-S.PRV.PRVChargeLoop'
     YawBone="REARgunBASE"
     PitchBone="REARgunTURRET"
     PitchUpLimit=15000
     PitchDownLimit=57500
     WeaponFireAttachmentBone="Dummy02"
     GunnerAttachmentBone="REARgunBASE"
     bInstantRotation=True
     bInstantFire=True
     bShowChargingBar=True
     RedSkin=Texture'IllyTemplar_and_HospitalerSkins.both.Hospi_Templar_Turrets'
     BlueSkin=Texture'IllyTemplar_and_HospitalerSkins.both.Hospi_Templar_Turrets'
     FireInterval=0.750000
     FlashEmitterClass=Class'Onslaught.ONSPRVRearGunCharge'
     FireSoundClass=Sound'ONSVehicleSounds-S.PRV.PRVFire04'
     FireForce="PRVRearFire"
     DamageType=Class'Onslaught.DamTypeChargingBeam'
     DamageMin=230
     DamageMax=230
     TraceRange=20000.000000
     Momentum=250000.000000
     AIInfo(0)=(bInstantHit=True,bFireOnRelease=True,RefireRate=0.850000)
     Mesh=SkeletalMesh'ONSWeapons-A.PRVrearGUN'
     DrawScale=0.800000
     
}
