// ============================================================================
// // Link Turret taken from HospitilarLinkTurret Turret Omni
// ============================================================================
class HospitalerLinkTurret extends ONSWeapon;

// ============================================================================
// Properties
// ============================================================================

// 0 = Red, 1 = Blue
var() array<Material> LinkSkin_Gold, LinkSkin_Green, LinkSkin_Red, LinkSkin_Blue;
var() int LinkBeamSkin;
var() sound LinkedFireSound;

// CPed from LinkFire
var(LinkBeam) class<HospitalerLinkTurretBeamEffect>	BeamEffectClass;
var(LinkBeam) Sound	MakeLinkSound;
var(LinkBeam) float LinkBreakDelay;
var(LinkBeam) float MomentumTransfer;
var(LinkBeam) class<DamageType> AltDamageType;
var(LinkBeam) int AltDamage;
var(LinkBeam) String MakeLinkForce;
var(LinkBeam) float LinkFlexibility;
var(LinkBeam) Sound BeamSounds[4];
var(LinkBeam) float VehicleDamageMult;
var(LinkBeam) float LinkMultiplierCap;
var(LinkBeam) float ShieldPassDamageScale; // beam damage multiplier per teammate Bastion/Fanatic/Hospitaler shield passed through

var float LinkMultiplier;  // linkers increase factor, not used in vampire, but will leave the code just in case want to add it back
var HospitalerLinkTurretBeamEffect Beam;
var float SelfHealMultiplier; 
var config int VehicleHealScore;
var HospitalerV3Omni MyHospitaler;  // need reference to it vehicle
var float RangeExtPerLink;

// ============================================================================
// Internal vars
// ============================================================================
//var LinkBeamEffect			Beam;

// CPed from LinkFire
var float	UpTime;
var Pawn	LockedPawn;
var float	LinkBreakTime;

var bool bInitAimError;
var		bool bDoHit;
var		bool bFeedbackDeath;
var		bool bLinkFeedbackPlaying;
var		bool bStartFire;
var rotator DesiredAimError, CurrentAimError;

var bool bBeaming;							// True if utilizing alt-fire
var bool bLinking; //true if alt-fire and locked to pawn
var int SentLinks; // links SetLinkTo credited to LockedPawn's link gun chain (server only)

// ============================================================================
replication
// ============================================================================
{
	reliable if (Role == ROLE_Authority)
		Beam;
	unreliable if (Role == ROLE_Authority && bNetDirty)
    bBeaming;
}

simulated function UpdatePrecacheMaterials()
{
	Super.UpdatePrecacheMaterials();
	
	// this stuff should be covered by LinkGun anyway
//	Level.AddPrecacheMaterial(Texture'XEffectMat.Link.link_beam_green');  // hard-coded texture reference
//	Level.AddPrecacheMaterial(MapperSpecifiedMaterial);          // specified by mapper in UnrealEd
}

simulated function UpdatePrecacheStaticMeshes()
{
	Super.UpdatePrecacheStaticMeshes();
//	Level.AddPrecacheStaticMesh(StaticMesh'MyStaticMesh');
}

simulated function PostNetBeginPlay()
{
	//if(HospitilarLinkTurret(Owner) != None)
	//	MyHospitaler = HospitilarLinkTurret(ONSWeaponPawn(Owner).VehicleBase);
	
	
	Super.PostNetBeginPlay();
}
 



// ============================================================================
// Spawn projectile. Adjust link properties if needed.
// ============================================================================
function Projectile SpawnProjectile(class<Projectile> ProjClass, bool bAltFire)
{
	local Projectile SpawnedProjectile;
	local int NumLinks;

  //log("HospitilarLinkTurretSecondaryTurret VT="$HospitilarLinkTurret(ONSWeaponPawn(Owner).VehicleBase));

	if (HospitalerV3Omni(ONSWeaponPawn(Owner).VehicleBase) != None)
		NumLinks = HospitalerV3Omni(ONSWeaponPawn(Owner).VehicleBase).Links;
	else
		NumLinks = 0;

  //log("HospitilarLinkTurretSecondaryTurret NumLinks="$NumLinks);
	// Swap out fire sound
	if (NumLinks > 0)
		FireSoundClass = LinkedFireSound;
	else
		FireSoundClass = default.FireSoundClass;

	SpawnedProjectile = Super.SpawnProjectile(ProjClass, bAltFire);
	if (SpawnedProjectile != None)
	{

  		HospitalerLinkPlasma(SpawnedProjectile).Links = NumLinks;
  		HospitalerLinkPlasma(SpawnedProjectile).LinkAdjust();  //sets size based on links.
  		
	}

	return SpawnedProjectile;
}

