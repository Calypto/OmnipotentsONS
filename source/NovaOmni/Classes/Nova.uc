// Pulled from GunShop; instigator and scoring fixes by Anonymous
class Nova extends ONSWheeledCraft
	placeable;

#exec OBJ LOAD FILE=..\Animations\CuddlyWheels_Mesh.ukx
#exec OBJ LOAD FILE=..\textures\VehicleFX.utx
#exec OBJ LOAD FILE=..\textures\EpicParticles.utx
#exec OBJ LOAD FILE=..\sounds\GorzWheels_Sounds.uax
#exec OBJ LOAD FILE=..\textures\Astrascorps_TEX.utx

var bool bLeftArmBroke;
var bool bRightArmBroke;
var bool bClientLeftArmBroke;
var bool bClientRightArmBroke;

var float Damage, DamageRadius, MomentumTransfer;
var class<DamageType> MyDamageType;
var NovaWarhead Warhead;
var bool bDetonating;

replication
{
	reliable if (Role < ROLE_Authority)
		ServerBlowUp;
}

simulated function PostNetBeginPlay()
{
	if (Role == ROLE_Authority)
	{
				bLeftArmBroke = True;
				bClientLeftArmBroke = True;
				bRightArmBroke = True;
				bClientRightArmBroke = True;
	}
	if (Role < ROLE_Authority)
	{
			bLeftArmBroke = True;
			bClientLeftArmBroke = False;
			bRightArmBroke = True;
			bClientRightArmBroke = False;
	}

	SetBoneScale(4, 0.0, 'CarLShoulder');
	SetBoneScale(5, 0.0, 'CarRShoulder');

	Super.PostNetBeginPlay();
}

function AltFire(optional float F)
{
	//avoid sending altfire to weapon and make me go boom instead
	Super(Vehicle).AltFire(F);
	ServerBlowUp();
	ClientBeginDetonating();
}

function ClientVehicleCeaseFire(bool bWasAltFire)
{
	if (bWasAltFire)
		Super(Vehicle).ClientVehicleCeaseFire(bWasAltFire);
	else
		Super.ClientVehicleCeaseFire(bWasAltFire);
}

function VehicleFire(bool bWasAltFire)
{
	if (bWasAltFire)
		Super(Vehicle).VehicleFire(bWasAltFire);
	else
		Super.VehicleFire(bWasAltFire);
}

function VehicleCeaseFire(bool bWasAltFire)
{
	if (bWasAltFire)
		Super(Vehicle).VehicleCeaseFire(bWasAltFire);
	else
		Super.VehicleCeaseFire(bWasAltFire);
}

simulated function Tick(float DT)
{
	if (Vsize(Velocity) < 650)
	{
		wheels[0].SteerType = VST_Inverted;   
		wheels[1].SteerType = VST_Inverted;
	}

	Else if (Vsize(Velocity) >=650)
	{
		wheels[0].SteerType = VST_Fixed;	
		wheels[1].SteerType = VST_Fixed;
	}
	Super.tick(DT);
}

function ClientBeginDetonating()
{
	local int i;
	
	if (Role == ROLE_Authority)
		return;
	
	bHidden = true;
	Driver.bHidden = true;
	KParams.KImpactThreshold = 0;
	SetPhysics(PHYS_None);
	
	bNoTeamBeacon = true;
	
	for(i=0;i<HeadlightCorona.Length;i++)
		HeadlightCorona[i].Skins[0] = None;
	
	if(HeadlightProjector != None)
		HeadlightProjector.ProjTexture = None;
	
	for(i=0; i<2; i++)
		if (BrakeLight[i] != None)
			BrakeLight[i].Skins[0] = None;
	
	for(i=0;i<Dust.Length;i++)
	{
		Dust[i].Emitters[0].Texture = None;
		Dust[i].Emitters[1].Texture = None;
		Dust[i].AmbientSound = None;
	}
}

function ServerBlowUp()
{
	BlowUp(Location);
}

function BlowUp(vector HitLocation)
{
	if (Role == ROLE_Authority)
		GoToState('Dying');
}

function FinishedDetonating(); // stub

