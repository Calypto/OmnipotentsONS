class IonPainterOmni extends Painter;

// Same as Painter.CheckMark, but makes sure the level's cannon is an IonCannonOmni
// (keeps kill credit after the painter dies or enters a vehicle).
function IonCannon CheckMark(vector MarkLocation, bool bFire)
{
	local IonCannon C, N;

	if ( FirstCannon != None )
		return FirstCannon;

	foreach DynamicActors(class'IonCannon', C)
	{
		if ( IonCannonOmni(C) != None )
		{
			FirstCannon = C;
			return C;
		}
		// stock cannon mid-strike: use it as-is for now, replace it on a later call
		if ( C.IsFiring() )
			return C;
		// stock cannon (map-placed or from a stock Painter): replace it in place.
		// IonCannon.PostBeginPlay destroys every other IonCannon.
		N = Spawn(class'IonCannonOmni',,, C.Location, C.Rotation);
		if ( N == None )
			return C;
		IonCannonOmni(N).CopyFrom(C);
		FirstCannon = N;
		return N;
	}

	FirstCannon = Spawn(class'IonCannonOmni',,, Location + vect(0,0,2000));
	return FirstCannon;
}

defaultproperties
{
     PickupClass=Class'OmniPainters.IonPainterOmniPickup'
     ItemName="Ion Painter Omni"
     FireModeClass(0)=Class'OmniPainters.IonPainterFireOmni'
     GroupOffset=150
}