// ============================================================================
// Spawn/find link beam
// ============================================================================
function SpawnBeamEffect(Vector Start, Rotator Dir, Vector HitLocation, Vector HitNormal, int ReflectNum)
{
	//local HospitilarLinkTurretTurretBeamEffect ThisBeam;
	//local HospitilarLinkTurretTurretBeamEffect FoundBeam;

	//if (HospitilarLinkTurret(Owner) != None)
	//	FoundBeam = HospitilarLinkTurret(Owner).Beam;

	//if (FoundBeam == None || FoundBeam.bDeleteMe)
	//{
	//	foreach DynamicActors(class'HospitilarLinkTurretTurretBeamEffect', ThisBeam)
	//		if (ThisBeam.Instigator == Instigator)
	//			FoundBeam = ThisBeam;
	//}

	//if (FoundBeam == None)
	//{
	//	FoundBeam = Spawn(BeamEffectClass, Owner,,WeaponFireLocation);
	//	if (HospitilarLinkTurret(Owner) != None) HospitilarLinkTurret(Owner).Beam = FoundBeam;
	//}


	if (Beam == None)
	  {
	  	Beam = Spawn(BeamEffectClass, Owner,,WeaponFireLocation);
	  	//log("Spawned Beam="$Beam,'VampTankSpawnBeamEffect');
	  	//if (HospitilarLinkTurret(Owner) != None) HospitilarLinkTurret(Owner).Beam = FoundBeam;
	  }


	bDoHit = true;
	UpTime = AltFireInterval + 0.1;
}

simulated function ClientStartFire(Controller C, bool bAltFire)
{
	//log(self@"client start fire alt"@bAltFire,'KDebug');
	Super.ClientStartFire(C, bAltFire);

	// Write UpTime here in the client
	if (bAltFire && Role < ROLE_Authority)
	{
		UpTime = AltFireInterval + 0.1;
//		log("UpTime is now"@UpTime,'KDebug');
	}
}

// ============================================================================
// Cease fire, destroy link beam
// ============================================================================
function WeaponCeaseFire(Controller C, bool bWasAltFire)
{
	//local HospitilarLinkTurretTurretBeamEffect Beam;

	//if (HospitilarLinkTurret(Owner) != None)
	//	Beam = HospitilarLinkTurret(Owner).Beam;
	//log(self@"WeaponCeaseFire, bWasAltFire"@bWasAltFire,'VampireTankDebug');
  Super.WeaponCeaseFire(C, bWasAltFire);
	
	if (bWasAltFire && Beam != None)
	{
		Beam.Destroy();
		Beam = None;
		if (HospitalerLinkTurret(Owner) != None)
		{
			//HospitilarLinkTurret(Owner).Beam = None;
			bBeaming = false;
		}
		AmbientSound = None;
		SetLinkTo(None);
	  bLinking=False;
		// Can't link if there's no beam
		/* following for changing colors on link panels Hosp has not of that
		if (HospitilarLinkTurret(Owner) != None)
		{
			//log(Level.TimeSeconds@Self@"Set Link Tank bLinking to FALSE in WeaponCeaseFire",'KDebug');
			//HospitilarLinkTurret(Owner).bLinking = false;
		}
		*/
	}
}

// ============================================================================
// Destroyed
// Dying with the Hospitaler skips cease-fire, so take back links credited to LockedPawn
// ============================================================================
simulated function Destroyed()
{
	if (SentLinks != 0)
		RemoveLink(SentLinks, MyHospitaler);
	Super.Destroyed();
}

