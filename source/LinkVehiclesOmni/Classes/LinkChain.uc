//=============================================================================
// LinkChain
// Link counting shared by the link vehicles.
//
// Every link beam is a LinkBeamEffect whose LinkedPawn is set on the server,
// so together the beams form the link graph: infantry link guns, every link
// vehicle, and link beams from other packages. A vehicle's link count is the
// number of distinct pawns whose beams reach it, directly or through a chain.
// Each pawn counts once, so beams that loop back cannot inflate the count.
//=============================================================================
class LinkChain extends Object
	abstract;

// ============================================================================
// CountLinkers
// Returns how many distinct pawns beam into Root, directly or through a chain.
// Export receives the same count minus the pawns that only reach Root through
// Root's own link target. That is what the target should be credited with:
// in a loop it already counts those pawns itself.
// ============================================================================
static function int CountLinkers(Pawn Root, out int Export)
{
	local LinkBeamEffect B;
	local Pawn S, D, Target;
	local Pawn Src[32], Dst[32], Seen[33];
	local byte ViaTarget[33];
	local int NumEdges, NumSeen, NumVia, Head, i;

	foreach Root.DynamicActors(class'LinkBeamEffect', B)
	{
		D = B.LinkedPawn;
		if (D == None)
			continue;

		// Vehicle beams are owned by the vehicle (or passenger seat), infantry beams by the player
		S = Pawn(B.Owner);
		if (S == None)
			S = B.Instigator;
		if (S == None)
			continue;
		if (S.DrivenVehicle != None)
			S = S.DrivenVehicle;

		// A link onto a driver or a passenger seat counts for the vehicle itself
		if (D.DrivenVehicle != None)
			D = D.DrivenVehicle;
		if (ONSWeaponPawn(D) != None && ONSWeaponPawn(D).VehicleBase != None)
			D = ONSWeaponPawn(D).VehicleBase;

		if (S == Root)
		{
			Target = D;
			continue;
		}

		// A pawn links a single target, so another beam from the same source
		// (the Lamprey's twin beams) is the same edge
		for (i = 0; i < NumEdges; i++)
			if (Src[i] == S)
				break;
		if (i < NumEdges || NumEdges == ArrayCount(Src))
			continue;

		Src[NumEdges] = S;
		Dst[NumEdges] = D;
		NumEdges++;
	}

	// Walk the beams backwards from Root. Each source has one edge and Root's
	// own beam is left out, so every pawn is reached exactly once.
	Seen[0] = Root;
	NumSeen = 1;
	for (Head = 0; Head < NumSeen; Head++)
	{
		for (i = 0; i < NumEdges; i++)
		{
			if (Dst[i] == Seen[Head])
			{
				Seen[NumSeen] = Src[i];
				if (ViaTarget[Head] != 0 || Src[i] == Target)
				{
					ViaTarget[NumSeen] = 1;
					NumVia++;
				}
				NumSeen++;
			}
		}
	}

	Export = NumSeen - 1 - NumVia;
	return NumSeen - 1;
}
