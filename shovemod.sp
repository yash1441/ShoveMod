#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Simon"
#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

EngineVersion g_Game;

Handle g_shove_enable;
Handle g_shove_force;
Handle g_shove_cooldown;

bool IsCooldown[MAXPLAYERS + 1] =  { false, ... };
float CooldownTime[MAXPLAYERS + 1] =  { 0.0, ... };
Handle CooldownTimer[MAXPLAYERS + 1];

bool shove_enable;
float shove_force;
float shove_cooldown;

public Plugin myinfo = 
{
	name = "ShoveMod",
	author = PLUGIN_AUTHOR,
	description = "Allow players to Shove each other.",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}

	CreateConVar("shove_version", PLUGIN_VERSION, "ShoveMod Version", FCVAR_DONTRECORD | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_SPONLY);
	g_shove_enable = CreateConVar("shove_enable", "1", "Shove enable? 0 = disable, 1 = enable", 0, true, 0.0, true, 1.0);
  	g_shove_force = CreateConVar("shove_force", "1000", "Shove force.", 0, true, 0.0);
  	g_shove_cooldown = CreateConVar("shove_cooldown", "5", "Shove cooldown.", 0, true, 1.0, true, 10.0);
  	
  	shove_enable = GetConVarBool(g_shove_enable);
  	shove_force = GetConVarFloat(g_shove_force);
  	shove_cooldown = GetConVarFloat(g_shove_cooldown);
  	
  	AddCommandListener(Command_LookAtWeapon, "+lookatweapon");
  	
  	HookConVarChange(g_shove_enable, OnConVarChanged);
	HookConVarChange(g_shove_force, OnConVarChanged);
	HookConVarChange(g_shove_cooldown, OnConVarChanged);
  	
  	AutoExecConfig(true, "shovemod");
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_shove_enable)
	{
		shove_enable = GetConVarBool(g_shove_enable);
	}
	
	else if (convar == g_shove_force)
	{
		shove_force = GetConVarFloat(g_shove_force);
	}
	
	else if (convar == g_shove_cooldown)
	{
		shove_cooldown = GetConVarFloat(g_shove_cooldown);
	}
}

public Action Command_LookAtWeapon(int client, const char[] command, int argc)
{
	if(!IsPlayerAlive(client) || !shove_enable)
	{
		return Plugin_Continue;
	}
	
	if(IsCooldown[client])
	{
		PrintToChat(client, "[Shove] Please wait %i seconds before using shove again.", RoundFloat(CooldownTime[client]));
		return Plugin_Continue;
	}
	
	CooldownTime[client] = shove_cooldown;
	
	int victim = GetVictim(client);
	
	float vAngles[3];
	float vOrigin[3];
	float pos[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	GetClientAbsOrigin(victim, pos);
	float velocity[3];
	SubtractVectors(pos, vOrigin, velocity);
	NormalizeVector(velocity, velocity);
	ScaleVector(velocity, shove_force);
	pos[2] += 5.0;
	SetEntityGravity(victim, 0.0);
	TeleportEntity(victim, pos, NULL_VECTOR, velocity);
	SetEntityGravity(victim, 1.0);
	
	IsCooldown[client] = true;
	CooldownTimer[client] = CreateTimer(1.0, ResetCooldown, client, TIMER_REPEAT);
	
	return Plugin_Handled;
}

public Action ResetCooldown(Handle timer, int client)
{
	--CooldownTime[client];
	if(CooldownTime[client] == 0)
	{
		IsCooldown[client] = false;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public int GetVictim(int client)
{
	int victim =0;
	
	float vAngles[3];
	float vOrigin[3];
	float pos[3];
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		victim = TR_GetEntityIndex(trace);
		if(victim > 0 && victim <= MaxClients)
		{
			PrintToChat(client, "%N is shoving %N.", client, victim);
		}
		else
		{
			PrintToChat(client, "Shove failed.");
		}
	}
	CloseHandle(trace);	
	return victim;
}
public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == 0 || entity > MaxClients || entity == data) 
	{
		return false; 
	}
	return true;
}