// ============================================================================
// ModeTick -- Maintain alt-firing link beam.
// Mostly c/p'd from LinkFire and modified accordingly to work with ONSWeapon
// ============================================================================
simulated event Tick(float dt)
{
	local Vector StartTrace, EndTrace, V, X, Y, Z;
	local Vector HitLocation, HitNormal, EndEffect;
	local Actor Other;
	local Rotator Aim;
	
	//local float Step, ls;
	//local bot B;
	local bool bIsHealingObjective;
	local int AdjustedDamage, NumLinks;
	//local LinkBeamEffect LB;
	local DestroyableObjective HealObjective;
	local Vehicle LinkedVehicle;
	local float BeamDamageScale;

	//local HospitilarLinkTurretTurretBeamEffect Beam;

	//log(self@"tick beam"@Beam@"uptime"@UpTime@"role"@Role,'KDebug');

	// No Super.Tick(): ONSWeapon has no script Tick and Actor.Tick is an empty event.

	// Nothing to maintain without a beam. Covers clients too, which otherwise ran
	// CalcWeaponFire() and a full BeamTrace() every frame for every idle link turret.
	if (Beam == None)
		return;

	// We're not a LinkGun, so we don't need this
	//LinkGun = LinkGun(Weapon);
	// Instead let's get a reference to our LinkTank
	// This is easily changed over if I decide I want to recode the Link Badger based off this code
	//log(Level.TimeSeconds@self@"TICK -- Owner"@Owner@"LinkTank of Owner"@HospitilarLinkTurret(Owner),'KDebug');

	// The gun is bone-attached to its Hospitaler; Base replicates to every client (Owner only to the owning one).
	// Read Links directly: GetLinks() isn't simulated, so clients got 0 and drew the beam without RangeExtPerLink.
	MyHospitaler = HospitalerV3Omni(Base);
	if (MyHospitaler != None)
		NumLinks = MyHospitaler.Links;
	
	
	
	  
	//if (Role < ROLE_Authority)
	//	log(Level.TimeSeconds@self@"TICK -- Role"@Role@"LinkBeam"@Beam,'KDebug');


	//if (MyHospitaler != None && MyHospitaler.GetLinks() < 0) 	{
        //log("warning:"@Instigator@"linktank had"@LinkTank.GetLinks()@"links");
  //      MyHospitaler.ResetLinks();
  // }

    if ( (UpTime > 0.0) || (Role < ROLE_Authority) )     {
//		log("warning: logspam ahead",'KDebug');
//		log("UpTime -= dt",'KDebug');
		UpTime -= dt;

		// FireStart begins at WeaponFireLocation
		//log("CalcWeaponFire",'KDebug');
		CalcWeaponFire();
//		log("GetAxes",'KDebug');
		GetAxes( WeaponFireRotation, X, Y, Z );
//		log("StartTrace = WeaponFireLocation",'KDebug');
		StartTrace = WeaponFireLocation;
//		log("TraceRange = default.TraceRange + NumLinks*250",'KDebug');
		TraceRange = default.TraceRange + NumLinks*RangeExtPerLink;

//		log("if role < role authority then do shit",'KDebug');
		// Get client LockedPawn
		if ( Role < ROLE_Authority )
        {
			//log(Level.TimeSeconds@self@"looking for a beam current beam"@beam,'KDebug');
			
			/*
			if ( Beam == None )
				ForEach DynamicActors(class'LinkBeamEffect', LB )
				{
					//log(self@"in tick check linkbeam"@LB@"instigator"@LB.Instigator@"vs our instigator"@Instigator@"and possibly our driver"@Vehicle(Owner).Driver@"also the link beams' bdelete is"@LB.bDeleteMe,'KDebug');
					//log("also our owner is"@owner@"and our owner's owner is"@owner.owner@"and our instigator is"@instigator@"and our instigator's owner is"@instigator.owner,'KDebug');
					//if ( !LB.bDeleteMe && (LB.Instigator != None) && (LB.Instigator == Instigator) )
					//log(self@"check beam"@lb@"owner"@lb.owner@"our owner"@owner@"instigator"@instigator,'KDebug');
					//if ( !LB.bDeleteMe && (LB.Instigator != None) && (LB.Owner == Owner) )
					if (HospitilarLinkTurretTurretBeamEffect(LB) != None && HospitilarLinkTurretTurretBeamEffect(LB).WeaponOwner == self)
					{
						log("and now it's ours",'KDebug');
						Beam = LB;
						break;
					}
				}
			*/

			LockedPawn = Beam.LinkedPawn;
			//log("in tick found beam"@beam@"locked onto"@LockedPawn,'KDebug');
		}

		// If we're locked onto a pawn increase our trace distance
      if ( LockedPawn != None ) TraceRange *= 1.5;

	
		if ( LockedPawn != None )
		{
			EndTrace = LockedPawn.Location + LockedPawn.BaseEyeHeight*Vect(0,0,0.5); // beam ends at approx gun height
			if ( Role == ROLE_Authority )
			{
				V = Normal(EndTrace - StartTrace);
				if ( (V dot X < LinkFlexibility) || LockedPawn.Health <= 0 || LockedPawn.bDeleteMe || (VSize(EndTrace - StartTrace) > 1.5 * TraceRange) )
				{				SetLinkTo( None ); 				}
			}
		}


        if ( LockedPawn == None )
        {
	        if (Role == ROLE_Authority)
	        	Aim = AdjustAim(true);
	        else
	        	Aim = WeaponFireRotation;

            X = Vector(Aim);
            EndTrace = StartTrace + TraceRange * X;
        }

        Other = BeamTrace(self, HitLocation, HitNormal, EndTrace, StartTrace, BeamDamageScale);
        if ( Other != None && Other != Instigator )
			     EndEffect = HitLocation;
		    else
			     EndEffect = EndTrace;

		    Beam.EndEffect = EndEffect;

				if ( Role < ROLE_Authority ) return;
		
        if ( Other != None && Other != Instigator && Other != Vehicle(Instigator) )
        {
            // target can be linked to
            if ( IsLinkable(Other) )
            {
                if ( Other != lockedpawn )  SetLinkTo( Pawn(Other) );
                if ( lockedpawn != None )   LinkBreakTime = LinkBreakDelay;
            }
            else
            {    // stop linking
                if ( lockedpawn != None )
                {
                    if ( LinkBreakTime <= 0.0 ) 
                        SetLinkTo( None );
                    else
                        LinkBreakTime -= dt;
                }

                // beam is updated every frame, but damage is only done based on the firing rate
                if ( bDoHit )
                {
                    if ( Beam != None )  Beam.bLockedOn = false;

                    Instigator.MakeNoise(1.0);


                    if ( !Other.bWorldGeometry )
                    {
                        if ( Level.Game.bTeamGame && Pawn(Other) != None && Pawn(Other).PlayerReplicationInfo != None
							           && Pawn(Other).PlayerReplicationInfo.Team == Instigator.PlayerReplicationInfo.Team) // so even if friendly fire is on you can't hurt teammates
                            AdjustedDamage = 0;

												HealObjective = DestroyableObjective(Other);
												if ( HealObjective == None )
													HealObjective = DestroyableObjective(Other.Owner);
												if ( HealObjective != None && HealObjective.TeamLink(Instigator.GetTeamNum()) )
												{
													SetLinkTo(None,true);
													//log(Level.TimeSeconds@Self@"Set Link Tank bLinking to TRUE in Tick",'KDebug');
													bLinking = true;
													bIsHealingObjective = true;
									  			AdjustedDamage = AdjustLinkDamage( NumLinks, None, AltDamage ); // no vehicle damage mutli on healing, passing in None deactivates.
													HealObjective.HealDamage(AdjustedDamage, Instigator.Controller, DamageType);
													//if (!HealObjective.HealDamage(AdjustedDamage, Instigator.Controller, DamageType))
													//	LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
												}
												else
												{
													if (LockedPawn != None)
														warn(self@"called takedamage with a linked pawn!!!");
													else {
														 AdjustedDamage = AdjustLinkDamage( NumLinks, Other, AltDamage ) * BeamDamageScale;
														 Other.TakeDamage(AdjustedDamage, Instigator, HitLocation, MomentumTransfer*X, AltDamageType);
														 //log(self@"Just before HealDamage to MyHospitaler="@MyHospitaler); 
														// if (MyHospitaler!=None&&MyHospitaler.Health<MyHospitaler.HealthMax&&(ONSPowerCore(HealObjective)==None||ONSPowerCore(HealObjective).PoweredBy(Team)&&!LockedPawn.IsInState('NeutralCore')))
						                //     MyHospitaler.HealDamage(Round(AdjustedDamage * SelfHealMultiplier), Instigator.Controller, DamageType);
													}	
												}

												if ( Beam != None )
													Beam.bLockedOn = true;
										}  // World geo
						}  // do hit
			}
		}

		// vehicle healing
		LinkedVehicle = Vehicle(LockedPawn);
		
		//log(self@" LinkedVehicle="@LinkedVehicle@" ONSWeaponPawn(Owner).VehicleBase="@ONSWeaponPawn(Owner).VehicleBase);
		// exclude self healing.
		if ( LinkedVehicle != None && bDoHit && (LinkedVehicle != ONSWeaponPawn(Owner).VehicleBase) && LinkedVehicle != Instigator )
		{
			AdjustedDamage = AdjustLinkDamage( NumLinks, None, AltDamage ) * Instigator.DamageScaling;
		
			 if(LinkedVehicle.HealDamage(AdjustedDamage, Instigator.Controller, DamageType))
	     			   if (ONSPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo) != None && !LinkedVehicle.IsVehicleEmpty())
                  ONSPlayerReplicationInfo(Instigator.Controller.PlayerReplicationInfo).AddHealBonus(FMin((AdjustedDamage * LinkedVehicle.LinkHealMult) / VehicleHealScore, LInkedVehicle.HealthMax - LinkedVehicle.Health)); 
			//LinkedVehicle.HealDamage(AdjustedDamage, Instigator.Controller, DamageType);
			//if (!LinkedVehicle.HealDamage(AdjustedDamage, Instigator.Controller, DamageType))
			//	LinkGun.ConsumeAmmo(ThisModeNum, -AmmoPerFire);
		}
		/* Linking for changing tank panel colors hosp has none
		if (MyHospitaler != None && bDoHit)
		{
			//log(Level.TimeSeconds@Self@"Set Link Tank bLinking to (LockedPawn != None) || bIsHealingObjective in Tick",'KDebug');
			MyHospitaler.bLinking = (LockedPawn != None) || bIsHealingObjective;
			//log("(This resolved to"@LinkTank.bLinking$")",'KDebug');
		}
 */

		//if ( bShouldStop )
		//	B.StopFiring();
		//else
		//{

		// Beam is created in TraceFire, don't create it again here.

		// beam effect is created and destroyed when firing starts and stops
		//if ( (Beam == None) && bIsFiring )
		//{
		//	Beam = Weapon.Spawn( BeamEffectClass, Instigator );
		//	// vary link volume to make sure it gets replicated (in case owning player changed it client side)
		//	if ( SentLinkVolume == Default.LinkVolume )
		//		SentLinkVolume = Default.LinkVolume + 1;
		//	else
		//		SentLinkVolume = Default.LinkVolume;
		//}

		// Handle color changes
		if ( Beam != None )
		{
			if ( (MyHospitaler != None && bLinking) || ((Other != None) && (Instigator.PlayerReplicationInfo.Team != None) && Other.TeamLink(Instigator.PlayerReplicationInfo.Team.TeamIndex)) )
			  	Beam.LinkColor = Instigator.PlayerReplicationInfo.Team.TeamIndex + 1;
			else
					Beam.LinkColor = 0;
			
			Beam.Links = NumLinks;
			// Hum plays on the gun at the SoundVolume/SoundPitch in defaultproperties.
			// Don't assign FireSoundVolume (256.0) here: SoundVolume is a byte and it wraps to 0 (silent).
			AmbientSound = BeamSounds[Min(NumLinks,3)];
			Beam.LinkedPawn = LockedPawn;
			Beam.bHitSomething = (Other != None);
			Beam.EndEffect = EndEffect;
		}

		//}
	}
	
	bDoHit = false;
}
// ============================================



