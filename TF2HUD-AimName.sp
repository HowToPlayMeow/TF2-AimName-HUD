#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define PLUGIN_VERSION "2.0"

public Plugin myinfo =
{
    name = "TF2HUD AimName",
    author = "HowToPlayMeow",
    description = "Meow Meow",
    version = PLUGIN_VERSION,
    url = "https://github.com/HowToPlayMeow/TF2-AimName-HUD"
};

ConVar cvAimNameEnable;
ConVar cvAimNameIcon;
ConVar cvAimNameDistance;
ConVar cvAimNameInterval;
ConVar cvAimNameBlockSpy;
ConVar cvAimNameSetHP;

Handle  g_hCheckTimer = INVALID_HANDLE;
bool    g_bHudEnable;
char    g_sHudIcon[64];
float   g_fDistance;
float   g_fInterval;
bool    g_bBlockSpy;
int     g_iHudHP;
int     g_iFilteredEntity = -1;

// Credit: arthurdead
bool    cl_hud_minmode[MAXPLAYERS+1];
float   tf_hud_notification_duration[MAXPLAYERS+1];

public void OnPluginStart()
{
    CreateConVar("sm_tfhud_version", PLUGIN_VERSION, "Version of TF2HUD AimName", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    cvAimNameEnable   = CreateConVar("sm_tfhud_enable", "1", "TF2HUD AimName (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    cvAimNameIcon     = CreateConVar("sm_tfhud_icon", "leaderboard_streak", "HUD Icon", FCVAR_NONE);
    cvAimNameDistance = CreateConVar("sm_tfhud_distance", "100.0", "Distance in Meters", FCVAR_NONE, true, 1.0);
    cvAimNameInterval = CreateConVar("sm_tfhud_interval", "0.2", "Check Interval", FCVAR_NONE, true, 0.1);
    cvAimNameBlockSpy = CreateConVar("sm_tfhud_blockspy", "1", "Block HUD for Spy Class (1 = Enable, 0 = Disable)", FCVAR_NONE, true, 0.0, true, 1.0);
    cvAimNameSetHP    = CreateConVar("sm_tfhud_hp", "0", "See HP (0 = OFF, 1 = All Teams, 2 = RED Teams, 3 = BLU Teams)", FCVAR_NONE, true, 0.0, true, 3.0);
    
    cvAimNameEnable.AddChangeHook(OnCvarChanged);  
    cvAimNameIcon.AddChangeHook(OnCvarChanged);
    cvAimNameDistance.AddChangeHook(OnCvarChanged);
    cvAimNameInterval.AddChangeHook(OnCvarChanged);
    cvAimNameBlockSpy.AddChangeHook(OnCvarChanged);
    cvAimNameSetHP.AddChangeHook(OnCvarChanged);
    
    UpdateSettings();
    HookEvent("player_spawn", Spawn_SetPlayer, EventHookMode_Post);

    g_hCheckTimer = CreateTimer(g_fInterval, TF2_AimName, _, TIMER_REPEAT);

    for (int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, BackStab);

    if(!IsFakeClient(client))
    {
        QueryClientConVar(client, "cl_hud_minmode", Minmode_Query);
        QueryClientConVar(client, "tf_hud_notification_duration", Notification_Query);
    }
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, BackStab);

    cl_hud_minmode[client] = false;
	tf_hud_notification_duration[client] = 3.0;
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (convar == cvAimNameEnable)             
        g_bHudEnable = cvAimNameEnable.BoolValue;

    else if (convar == cvAimNameIcon)
        strcopy(g_sHudIcon, sizeof(g_sHudIcon), newValue);

    else if (convar == cvAimNameDistance)
        g_fDistance = cvAimNameDistance.FloatValue;

    else if (convar == cvAimNameInterval)
    {
        if (g_hCheckTimer != INVALID_HANDLE)
        {
            KillTimer(g_hCheckTimer);
            g_hCheckTimer = INVALID_HANDLE;
        }

        float newInterval = cvAimNameInterval.FloatValue;
        g_hCheckTimer = CreateTimer(newInterval, TF2_AimName, _, TIMER_REPEAT);
    }

    else if (convar == cvAimNameBlockSpy)
        g_bBlockSpy = cvAimNameBlockSpy.BoolValue;

    else if (convar == cvAimNameSetHP)
    {
        g_iHudHP = cvAimNameSetHP.IntValue;

        for (int i = 1; i <= MaxClients; i++)
        {
            if (!IsValidClient(i) || !IsPlayerAlive(i))
                continue;

            if (g_iHudHP == 0)
            {
                SetEntProp(i, Prop_Send, "m_bIsMiniBoss", 0);
            }
            else
            {
                bool showHP = (g_iHudHP == 1) 
                || (g_iHudHP == 2 && TF2_GetClientTeam(i) == TFTeam_Red) 
                || (g_iHudHP == 3 && TF2_GetClientTeam(i) == TFTeam_Blue);

                SetEntProp(i, Prop_Send, "m_bIsMiniBoss", showHP ? 1 : 0);
            }
        }
    }
}

void UpdateSettings()
{
    g_bHudEnable = cvAimNameEnable.BoolValue;
    GetConVarString(cvAimNameIcon, g_sHudIcon, sizeof(g_sHudIcon));
    g_fDistance  = cvAimNameDistance.FloatValue;
    g_fInterval  = cvAimNameInterval.FloatValue;
    g_bBlockSpy  = cvAimNameBlockSpy.BoolValue;
    g_iHudHP     = cvAimNameSetHP.IntValue;
}

bool IsValidClient(int client)
{
    if (client <= 0 || client > MaxClients)
        return false;

    if (!IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
        return false;

    return true;
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
    if (fDistance >= range) 
        return false;

    g_iFilteredEntity = origin;
    Handle hTrace = TR_TraceRayFilterEx(pos, targetPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceFilter);

    bool canSee = false;
    if (!TR_DidHit(hTrace))
    {
        canSee = true;
    }
    else
    {
        float hitPos[3];
        TR_GetEndPosition(hitPos, hTrace);

        if (GetVectorDistanceMeter(hitPos, targetPos) <= 1.0)
            canSee = true;
    }

    delete hTrace;
    g_iFilteredEntity = -1;
    
    return canSee;
}

public Action TF2_AimName(Handle timer)
{
    if (!g_bHudEnable) 
        return Plugin_Continue;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsValidClient(client) || IsFakeClient(client) || !IsPlayerAlive(client))
            continue;

        if (g_bBlockSpy && TF2_GetPlayerClass(client) == TFClass_Spy)
            continue;

        int target = GetClientAimTarget(client, false);
        if (!IsValidClient(target) || !IsPlayerAlive(target))
            continue;

        if (TF2_GetClientTeam(client) == TF2_GetClientTeam(target))
            continue;

        float clientPos[3], targetPos[3];
        GetClientEyePosition(client, clientPos);
        GetClientEyePosition(target, targetPos);

        if (!CanSeeTarget(client, clientPos, targetPos, g_fDistance))
            continue;

        if (TF2_IsPlayerInCondition(target, TFCond_Cloaked)
        || TF2_IsPlayerInCondition(target, TFCond_Disguised)
        || TF2_IsPlayerInCondition(target, TFCond_Disguising)
        || TF2_IsPlayerInCondition(target, TFCond_DisguisedAsDispenser))
            continue;

        char name[MAX_NAME_LENGTH];
        GetClientName(target, name, sizeof(name));

        if (cl_hud_minmode[client] || tf_hud_notification_duration[client] == 0.0)
        {
            PrintHintText(client, "%s", name);
            StopSound(client, SNDCHAN_STATIC, "UI/hint.wav");
        }
        else
        {
            BfWrite AimNameHUD = view_as<BfWrite>(StartMessageOne("HudNotifyCustom", client));
            AimNameHUD.WriteString(name);
            AimNameHUD.WriteString(g_sHudIcon);
            AimNameHUD.WriteByte(TF2_GetClientTeam(target));
            EndMessage();
        }
    }

    return Plugin_Continue;
}

