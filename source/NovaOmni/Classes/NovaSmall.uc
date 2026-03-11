// Smaller, slower version of the Nova
class NovaSmall extends Nova
	placeable;

defaultproperties
{
	VehicleNameString="Small Nova )o("

	DrawScale=0.875

	AirTurnTorque=35.0
	AirPitchTorque=55.0
	AirPitchDamping=35.0
	AirRollTorque=35.0
	AirRollDamping=35.0

	WheelPenScale=1.2
	WheelPenOffset=0.01
	WheelSoftness=0.025
	WheelRestitution=0.1
	WheelAdhesion=0.0
	WheelLongFrictionFunc=(Points=((InVal=0,OutVal=0.0),(InVal=100.0,OutVal=1.0),(InVal=200.0,OutVal=0.9),(InVal=10000000000.0,OutVal=0.9)))
	WheelLongFrictionScale=1.1
	WheelLatFrictionScale=1.35
	WheelLongSlip=0.001
	WheelLatSlipFunc=(Points=((InVal=0.0,OutVal=0.0),(InVal=30.0,OutVal=0.009),(InVal=45.0,OutVal=0.00),(InVal=10000000000.0,OutVal=0.00)))
	WheelHandbrakeSlip=0.01
	WheelHandbrakeFriction=0.1
	WheelSuspensionTravel=15.0
	WheelSuspensionOffset=0.0
	WheelSuspensionMaxRenderTravel=15.0
	TurnDamping=35

	HandbrakeThresh=200
	FTScale=0.03
	ChassisTorqueScale=0.4

	MinBrakeFriction=4.0
	MaxBrakeTorque=20.0
	MaxSteerAngleCurve=(Points=((InVal=0,OutVal=25.0),(InVal=1500.0,OutVal=11.0),(InVal=1000000000.0,OutVal=11.0)))
	SteerSpeed=160
	StopThreshold=100
	TorqueCurve=(Points=((InVal=0,OutVal=9.0),(InVal=200,OutVal=10.0),(InVal=1500,OutVal=11.0),(InVal=2800,OutVal=0.0)))
	EngineBrakeFactor=0.0001
	EngineBrakeRPMScale=0.1
	EngineInertia=0.1
	WheelInertia=0.1

	TransRatio=0.15
	ChangeUpPoint=2000
	ChangeDownPoint=1000
	LSDFactor=1.0

	VehicleMass=3.5

	Begin Object Class=KarmaParamsRBFull Name=KParams0
		KStartEnabled=True
		KFriction=0.5
		KLinearDamping=0.05
		KAngularDamping=0.05
		KImpactThreshold=700
		bKNonSphericalInertia=True
		bHighDetailOnly=False
		bClientOnly=False
		bKDoubleTickRate=True
		KInertiaTensor(0)=1.0
		KInertiaTensor(1)=0.0
		KInertiaTensor(2)=0.0
		KInertiaTensor(3)=3.0
		KInertiaTensor(4)=0.0
		KInertiaTensor(5)=3.0
		KCOMOffset=(X=-0.25,Y=0.0,Z=-0.4)
		bDestroyOnWorldPenetrate=True
		bDoSafetime=True
		Name="KParams0"
	End Object
	KParams=KarmaParams'KParams0'

	 Begin Object Class=SVehicleWheel Name=NovaRR
		 bPoweredWheel=True
		 bHandbrakeWheel=True
		 BoneName="tire02"
		 BoneRollAxis=AXIS_Y
		 BoneOffset=(Y=7.000000)
		 WheelRadius=21
		 SupportBoneName="RrearStrut"
		 SupportBoneAxis=AXIS_X
	 End Object
	 Wheels(0)=SVehicleWheel'NovaOmni.NovaSmall.NovaRR'

	 Begin Object Class=SVehicleWheel Name=NovaLR
		 bPoweredWheel=True
		 bHandbrakeWheel=True
		 BoneName="tire04"
		 BoneRollAxis=AXIS_Y
		 BoneOffset=(Y=-7.000000)
		 WheelRadius=21
		 SupportBoneName="LrearStrut"
		 SupportBoneAxis=AXIS_X
	 End Object
	 Wheels(1)=SVehicleWheel'NovaOmni.NovaSmall.NovaLR'

	 Begin Object Class=SVehicleWheel Name=NovaRF
		 bPoweredWheel=True
		 SteerType=VST_Steered
		 BoneName="tire"
		 BoneRollAxis=AXIS_Y
		 BoneOffset=(Y=7.000000)
		 WheelRadius=21
		 SupportBoneName="RFrontStrut"
		 SupportBoneAxis=AXIS_X
	 End Object
	 Wheels(2)=SVehicleWheel'NovaOmni.NovaSmall.NovaRF'

	 Begin Object Class=SVehicleWheel Name=NovaLF
		 bPoweredWheel=True
		 SteerType=VST_Steered
		 BoneName="tire03"
		 BoneRollAxis=AXIS_Y
		 BoneOffset=(Y=-7.000000)
		 WheelRadius=21
		 SupportBoneName="LfrontStrut"
		 SupportBoneAxis=AXIS_X
	 End Object
	 Wheels(3)=SVehicleWheel'NovaOmni.NovaSmall.NovaLF'
}