// ============================================================================
// AdjustLinkDamage
// Return adjusted damage based on number of links
// Takes a NumLinks argument instead of an actual LinkGun
// ============================================================================
function float AdjustLinkDamage( int NumLinks, Actor Target, float Damage )
{
	local float AdjDamage;
	
	AdjDamage = Damage * FMin(LinkMultiplier*NumLinks+1,LinkMultiplierCap);
	// no matter how many linkers Multiplier Cap

	if (Target != None && Target.IsA('Vehicle') ) 	AdjDamage *= VehicleDamageMult;
  if (Instigator.HasUDamage()) 	AdjDamage *= 2;
	
	return AdjDamage;
	
}


// ============================================================================
// SetLinkTo
// Add our link to the other pawn
// ============================================================================
function SetLinkTo(Pawn Other, optional bool bHealing)
{
	// Sanity check
	if (LockedPawn != Other)
	{
	    // Take back exactly what AddLink() credited; the Hospitaler's links may have changed since
	    if (SentLinks != 0)
	    {
	        RemoveLink(SentLinks, MyHospitaler);
	        SentLinks = 0;

	        if (!bHealing)
	        {
				//log(Level.TimeSeconds@Self@"Set Link Tank bLinking to FALSE in SetLinkTo"@Other,'KDebug');
	        //	MyHospitaler.bLinking = false;
	        }
	    }

	    LockedPawn = Other;

	    // Light up panels if linking a node
	    //if (HospitilarLinkTurret(Owner) != None)
	    //	HospitilarLinkTurret(Owner).bLinking = bIsHealingObjective;

	    if (LockedPawn != None)
	    {
			// Link like a link gun carrying the Hospitaler's links (LinkFire uses 1 + Links). With the Hospitaler
			// as Starter, LinkFire.AddLink refuses (crediting nothing) if the target's chain already feeds into it.
			SentLinks = 1;
			if (MyHospitaler != None)
				SentLinks += MyHospitaler.Links;
			if (!AddLink(SentLinks, MyHospitaler))
				SentLinks = 0;
	
	        LockedPawn.PlaySound(MakeLinkSound, SLOT_None);
	    }
	}   
}

