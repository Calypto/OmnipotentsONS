//=============================================================================
// SmallKraken.
//=============================================================================
class SmallKraken extends Kraken;

defaultproperties
{
     VehiclePositionString="in a Tiamat"
     VehicleNameString="Tiamat"
     HealthMax=5000.000000
     Health=5000
     DrawScale=0.800000

     RedSkin=Texture'DevilsArsenal_Tex.Kraken.KrakenRed'
     BlueSkin=Texture'DevilsArsenal_Tex.Kraken.KrakenBlue'

	 // Re-declare the wheels to scale down the WheelRadius (99 * 0.8 = ~79.2)
     Begin Object Class=SVehicleWheel Name=RightRearTIRe
         bPoweredWheel=True
         bHandbrakeWheel=True
         SteerType=VST_Inverted
         BoneName="RightRearTIRe"
         BoneRollAxis=AXIS_Y
         WheelRadius=79.200000
     End Object
     Wheels(0)=SVehicleWheel'CSKraken.SmallKraken.RightRearTIRe'

     Begin Object Class=SVehicleWheel Name=LeftRearTIRE
         bPoweredWheel=True
         bHandbrakeWheel=True
         SteerType=VST_Inverted
         BoneName="LeftRearTIRE"
         BoneRollAxis=AXIS_Y
         WheelRadius=79.200000
     End Object
     Wheels(1)=SVehicleWheel'CSKraken.SmallKraken.LeftRearTIRE'

     Begin Object Class=SVehicleWheel Name=RightFrontTIRE
         bPoweredWheel=True
         SteerType=VST_Steered
         BoneName="RightFrontTIRE"
         BoneRollAxis=AXIS_Y
         WheelRadius=79.200000
     End Object
     Wheels(2)=SVehicleWheel'CSKraken.SmallKraken.RightFrontTIRE'

     Begin Object Class=SVehicleWheel Name=LeftFrontTIRE
         bPoweredWheel=True
         SteerType=VST_Steered
         BoneName="LeftFrontTIRE"
         BoneRollAxis=AXIS_Y
         WheelRadius=79.200000
     End Object
     Wheels(3)=SVehicleWheel'CSKraken.SmallKraken.LeftFrontTIRE'

     Begin Object Class=KarmaParamsRBFull Name=KarmaParamsRBFull5
         KInertiaTensor(0)=1.300000
         KInertiaTensor(3)=4.000000
         KInertiaTensor(5)=4.500000
         KLinearDamping=0.150000
         KAngularDamping=0.000000
         KStartEnabled=True
         bHighDetailOnly=False
         bClientOnly=False
         bKDoubleTickRate=True
         bKStayUpright=True
         bKAllowRotate=True
         bDestroyOnWorldPenetrate=True
         bDoSafetime=True
         KFriction=0.500000
         KImpactThreshold=700.000000
     End Object
     KParams=KarmaParamsRBFull'CSKraken.KarmaParamsRBFull5'
}