state Dying
{
ignores Trigger, Bump, Touch, HitWall, Landed, HeadVolumeChange, PhysicsVolumeChange, Falling, BreathTimer, KImpact, TakeImpactDamage, Fire, AltFire, VehicleFire, VehicleCeaseFire, ClientVehicleCeaseFire;

	simulated function DrivingStatusChanged() {}
	function BlowUp(vector HitLocation) {}
	function ServerBlowUp() {}
	function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
							Vector momentum, class<DamageType> MydamageType) {}

	function BeginState()
	{
		local int i;
		
		// spawn the deemer and give it our settings
		Warhead = Spawn(class'NovaWarhead');
		Warhead.SetUp(Self);
		bDetonating = True;
		
		bHidden = true;
		Driver.bHidden = true;
		KParams.KImpactThreshold = 0;
		SetCollision(false,false,false);
		KarmaParams(KParams).KMaxSpeed = 0;
		
		bNoTeamBeacon = true;
		
		for(i=0;i<HeadlightCorona.Length;i++)
			HeadlightCorona[i].Destroy();
		HeadlightCorona.Length = 0;
		
		if(HeadlightProjector != None)
			HeadlightProjector.Destroy();
		
		for(i=0; i<2; i++)
			if (BrakeLight[i] != None)
				BrakeLight[i].Destroy();
		
		for(i=0;i<Dust.Length;i++)
			Dust[i].Destroy();
		Dust.Length = 0;
		
		SetTimer(1,false);
	}

/*
	function Timer()
	{
		bDetonating = False;
		if (Driver != None)
			Driver.Died(None, MyDamageType, Location);
		Died(None, MyDamageType, Location);
	}
*/

	function Timer()
	{
		local Controller C;
		local PlayerReplicationInfo ValidPRI;

		// Loop and wait if the warhead actor is still active
		if (Warhead != None && !Warhead.bDeleteMe)
		{
			SetTimer(0.5, false);
			return;
		}

		bDetonating = False;
		
		// Secure the Controller
		C = Controller;
		if (C == None && Instigator != None)
			C = Instigator.Controller;

		// Secure the PRI before death forces the player into a spectator state
		if (C != None)
			ValidPRI = C.PlayerReplicationInfo;

		// Trigger the driver's death
		if (Driver != None)
			Driver.Died(None, MyDamageType, Location);
			
		// Trigger the vehicle's death
		Died(None, MyDamageType, Location);

		// Zero out the suicide score penalty
		if (ValidPRI != None)
		{
			ValidPRI.Deaths -= 1;
			ValidPRI.Score += 1;

			if (xPlayerReplicationInfo(ValidPRI) != None)
				xPlayerReplicationInfo(ValidPRI).Suicides -= 1;

			ValidPRI.NetUpdateTime = Level.TimeSeconds - 1;
		}
	}

	function FinishedDetonating()
	{
		Warhead = None;
		Timer();
	}
}

function bool KDriverLeave(bool bForceLeave)
{
	if (bDetonating)
		return false;
	else
		Super.KDriverLeave(bForceLeave);
}

function Died(Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	if (!bDetonating)
		Super.Died(Killer,DamageType,HitLocation);
}

function TakeDamage(int Damage, Pawn instigatedBy, Vector Hitlocation, Vector Momentum, class<DamageType> DamageType)
{

	if (DamageType == class'DamTypeShockBeam')
		Momentum *= 0.00;
	
	if (DamageType == class'DamTypeONSWeb' && instigatedBy != None && instigatedBy == self)
		Damage *= 0.30;

	if (DamageType == class'NovaBlast' && instigatedBy != None && instigatedBy == self)
		Damage *= 0.00;

	Super.TakeDamage(Damage, instigatedBy, Hitlocation, Momentum, DamageType);
}

static function StaticPrecache(LevelInfo L)
{
	Super.StaticPrecache(L);

	L.AddPrecacheStaticMesh(StaticMesh'ONSDeadVehicles-SM.RVexploded.RVgun');
	L.AddPrecacheStaticMesh(StaticMesh'ONSDeadVehicles-SM.RVexploded.RVrail');
	L.AddPrecacheStaticMesh(StaticMesh'ONSDeadVehicles-SM.RVexploded.Rvtire');
	L.AddPrecacheStaticMesh(StaticMesh'AW-2004Particles.Debris.Veh_Debris2');
	L.AddPrecacheStaticMesh(StaticMesh'AW-2004Particles.Debris.Veh_Debris1');

	L.AddPrecacheMaterial(Material'ExplosionTex.Framed.exp2_frames');
	L.AddPrecacheMaterial(Material'ExplosionTex.Framed.exp1_frames');
	L.AddPrecacheMaterial(Material'ExplosionTex.Framed.we1_frames');
	L.AddPrecacheMaterial(Material'ExplosionTex.Framed.SmokeReOrdered');
	L.AddPrecacheMaterial(Material'AW-2004Particles.Fire.NapalmSpot');
	L.AddPrecacheMaterial(Material'EpicParticles.Fire.SprayFire1');
	L.AddPrecacheMaterial(Material'VMVehicles-TX.RVGroup.RVblades');
	L.AddPrecacheMaterial(Material'VMVehicles-TX.Environments.ReflectionTexture');
	L.AddPrecacheMaterial(Material'VMWeaponsTX.RVgunGroup.RVnewGUNtex');
	L.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.MuzzleSpray');
	L.AddPrecacheMaterial(Material'VehicleFX.Particles.DustyCloud2');
	L.AddPrecacheMaterial(Material'VMParticleTextures.DirtKICKGROUP.dirtKICKTEX');
	L.AddPrecacheMaterial(Material'Engine.GRADIENT_Fade');
	L.AddPrecacheMaterial(Material'XEffectMat.Link.link_spark_green');
}