public void Spawn_SetPlayer(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bHudEnable || g_iHudHP == 0)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client) || !IsPlayerAlive(client))
        return;

    CreateTimer(2.0, SetPlayer, client);
}

public Action SetPlayer(Handle timer, any client)
{
    if (!g_bHudEnable)
        return Plugin_Stop;

    if (IsValidClient(client) && IsPlayerAlive(client))
    {
        if (g_iHudHP == 0)
        {
            SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 0);
        }
        else
        {
            bool showHP = (g_iHudHP == 1)
            || (g_iHudHP == 2 && TF2_GetClientTeam(client) == TFTeam_Red)
            || (g_iHudHP == 3 && TF2_GetClientTeam(client) == TFTeam_Blue);

            SetEntProp(client, Prop_Send, "m_bIsMiniBoss", showHP ? 1 : 0);
        }
    }   

    return Plugin_Stop;
}

public Action BackStab(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if (!g_bHudEnable || g_iHudHP == 0)
        return Plugin_Continue;

    if (!IsValidClient(victim) || !IsValidClient(attacker))
        return Plugin_Continue;

    if (damagecustom == TF_CUSTOM_BACKSTAB)
    {
        damage = 400.0; // + critical = 1200
        return Plugin_Changed;
    }

    return Plugin_Continue;
}

static void Notification_Query(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any data)
{
	if(result == ConVarQuery_Okay)
	{
		float value = StringToFloat(cvarValue);
		tf_hud_notification_duration[client] = value;
	}
}

static void Minmode_Query(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, any data)
{
	if(result == ConVarQuery_Okay)
	{
		int value = StringToInt(cvarValue);
		cl_hud_minmode[client] = view_as<bool>(value);
	}
}