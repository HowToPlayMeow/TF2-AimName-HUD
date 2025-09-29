#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2hudmsg>

#define PLUGIN_VERSION "1.0"
#define TF2_PLAYERCOND_DISGUISING (1<<2)
#define TF2_PLAYERCOND_DISGUISED  (1<<3)
#define TF2_PLAYERCOND_SPYCLOAK   (1<<4)

int g_iLastTarget[MAXPLAYERS+1];
int g_iLastCond[MAXPLAYERS+1];
float g_fLastHudTime[MAXPLAYERS+1];
int g_iFilteredEntity = -1;

ConVar g_hCvarEnable;
ConVar g_hCvarIcon;
ConVar g_hCvarDistance;
ConVar g_hCvarInterval;
ConVar g_hCvarBlockSpy;
ConVar g_hCvarHudHP;

bool  g_bHudEnable = true;
char  g_sHudIcon[64];
float g_fDistance;
float g_fInterval;
bool  g_bBlockSpy;
int   g_iHudHP;

Handle g_hCheckTimer = INVALID_HANDLE;

public Plugin myinfo =
{
    name = "TF2HUD AimName",
    author = "HowToPlayMeow",
    description = "Meow Meow",
    version = PLUGIN_VERSION,
    url = "https://github.com/HowToPlayMeow/TF2-AimName-HUD"
};

public void OnPluginStart()
{
    CreateConVar("sm_tfhud_version", PLUGIN_VERSION, "Version of TF2HUD AimName", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    g_hCvarEnable   = CreateConVar("sm_tfhud_enable", "1", "TF2HUD AimName (1 = Enable, 0 = Disable)");
    g_hCvarIcon     = CreateConVar("sm_tfhud_icon", "leaderboard_streak", "HUD Icon");
    g_hCvarDistance = CreateConVar("sm_tfhud_distance", "100.0", "Distance in Meters");
    g_hCvarInterval = CreateConVar("sm_tfhud_interval", "0.2", "Check Interval");
    g_hCvarBlockSpy = CreateConVar("sm_tfhud_blockspy", "1", "Block HUD for Spy Class (1 = Enable, 0 = Disable)");
    g_hCvarHudHP    = CreateConVar("sm_tfhud_hp", "0", "See HP (0 = OFF, 1 = All Teams, 2 = RED Teams, 3 = BLU Teams)");

    HookEvent("player_spawn", Spawn_SetHP, EventHookMode_Post);

    g_hCvarEnable.AddChangeHook(OnCvarChanged);  
    g_hCvarIcon.AddChangeHook(OnCvarChanged);
    g_hCvarDistance.AddChangeHook(OnCvarChanged);
    g_hCvarInterval.AddChangeHook(OnCvarChanged);
    g_hCvarBlockSpy.AddChangeHook(OnCvarChanged);
    g_hCvarHudHP.AddChangeHook(OnCvarChanged);

    g_bHudEnable = g_hCvarEnable.BoolValue;      
    GetConVarString(g_hCvarIcon, g_sHudIcon, sizeof(g_sHudIcon));
    g_fDistance = g_hCvarDistance.FloatValue;
    g_fInterval = g_hCvarInterval.FloatValue;
    g_bBlockSpy = g_hCvarBlockSpy.BoolValue;
    g_iHudHP    = g_hCvarHudHP.IntValue;

    g_hCheckTimer = CreateTimer(g_fInterval, TF2_AimName, _, TIMER_REPEAT);

    for (int i = 1; i <= MaxClients; i++)
    {
        g_iLastTarget[i]  = -1;
        g_iLastCond[i]    = 0;
        g_fLastHudTime[i] = 0.0;
    }
}

public void OnClientPutInServer(int client)
{
    g_iLastTarget[client]  = -1;
    g_iLastCond[client]    = 0;
    g_fLastHudTime[client] = 0.0;
}

public void OnClientDisconnect(int client)
{
    g_iLastTarget[client]  = -1;
    g_iLastCond[client]    = 0;
    g_fLastHudTime[client] = 0.0;
}

bool IsValidClient(int client, bool allowBots = true)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    if (!allowBots && IsFakeClient(client)) return false;
    return true;
}

stock int TF2_GetPlayerCond(int client)
{
    return GetEntProp(client, Prop_Send, "m_nPlayerCond");
}

stock float UnitToMeter(float distance)
{
    return distance / 50.0;
}

stock float GetVectorDistanceMeter(const float vec1[3], const float vec2[3], bool squared = false)
{
    return UnitToMeter(GetVectorDistance(vec1, vec2, squared));
}