// ============================================================================
// AddLink
// Add our links to the target's LinkGun
// No need to notify other LinkTanks -- they will pick up the link automatically in HealDamage
// (This will also work for other Link Vehicles utilizing the same code)
// c/p'd from LinkFire
// ============================================================================
function bool AddLink(int Size, Pawn Starter)
{
    local Inventory Inv;
    if (LockedPawn != None && !bFeedbackDeath)
    {
        if (LockedPawn == Starter)
        {
            return false;
        }
        else
        {
            Inv = LockedPawn.FindInventoryType(class'LinkGun');
            if (Inv != None)
            {
                if (LinkFire(LinkGun(Inv).GetFireMode(1)).AddLink(Size, Starter))
                    LinkGun(Inv).Links += Size;
                else
                    return false;
            }
        }
    }
    return true;
}

// ============================================================================
// RemoveLink
// Remove our link from the target's LinkGun
// c/p'd from LinkFire
// ============================================================================
function RemoveLink(int Size, Pawn Starter)
{
    local Inventory Inv;
    if (LockedPawn != None && !bFeedbackDeath)
    {
        if (LockedPawn != Starter)
        {
            Inv = LockedPawn.FindInventoryType(class'LinkGun');
            if (Inv != None)
            {
				//log(self@"removing link from"@Inv);
                LinkFire(LinkGun(Inv).GetFireMode(1)).RemoveLink(Size, Starter);
                LinkGun(Inv).Links -= Size;
            }
        }
    }
}

