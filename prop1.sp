/**
 * csgo_props.sp
 *
 * Description: A prop spawner that can be used in CS:GO
 *
 * Version: 1.0
 * Author: Sn1ce
 *
 * Dependencies: SDK Hooks
 **/

#include <sourcemod>

#include <sdkhooks>

// Configuration
const Float:PROP_DEPLOY_HEIGHT = 25.0; // The height above the player to spawn a prop
const Float:PROP_DEPLOY_FORWARD = 50.0; // The distance in front of the player to spawn a prop

enum PropType
{
    PT_INVALID = -1,
    PT_GENERIC = 0,
    PT_BREAKABLE,
    PT_PHYSICS
};

const PropType:PROP_TYPES[] =
{
    PT_GENERIC,
    PT_BREAKABLE,
    PT_PHYSICS
};

const char *PROP_TYPE_NAMES[] =
{
    "prop_static",
    "prop_physics_breakable",
    "prop_physics"
};

// Stores the player's chosen prop type
dictionary g_PlayerPropType;

// Stores the player's chosen prop model
dictionary g_PlayerPropModel;

// Stores the player's chosen prop skin
dictionary g_PlayerPropSkin;

// Stores the player's chosen prop color
dictionary g_PlayerPropColor;

// Stores the player's chosen prop bodygroup
dictionary g_PlayerPropBodygroup;

// Stores the player's chosen prop material
dictionary g_PlayerPropMaterial;

// SDK Hooks
private SDKHook g_PlayerSayHook;

// Helper function to spawn a prop of the given type
void SpawnProp(CBasePlayer@ pPlayer, PropType propType, const char[] propModel, int propSkin = -1, int propBodygroup = -1, const char[] propMaterial = "")
{
    // Check if the given prop type is valid
    if (propType < 0 || propType >= PROP_TYPES.length())
    {
        LogError("Invalid prop type %d", propType);
        return;
    }

    // Check if the given prop model is valid
    if (propModel.IsEmpty())
    {
        LogError("Invalid prop model %s", propModel);
        return;
    }

    // Get the player's position and angles
    Vector vecOrigin = pPlayer.EyePosition() + (pPlayer.EyeDirection() * PROP_DEPLOY_FORWARD);
    Vector vecAngles = pPlayer.EyeAngles();

    // Create the prop
    CBaseEntity@ pProp = g_EntityFuncs.CreateEntityByName(PROP_TYPE_NAMES[propType]);
    if (pProp is null)
    {
        LogError("Failed to create prop entity");
        return;
    }

    // Set the prop's position and angles
    pProp.pev.origin = vecOrigin;
    pProp.pev.angles = vecAngles;

    // Set the prop's model
    g_EntityFuncs.SetModel(pProp, propModel);

    // Set the prop's skin
    if (propSkin >= 0)
    {
        pProp.pev.skin = propSkin;
    }

    // Set the prop's bodygroup
    if (propBodygroup >= 0)
    {
        g_EntityFuncs.SetBodygroup(pProp, propBodygroup);
    }

    // Set the prop's material
    if (!propMaterial.IsEmpty())
    {
        g_EntityFuncs.SetKeyValue(pProp.edict(), "material", propMaterial);
    }

    // Spawn the prop
    g_EntityFuncs.DispatchSpawn(pProp.edict());

    // Set the prop's owner
    pProp.SetOwner(pPlayer);
    // Set the prop's owner
    // Give the prop a velocity
    Vector vecVelocity = Vector(RandomFloat(-100, 100), RandomFloat(-100, 100), RandomFloat(0, 100));
    pProp.SetAbsVelocity(vecVelocity);

    // Give the prop a random angular velocity
    AngularImpulse angVelocity = AngularImpulse(RandomFloat(-100, 100), RandomFloat(-100, 100), RandomFloat(-100, 100));
    pProp.SetLocalAngularVelocity(angVelocity);

    // Spawn the prop
    g_EntityFuncs.SetOrigin(pProp, vecOrigin);
    g_EntityFuncs.DispatchSpawn(pProp.edict());
    g_EntityFuncs.SetModel(pProp, strModel);
    g_EntityFuncs.SetSize(pProp.pev, vecMin, vecMax);

    // Set the prop's health
    pProp.pev.health = fHealth;

    // Set the prop's material
    pProp.pev.rendermode = kRenderNormal;
    pProp.pev.renderamt = 255;
    pProp.pev.renderfx = kRenderFxNone;
    pProp.pev.skin = iSkin;

    // Set the prop's collision
    pProp.pev.solid = SOLID_VPHYSICS;
    pProp.pev.movetype = MOVETYPE_VPHYSICS;
    pProp.pev.takedamage = DAMAGE_YES;
    pProp.pev.flags |= FL_WORLDBRUSH;
    pProp.pev.iuser4 = PROP_ACTIVE;

    // Set the prop's physics properties
    pProp.pev.gravity = flGravity;
    pProp.pev.friction = flFriction;
    pProp.pev.avelocity = angVelocity;

    // Set the prop's respawn timer
    g_Scheduler.SetTimeout("RespawnProp", fRespawnTime, PropIndex(pProp));

    return pProp;

    // Set the prop's owner
    pProp.SetOwner(pPlayer);
    
    // Set the prop's respawn timer
    g_Scheduler.SetTimeout("RespawnProp", fRespawnTime, PropIndex(pProp));

    return pProp;
}

void RespawnProp(int iIndex)
{
    PropData@ pData = g_Props[iIndex];
    if (pData !is null)
    {
        pData.bRespawning = false;
        SpawnProp(pData.sModel, pData.vOrigin, pData.qAngles, pData.iType);
    }
}

int PropIndex(CBaseEntity@ pProp)
{
    for (uint i = 0; i < g_Props.length(); i++)
    {
        PropData@ pData = g_Props[i];
        if (pData !is null && pData.pEntity is pProp)
        {
            return i;
        }
    }
    return -1;
}
