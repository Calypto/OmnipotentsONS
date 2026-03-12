class NovaWeb extends VehicleDamageType;

static function ScoreKill(Controller Killer, Controller Killed)
{
	if (Killed != None && Killer != Killed && Vehicle(Killed.Pawn) != None && Vehicle(Killed.Pawn).bCanFly)
	{
		if (PlayerController(Killer) != None)
			PlayerController(Killer).ReceiveLocalizedMessage(class'ONSVehicleKillMessage', 5);
	}
}

defaultproperties
{
     VehicleClass=Class'NovaOmni.Nova'
     DeathString="%o was tied up by %k."
     FemaleSuicide="%o came to a sticky end."
     MaleSuicide="%o came to a sticky end."
     bArmorStops=False
     bDetonatesGoop=True
     bDelayedDamage=True
}