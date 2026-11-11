class CSLinkNukeSphere extends MeshEffect;

// Radius of StaticMesh'Editor.TexPropSphere' at DrawScale 1 (every vertex of
// Source/Editor/Models/TexPropSphere.ASE is 126.733uu from the origin). The spawner sets
// DrawScale3D = DesiredRadius / MeshRadius; the radius peaks at ScaleInterp.Mid (1.0).
var float MeshRadius;

event PostBeginPlay()
{
    Super.PostBeginPlay();
    SetRotation(RotRand());
}

defaultproperties
{
     FadeInterp=(InTime=0.150000,OutTime=0.750000)
     // Visual radius = MeshRadius * DrawScale3D * current ScaleInterp value; Mid=1.0 is the peak.
     // DrawScale3D is set by CSLinkNukeProjectile.SpawnEffects from its DamageRadius.
     MeshRadius=126.733000
     ScaleInterp=(Start=0.100000,Mid=1.000000,InTime=0.500000,OutTime=0.500000,InStyle=IS_InvExp,OutStyle=IS_InvExp)
     DrawType=DT_StaticMesh
     StaticMesh=StaticMesh'Editor.TexPropSphere'
     Skins(0)=FinalBlend'XEffectMat.Shield.RedShell'
     bUnlit=True
}