simulated function UpdatePrecacheStaticMeshes()
{
	Level.AddPrecacheStaticMesh(StaticMesh'ONSDeadVehicles-SM.RVexploded.RVgun');
	Level.AddPrecacheStaticMesh(StaticMesh'ONSDeadVehicles-SM.RVexploded.RVrail');
	Level.AddPrecacheStaticMesh(StaticMesh'ONSDeadVehicles-SM.RVexploded.Rvtire');
	Level.AddPrecacheStaticMesh(StaticMesh'AW-2004Particles.Debris.Veh_Debris2');
	Level.AddPrecacheStaticMesh(StaticMesh'AW-2004Particles.Debris.Veh_Debris1');

	Super.UpdatePrecacheStaticMeshes();
}

simulated function UpdatePrecacheMaterials()
{
	Level.AddPrecacheMaterial(Material'ExplosionTex.Framed.exp2_frames');
	Level.AddPrecacheMaterial(Material'ExplosionTex.Framed.exp1_frames');
	Level.AddPrecacheMaterial(Material'ExplosionTex.Framed.we1_frames');
	Level.AddPrecacheMaterial(Material'ExplosionTex.Framed.SmokeReOrdered');
	Level.AddPrecacheMaterial(Material'AW-2004Particles.Fire.NapalmSpot');
	Level.AddPrecacheMaterial(Material'EpicParticles.Fire.SprayFire1');
	Level.AddPrecacheMaterial(Material'VMVehicles-TX.Environments.ReflectionTexture');
	Level.AddPrecacheMaterial(Material'VMWeaponsTX.RVgunGroup.RVnewGUNtex');
	Level.AddPrecacheMaterial(Material'AW-2004Particles.Weapons.MuzzleSpray');
	Level.AddPrecacheMaterial(Material'VehicleFX.Particles.DustyCloud2');
	Level.AddPrecacheMaterial(Material'VMParticleTextures.DirtKICKGROUP.dirtKICKTEX');
	Level.AddPrecacheMaterial(Material'Engine.GRADIENT_Fade');
	Level.AddPrecacheMaterial(Material'XEffectMat.Link.link_spark_green');
	Level.AddPrecacheMaterial(Material'Astrascorps_TEX.Nova.NovaFlare');
	Level.AddPrecacheMaterial(Material'Astrascorps_TEX.Nova.NovaProjector');
	Level.AddPrecacheMaterial(Material'Astrascorps_TEX.Nova.NovaBlue');
	Level.AddPrecacheMaterial(Material'Astrascorps_TEX.Nova.NovaRed');

	Super.UpdatePrecacheMaterials();
}