public bool TraceFilter(int ent, int contentMask)
{
    return (ent == g_iFilteredEntity) ? false : true;
}

stock bool CanSeeTarget(int origin, float pos[3], float targetPos[3], float range)
{
    float fDistance = GetVectorDistanceMeter(pos, targetPos);
    if (fDistance >= range) return false;

    g_iFilteredEntity = origin;
    Handle hTrace = TR_TraceRayFilterEx(pos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);
    float hitPos[3];
    TR_GetEndPosition(hitPos, hTrace);
    CloseHandle(hTrace);

    if (GetVectorDistanceMeter(hitPos, targetPos) <= 1.0)
        return true;

    return false;
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == g_hCvarEnable)                 
        g_bHudEnable = g_hCvarEnable.BoolValue;  

    else if (convar == g_hCvarIcon)
        strcopy(g_sHudIcon, sizeof(g_sHudIcon), newValue);

    else if (convar == g_hCvarDistance)
        g_fDistance = g_hCvarDistance.FloatValue;

    else if (convar == g_hCvarInterval)
    {
        float newInterval = g_hCvarInterval.FloatValue;
        if (newInterval > 0.01)
        {
            g_fInterval = newInterval;

            if (g_hCheckTimer != INVALID_HANDLE)
            {
                KillTimer(g_hCheckTimer);
                g_hCheckTimer = INVALID_HANDLE;
            }
            g_hCheckTimer = CreateTimer(g_fInterval, TF2_AimName, _, TIMER_REPEAT);
        }
    }

    else if (convar == g_hCvarBlockSpy)
        g_bBlockSpy = g_hCvarBlockSpy.BoolValue;

    else if (convar == g_hCvarHudHP)
    {
        g_iHudHP = g_hCvarHudHP.IntValue;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                bool showHP = (g_iHudHP == 1) || (g_iHudHP == 2 && GetClientTeam(i) == view_as<int>(TFTeam_Red)) || (g_iHudHP == 3 && GetClientTeam(i) == view_as<int>(TFTeam_Blue));
                SetEntProp(i, Prop_Send, "m_bIsMiniBoss", showHP ? 1 : 0);
            }
        }
    }
}

public Action TF2_AimName(Handle timer)
{
    if (!g_bHudEnable) return Plugin_Continue;

    float now = GetEngineTime();

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsValidClient(client, true) || !IsPlayerAlive(client))
            continue;

        if (!IsFakeClient(client) && g_bBlockSpy && TF2_GetPlayerClass(client) == TFClass_Spy)
            continue;

        int target = GetClientAimTarget(client, false);
        if (!IsValidClient(target, true) || !IsPlayerAlive(target))
        {
            g_iLastTarget[client] = -1;
            g_iLastCond[client] = 0;
            continue;
        }

        if (GetClientTeam(client) == GetClientTeam(target))
            continue;

        float clientPos[3], targetPos[3];
        GetClientEyePosition(client, clientPos);
        GetClientEyePosition(target, targetPos);

        if (!CanSeeTarget(client, clientPos, targetPos, g_fDistance))
            continue;

        int cond = TF2_GetPlayerCond(target);
        if (cond & (TF2_PLAYERCOND_DISGUISING | TF2_PLAYERCOND_DISGUISED | TF2_PLAYERCOND_SPYCLOAK))
            continue;

        // Prevent Spam
        if (g_iLastTarget[client] == target && g_iLastCond[client] == cond)
        {
            if (now - g_fLastHudTime[client] < 2.0)
                continue;
        }

        char name[MAX_NAME_LENGTH];
        GetClientName(target, name, sizeof(name));

        TF2_HudNotificationCustom(client, g_sHudIcon, GetClientTeam(target), true, "%s", name);

        g_iLastTarget[client]  = target;
        g_iLastCond[client]    = cond;
        g_fLastHudTime[client] = now;
    }

    return Plugin_Continue;
}

public void Spawn_SetHP(Event event, const char[] name, bool dontBroadcast)
{
    if (g_iHudHP == 0) return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client <= 0 || !IsClientInGame(client)) return;

    CreateTimer(1.0, SetHP, client);
}

public Action SetHP(Handle timer, any client)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
        bool showHP = (g_iHudHP == 1) || (g_iHudHP == 2 && GetClientTeam(client) == view_as<int>(TFTeam_Red)) || (g_iHudHP == 3 && GetClientTeam(client) == view_as<int>(TFTeam_Blue));

        SetEntProp(client, Prop_Send, "m_bIsMiniBoss", showHP ? 1 : 0);
    }
    return Plugin_Stop;
}