// ============================================================================
// IsLinkable
// More c/p action
// ============================================================================
function bool IsLinkable(Actor Other)
{
    local Pawn P;
    local LinkGun LG;
    local LinkFire LF;
    local int sanity;
    //local ONSVehicle OwnerVehicle;

   // log(self@"IsLinkable:Other..."@Other);
	  if (Other == Vehicle(Instigator) || Other == ONSWeaponPawn(Owner).VehicleBase) {
	  //	log(self@"Don't link self!");
	  	return false;
	  }
	  
    if ( Other.IsA('Pawn') && Other.bProjTarget )   {
        P = Pawn(Other);
        if ( P.Weapon == None || !P.Weapon.IsA('LinkGun') )
				{
	  			if ( Vehicle(P) != None ) return P.TeamLink( Instigator.GetTeamNum() );
    			return false;
		    }

        // pro-actively prevent link cycles from happening
        LG = LinkGun(P.Weapon);
        LF = LinkFire(LG.GetFireMode(1));
        while ( LF != None && LF.LockedPawn != None && LF.LockedPawn != P && sanity < 32 )
        {
            if ( LF.LockedPawn == Pawn(Owner) )
                return false;

            LG = LinkGun(LF.LockedPawn.Weapon);
            if ( LG == None )
                break;
            LF = LinkFire(LG.GetFireMode(1));
            sanity++;
        }

        return ( Level.Game.bTeamGame && P.GetTeamNum() == Instigator.GetTeamNum() );
    }

    return false;
}

