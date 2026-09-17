class OmniRedeemerII extends Redeemer;

defaultproperties
{
     FireModeClass(0)=Class'OmniNukes.OmniRedeemerIIFire'
     FireModeClass(1)=Class'OmniNukes.OmniRedeemerIIGuidedFire'
     Description="The first time you witness this upgraded nuclear device in action, you'll wet your pants.|Launch a FAST-moving and utterly devastating missile with the primary fire; but make sure you're out of the Nuker's massive blast radius before it impacts. The secondary fire allows you to guide the nuke yourself with a rocket's-eye view.||Keep in mind, however, that you are vulnerable to attack when steering the RedeemerII's projectile. Due to the extreme bulkiness of its ammo, the RedeemerII is exhausted after a single shot."
     Priority=29
     CustomCrosshair=3
     CustomCrossHairTextureName="Crosshairs.HUD.Crosshair_Circle2"
     GroupOffset=111
     PickupClass=Class'OmniNukes.OmniRedeemerIIPickup'
     AttachmentClass=Class'OmniNukes.OmniRedeemerIIAttachment'
     ItemName="Omni BF Redeemer"
     DrawScale=1.300000
     Skins(0)=Texture'OmniNukes_Tex.OBFDeemer.OBFRedeemerTex0'
     UV2Texture=Shader'XGameShaders.WeaponShaders.WeaponEnvShader'
     HighDetailOverlay=Combiner'UT2004Weapons.WeaponSpecMap2'
}
