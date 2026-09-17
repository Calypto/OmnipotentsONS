class NovaWarhead extends Actor;

var float Damage, DamageRadius, MomentumTransfer;
var class<DamageType> MyDamageType;
var Nova MyNova;
var byte Team;

function SetUp(Nova UseNova)
{
	MyNova = UseNova;

	MyDamageType = MyNova.MyDamageType;
	Damage = MyNova.Damage;
	DamageRadius = MyNova.DamageRadius;
	MomentumTransfer = MyNova.MomentumTransfer;
	Instigator = MyNova.Instigator;
	Team = Instigator.GetTeamNum();
	BlowUp(MyNova.Location);
}

function BlowUp(vector HitLocation)
{
	local Emitter E;

	if ( Role == ROLE_Authority )
	{
		bHidden = true;
		E = Spawn(class'RedeemerExplosion',,, HitLocation - 100 * Normal(Velocity), Rot(0,16384,0));
		if ( Level.NetMode == NM_DedicatedServer )
			E.LifeSpan = 0.7;
		GotoState('Exploding');
	}
}

state Exploding
{
	function BlowUp(vector HitLocation) {}

Begin:
	PlaySound(sound'WeaponSounds.redeemer_explosionsound');
	HurtRadius(Damage, DamageRadius*0.125, MyDamageType, MomentumTransfer, Location);
	Sleep(0.5);
	HurtRadius(Damage, DamageRadius*0.300, MyDamageType, MomentumTransfer, Location);
	Sleep(0.2);
	HurtRadius(Damage, DamageRadius*0.475, MyDamageType, MomentumTransfer, Location);
	Sleep(0.2);
	HurtRadius(Damage, DamageRadius*0.650, MyDamageType, MomentumTransfer, Location);
	Sleep(0.2);
	HurtRadius(Damage, DamageRadius*0.825, MyDamageType, MomentumTransfer, Location);
	Sleep(0.2);
	HurtRadius(Damage, DamageRadius*1.000, MyDamageType, MomentumTransfer, Location);
	if (MyNova != None)
		MyNova.FinishedDetonating();
	Destroy();
}

/* HurtRadius()
 Hurt locally authoritative actors within the radius.
*/
simulated function HurtRadius( float DamageAmount, float DamageRadius, class<DamageType> DamageType, float Momentum, vector HitLocation )
{
	local actor Victims;
	local float damageScale, dist;
	local vector dir;

	if( bHurtEntry )
		return;

	bHurtEntry = true;
	foreach VisibleCollidingActors( class 'Actor', Victims, DamageRadius, HitLocation )
	{
		// don't let blast damage affect fluid - VisibleCollisingActors doesn't really work for them - jag
		if( (Victims != self) && (Victims.Role == ROLE_Authority) && (!Victims.IsA('FluidSurfaceInfo')) && ( (!Victims.IsA('Pawn') && !Victims.IsA('ONSPowerCore')) || (Victims.IsA('Pawn') && Team != Pawn(Victims).GetTeamNum()) || (Victims.IsA('ONSPowerCore') && Team != ONSPowerCore(Victims).DefenderTeamIndex) ) )
		{
			dir = Victims.Location - HitLocation;
			dist = FMax(1,VSize(dir));
			dir = dir/dist;
			damageScale = 1 - FMax(0,(dist - Victims.CollisionRadius)/DamageRadius);
			Victims.TakeDamage
			(
				damageScale * DamageAmount,
				Instigator,
				Victims.Location - 0.5 * (Victims.CollisionHeight + Victims.CollisionRadius) * dir,
				(damageScale * Momentum * dir),
				DamageType
			);
			if (Instigator != None && Vehicle(Victims) != None && Vehicle(Victims).Health > 0)
				Vehicle(Victims).DriverRadiusDamage(DamageAmount, DamageRadius, Instigator.Controller, DamageType, Momentum, HitLocation);
		}
	}
	bHurtEntry = false;
}

defaultproperties
{
     DrawType=DT_None
     bHidden=True
     bReplicateInstigator=True
     NetPriority=3.000000
     bGameRelevant=True
     SoundVolume=255
     SoundRadius=100.000000
     TransientSoundVolume=1.000000
     TransientSoundRadius=5000.000000
}
