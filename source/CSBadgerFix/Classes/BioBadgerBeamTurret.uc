//=============================================================================
// BioBadgerBeamTurret.
//=============================================================================
class BioBadgerBeamTurret extends BioSecondaryTurret;

defaultproperties
{
     YawBone="MiniGunBase"
     PitchBone="MinigunBarrel"
     PitchUpLimit=8000
     PitchDownLimit=62500
     WeaponFireAttachmentBone="MinigunFire"
     WeaponFireOffset=0.000000
     DualFireOffset=0.000000
     BeamEffectClass(0)=Class'CSBadgerFix.BioBadgerBeamEffect'
     BeamEffectClass(1)=Class'CSBadgerFix.BioBadgerBeamEffect'
     RedSkin=Texture'MoreBadgers.BioBadger.BioBadgerRed'
     BlueSkin=Texture'MoreBadgers.BioBadger.BioBadgerBlue'
     //FireSoundClass=Sound'CuddlyArmor_Sound.BioTank.BioBeam' (inherited from BioSecondaryTurret)
     FireSoundClass=Sound'WeaponSounds.Misc.instagib_rifleshot'
     DamageType=Class'CSBadgerFix.BioBadgerBeamKill'
     Mesh=SkeletalMesh'CSBadgerFix.BadgerMinigun'
}
