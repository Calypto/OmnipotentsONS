// use a fake vehicle to create extra collision cylinder
// fake vehicle allows for checkforheadshot engine code to work
class CSTrickboardCollision extends Vehicle
    cacheexempt;

// if our collision cylinder takes damage, relay it to driver
event TakeDamage(int Damage, Pawn EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    if(Owner != None && Vehicle(Owner) != None && Vehicle(Owner).Driver != None)
        Vehicle(Owner).Driver.TakeDamage(Damage, EventInstigator, HitLocation, Momentum, DamageType);
}

// report the board's team (we are never possessed, so our own Team stays 255/neutral),
// so team-filtered radius damage treats us like the board and its rider
simulated function int GetTeamNum()
{
    local Vehicle V;

    V = Vehicle(Owner);
    if (V != None)
        return V.GetTeamNum();

    return Team;
}

// relay the delayed damage instigator to the driver along with the damage,
// so friendly fire still applies when the shooter is already dead
function SetDelayedDamageInstigatorController(Controller C)
{
    local Vehicle V;

    V = Vehicle(Owner);
    if (V != None && V.Driver != None)
        V.Driver.SetDelayedDamageInstigatorController(C);
}

function Pawn CheckForHeadShot(Vector loc, Vector ray, float AdditionalScale)
{
    if(Owner != None && Vehicle(Owner) != None)
        return Vehicle(Owner).CheckForHeadShot(loc, ray, AdditionalScale);

    return None;
}

// you should not be able to enter this vehicle so do nothing here
function KDriverEnter(Pawn P)
{
}

function bool KDriverLeave(bool bForceLeave)
{
    return false;
}

simulated function ClientKDriverEnter(PlayerController PC)
{
}

simulated function ClientKDriverLeave(PlayerController PC)
{
}

defaultproperties
{
    CollisionRadius=25.000000    //Direct copies from xPawn
    CollisionHeight=44.000000
    Physics=PHYS_None
    // set true to debug, use rend collision + kdraw collision
    bHidden=true
    DrawType=DT_Sprite
    bUseCylinderCollision=true
    bCollideActors=True
    bBlockActors=False
    bCollideWorld=False
    bProjTarget=True
    bDirectional=True
    bHardAttach=True
}