defaultproperties
{
	 CrossHairColor=(B=200,G=200,R=200,A=200)
	 CrosshairTexture=Texture'Crosshairs.HUD.Crosshair_Pointer'
	 
	 Damage=330.000000
	 DamageRadius=2000.000000
	 MyDamageType=Class'NovaBlast'
	 WheelSoftness=0.025000
	 WheelPenScale=1.200000
	 WheelPenOffset=0.010000
	 WheelRestitution=0.100000
	 WheelAdhesion=2.000000
	 WheelInertia=0.100000
	 WheelLongFrictionFunc=(Points=(,(InVal=100.000000,OutVal=1.000000),(InVal=200.000000,OutVal=0.900000),(InVal=10000000000.000000,OutVal=0.900000)))
	 WheelLongSlip=0.001000
	 WheelLatSlipFunc=(Points=(,(InVal=30.000000,OutVal=0.007000),(InVal=45.000000),(InVal=10000000000.000000)))
	 WheelLongFrictionScale=1.250000
	 WheelLatFrictionScale=1.350000
	 WheelHandbrakeSlip=0.010000
	 WheelHandbrakeFriction=0.100000
	 WheelSuspensionTravel=15.000000
	 WheelSuspensionMaxRenderTravel=15.000000
	 FTScale=0.030000
	 ChassisTorqueScale=0.100000
	 MinBrakeFriction=4.900000
	 MaxSteerAngleCurve=(Points=((OutVal=25.000000),(InVal=1500.000000,OutVal=11.000000),(InVal=1000000000.000000,OutVal=11.000000)))
	 TorqueCurve=(Points=((OutVal=14.000000),(InVal=200.000000,OutVal=20.000000),(InVal=1500.000000,OutVal=28.000000),(InVal=2800.000000)))
	 GearRatios(0)=-1.500000
	 GearRatios(1)=0.700000
	 GearRatios(2)=1.500000
	 GearRatios(3)=1.850000
	 GearRatios(4)=2.450000
	 TransRatio=0.150000
	 ChangeUpPoint=2000.000000
	 ChangeDownPoint=1300.000000
	 LSDFactor=1.000000
	 EngineBrakeFactor=0.000100
	 EngineBrakeRPMScale=0.100000
	 MaxBrakeTorque=50.000000
	 SteerSpeed=240.000000
	 TurnDamping=35.000000
	 StopThreshold=100.000000
	 HandbrakeThresh=200.000000
	 EngineInertia=0.100000
	 IdleRPM=500.000000
	 EngineRPMSoundRange=12000.000000
	 SteerBoneName="SteeringWheel"
	 SteerBoneAxis=AXIS_Z
	 SteerBoneMaxAngle=90.000000
	 RevMeterScale=4000.000000
	 bMakeBrakeLights=True
	 BrakeLightOffset(0)=(X=-100.000000,Y=23.000000,Z=7.000000)
	 BrakeLightOffset(1)=(X=-100.000000,Y=-23.000000,Z=7.000000)
	 BrakeLightMaterial=Texture'EpicParticles.Flares.FlashFlare1'
	 DaredevilThreshInAirSpin=180.000000
	 DaredevilThreshInAirTime=2.400000
	 DaredevilThreshInAirDistance=33.000000
	 bDoStuntInfo=True
	 bAllowAirControl=True
	 bAllowBigWheels=True
	 AirTurnTorque=35.000000
	 AirPitchTorque=55.000000
	 AirPitchDamping=55.000000
	 AirRollTorque=35.000000
	 AirRollDamping=35.000000
	 DriverWeapons(0)=(WeaponClass=Class'NovaOmni.NovaWebLauncher',WeaponBone="ChainGunAttachment")
	 bHasAltFire=False
	 RedSkin=Texture'Astrascorps_Tex.Nova.NovaRed'
	 BlueSkin=Texture'Astrascorps_Tex.Nova.NovaBlue'
	 IdleSound=Sound'GorzWheels_Sounds.Tarantula.TarantulaEngine'
	 StartUpSound=Sound'ONSVehicleSounds-S.RV.RVStart01'
	 ShutDownSound=Sound'ONSVehicleSounds-S.RV.RVStop01'
	 StartUpForce="RVStartUp"
	 DestroyedVehicleMesh=StaticMesh'ONSDeadVehicles-SM.RVDead'
	 DestructionEffectClass=Class'Onslaught.ONSSmallVehicleExplosionEffect'
	 DisintegrationEffectClass=Class'Onslaught.ONSVehDeathRV'
	 DisintegrationHealth=-25.000000
	 DestructionLinearMomentum=(Min=200000.000000,Max=300000.000000)
	 DestructionAngularMomentum=(Min=100.000000,Max=150.000000)
	 DamagedEffectOffset=(X=60.000000,Y=10.000000,Z=10.000000)
	 bEjectPassengersWhenFlipped=False
	 ImpactDamageMult=0.000100
	 HeadlightCoronaOffset(0)=(X=86.000000,Y=30.000000,Z=7.000000)
	 HeadlightCoronaOffset(1)=(X=86.000000,Y=-30.000000,Z=7.000000)
	 HeadlightCoronaMaterial=Texture'Astrascorps_Tex.Nova.NovaFlare'
	 HeadlightCoronaMaxSize=65.000000
	 HeadlightProjectorMaterial=Texture'Astrascorps_Tex.Nova.NovaProjector'
	 HeadlightProjectorOffset=(X=90.000000,Z=7.000000)
	 HeadlightProjectorRotation=(Pitch=-1000)
	 HeadlightProjectorScale=0.300000

	 Begin Object Class=SVehicleWheel Name=NovaRR
		 bPoweredWheel=True
		 bHandbrakeWheel=True
		 BoneName="tire02"
		 BoneRollAxis=AXIS_Y
		 BoneOffset=(Y=7.000000)
		 WheelRadius=24.000000
		 SupportBoneName="RrearStrut"
		 SupportBoneAxis=AXIS_X
	 End Object
	 Wheels(0)=SVehicleWheel'NovaOmni.Nova.NovaRR'

	 Begin Object Class=SVehicleWheel Name=NovaLR
		 bPoweredWheel=True
		 bHandbrakeWheel=True
		 BoneName="tire04"
		 BoneRollAxis=AXIS_Y
		 BoneOffset=(Y=-7.000000)
		 WheelRadius=24.000000
		 SupportBoneName="LrearStrut"
		 SupportBoneAxis=AXIS_X
	 End Object
	 Wheels(1)=SVehicleWheel'NovaOmni.Nova.NovaLR'

	 Begin Object Class=SVehicleWheel Name=NovaRF
		 bPoweredWheel=True
		 SteerType=VST_Steered
		 BoneName="tire"
		 BoneRollAxis=AXIS_Y
		 BoneOffset=(Y=7.000000)
		 WheelRadius=24.000000
		 SupportBoneName="RFrontStrut"
		 SupportBoneAxis=AXIS_X
	 End Object
	 Wheels(2)=SVehicleWheel'NovaOmni.Nova.NovaRF'

	 Begin Object Class=SVehicleWheel Name=NovaLF
		 bPoweredWheel=True
		 SteerType=VST_Steered
		 BoneName="tire03"
		 BoneRollAxis=AXIS_Y
		 BoneOffset=(Y=-7.000000)
		 WheelRadius=24.000000
		 SupportBoneName="LfrontStrut"
		 SupportBoneAxis=AXIS_X
	 End Object
	 Wheels(3)=SVehicleWheel'NovaOmni.Nova.NovaLF'

	 VehicleMass=3.000000
	 bDrawDriverInTP=True
	 bDrawMeshInFP=True
	 bHasHandbrake=True
	 bSeparateTurretFocus=True
	 DrivePos=(X=2.000000,Z=38.000000)
	 ExitPositions(0)=(Y=-165.000000,Z=100.000000)
	 ExitPositions(1)=(Y=165.000000,Z=100.000000)
	 ExitPositions(2)=(Y=-165.000000,Z=-100.000000)
	 ExitPositions(3)=(Y=165.000000,Z=-100.000000)
	 EntryRadius=160.000000
	 FPCamPos=(X=15.000000,Z=25.000000)
	 TPCamDistance=200
	 TPCamLookat=(X=0.000000,Z=0.000000)
	 TPCamWorldOffset=(Z=100.000000)
	 DriverDamageMult=0.400000
	 VehiclePositionString="in a Nova )o("
	 VehicleNameString="Nova )o("
	 RanOverDamageType=Class'NovaOmni.NovaRoadkill'
	 CrushedDamageType=Class'Onslaught.DamTypeRVPancake'
	 MaxDesireability=0.400000
	 ObjectiveGetOutDist=1500.000000
	 HornSounds(0)=Sound'GorzWheels_Sounds.Stinger.StingerHorn'
	 HornSounds(1)=Sound'ONSVehicleSounds-S.Horns.Dixie_Horn'
	 GroundSpeed=1330.000000
	 HealthMax=300.000000
	 Health=300
	 bReplicateAnimations=True
	 Mesh=SkeletalMesh'CuddlyWheels_Mesh.Nova.Nova'
	 SoundVolume=180
	 CollisionRadius=100.000000
	 CollisionHeight=40.000000

	 Begin Object Class=KarmaParamsRBFull Name=KParams0
		 KInertiaTensor(0)=1.000000
		 KInertiaTensor(3)=3.000000
		 KInertiaTensor(5)=3.000000
		 KCOMOffset=(X=-0.250000,Z=-0.400000)
		 KLinearDamping=0.050000
		 KAngularDamping=0.050000
		 KStartEnabled=True
		 bKNonSphericalInertia=True
		 bHighDetailOnly=False
		 bClientOnly=False
		 bKDoubleTickRate=True
		 bDestroyOnWorldPenetrate=True
		 bDoSafetime=True
		 KFriction=0.500000
		 KImpactThreshold=700.000000
	 End Object
	 KParams=KarmaParamsRBFull'NovaOmni.Nova.KParams0'
}