// ============================================================================
// BeamTrace
// Beam trace that passes through active teammate Bastion/Fanatic/Hospitaler shields.
// DamageScale is multiplied by ShieldPassDamageScale per shield passed.
// Shields matched by name: no dependency on ShieldVehiclesOmni.
// Traces run from the vehicle the gun is bone-attached to (Gun.Base, replicated to every client).
// Native line checks skip their source actor, so the beam ignores its own vehicle's hull at no extra cost.
// ============================================================================
simulated static function Actor BeamTrace(ONSWeapon Gun, out Vector HitLocation, out Vector HitNormal, Vector End, Vector Start, out float DamageScale)
{
	local Actor Tracer, Other, Skipped[4];
	local int i, n;

	Tracer = Gun.Base;
	if (Tracer == None)
		Tracer = Gun;

	DamageScale = 1.0;
	Other = Tracer.Trace(HitLocation, HitNormal, End, Start, true);
	while ( Other != None && n < ArrayCount(Skipped) && ONSWeapon(Other.Owner) != None
		&& ONSWeapon(Other.Owner).Team == Gun.Team
		&& (Other.IsA('BastionShield') || Other.IsA('FanaticShield') || HospitalerShield(Other) != None) )
	{
		Other.bBlockZeroExtentTraces = false;
		Skipped[n] = Other;
		n++;
		DamageScale *= default.ShieldPassDamageScale;
		Other = Tracer.Trace(HitLocation, HitNormal, End, HitLocation, true);
	}

	for (i = 0; i < n; i++)
		Skipped[i].bBlockZeroExtentTraces = true;

	return Other;
}


// ============================================================================
// TraceFire
// Spawn/refresh the beam only; its hits are traced every tick in Tick() via BeamTrace()
// ============================================================================
function TraceFire(Vector Start, Rotator Dir)
{
	SpawnBeamEffect(Start, Dir, Start, vect(0,0,0), 0);
	NetUpdateTime = Level.TimeSeconds - 1;
}

// ============================================================================
//
// ============================================================================
state ProjectileFireMode
{
	function Fire(Controller C)
	{
		//if (Beam != None)
		//	CeaseFire(C);

		Super.Fire(C);
	}

    function AltFire(Controller C)
    {
		//log(self@"alt-firing",'KDebug');
        FlashMuzzleFlash();

        if (AmbientEffectEmitter != None)
        {
            AmbientEffectEmitter.SetEmitterStatus(true);
        }

        // Play firing noise
        //if (bAmbientFireSound)
        //    AmbientSound = AltFireSoundClass;
        //else
        //   PlayOwnedSound(AltFireSoundClass, SLOT_None, FireSoundVolume/255.0,, FireSoundRadius, FireSoundPitch, False);
				bBeaming=true;
        TraceFire(WeaponFireLocation, WeaponFireRotation);
    }
}


// ============================================================================

defaultproperties
{
     LinkSkin_Gold(0)=Shader'UT2004Weapons.Shaders.PowerPulseShaderYellow'
     LinkSkin_Gold(1)=Shader'UT2004Weapons.Shaders.PowerPulseShaderYellow'
     LinkSkin_Green(0)=Shader'UT2004Weapons.Shaders.PowerPulseShader'
     LinkSkin_Green(1)=Shader'UT2004Weapons.Shaders.PowerPulseShader'
     LinkSkin_Red(0)=Shader'UT2004Weapons.Shaders.PowerPulseShaderRed'
     LinkSkin_Blue(1)=Shader'UT2004Weapons.Shaders.PowerPulseShaderBlue'
     LinkBeamSkin=2
     LinkedFireSound=Sound'WeaponSounds.LinkGun.BLinkedFire'
     BeamEffectClass=Class'HospitalerV3Omni.HospitalerLinkTurretBeamEffect'
     MakeLinkSound=Sound'WeaponSounds.LinkGun.LinkActivated'
     LinkBreakDelay=0.500000
     MomentumTransfer=2000.000000
     AltDamageType=Class'HospitalerV3Omni.DamTypeHospitalerLinkBeam'
     AltDamage=18
     MakeLinkForce="LinkActivated"
     LinkFlexibility=0.550000
     BeamSounds(0)=Sound'WeaponSounds.LinkGun.BLinkGunBeam1'
     BeamSounds(1)=Sound'WeaponSounds.LinkGun.BLinkGunBeam2'
     BeamSounds(2)=Sound'WeaponSounds.LinkGun.BLinkGunBeam3'
     BeamSounds(3)=Sound'WeaponSounds.LinkGun.BLinkGunBeam4'
     VehicleDamageMult=1.0000
     LinkMultiplier = 0.75000
     LinkMultiplierCap = 4.0
     bInitAimError=True
     YawBone="Object02"
     PitchBone="Object02"
     PitchUpLimit=12000
     PitchDownLimit=57000
     // Muzzle bone already sits at the barrel tip and scales with DrawScale; WeaponFireOffset is unscaled
     // world units past it (120 put the beam/plasma origin ~120uu beyond a ~143uu-long turret at 0.2).
     WeaponFireAttachmentBone="Muzzle"
     RotationsPerSecond=0.500000
     FireInterval=0.350000
     AltFireInterval=0.120000
     FireSoundClass=SoundGroup'WeaponSounds.PulseRifle.PulseRifleFire'
     FireSoundVolume=256.000000
     FireForce="Explosion05"
     DamageMin=0
     DamageMax=0
     TraceRange=6600.000000
     ProjectileClass=Class'HospitalerV3Omni.HospitalerLinkPlasma'
     ShakeRotMag=(X=40.000000)
     ShakeRotRate=(X=2000.000000)
     ShakeRotTime=2.000000
     ShakeOffsetMag=(Y=1.000000)
     ShakeOffsetRate=(Y=-2000.000000)
     ShakeOffsetTime=4.000000
     AIInfo(0)=(bLeadTarget=True,WarnTargetPct=0.990000,RefireRate=0.990000)
     AIInfo(1)=(bInstantHit=True,WarnTargetPct=0.990000,RefireRate=0.990000)
     Mesh=SkeletalMesh'ANIM_Hospitaler.LinkBody'
     //Mesh=SkeletalMesh'AS_VehiclesFull_M.LinkBody'
     DrawScale=0.2000
     Skins(0)=Texture'IllyHospitalerSkins.Hospitaler.LinkTurret_skin2'
     Skins(1)=Texture'IllyHospitalerSkins.Hospitaler.LinkTurret_skin1'
     // Beam hum matches the stock link gun: Pawn plays it at 0.8*240/400/2 = 0.24, ONSWeapon at Scaling*240/255/2.
     // Lower AmbientSoundScaling for a quieter hum; SoundRadius matches the Pawn falloff other players hear.
     SoundVolume=240
     AmbientSoundScaling=0.510000
     SoundRadius=160.000000
     TransientSoundRadius=1024.000000
     SelfHealMultiplier = 1.0 // not used in hospitaler
     VehicleHealScore=250.0
     RangeExtPerLink=500
     bDoOffsetTrace=True
     ShieldPassDamageScale=0.500000
}

