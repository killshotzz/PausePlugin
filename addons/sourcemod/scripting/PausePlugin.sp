#pragma semicolon 1
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <colors>

/** Macros **/
#define max_usage 4
#define timer_delay 30.0

/** Bools **/
new bool:g_ctUnpaused = false;
new bool:g_tUnpaused = false;
new bool:g_bTimerEnd = false;

/** Global Variables **/
int g_vcount[4]; 
Handle g_vtrack_timer;

public Plugin:myinfo = {
    name = "CS:GO Pause Commands",
    author = "splewis & ^kS",
    description = "Adds simple pause/unpause commands for players",
    version = "1.0.3d",
    url = "https://github.com/ksgoescoding/PausePlugin"
};

public void OnPluginStart() {
    /** Load Translations **/
    LoadTranslations("pauseplugin.phrases");

    /** Admin Commands **/
    RegAdminCmd("sm_forcetechpause", Command_ForceTechPause, ADMFLAG_GENERIC, "Forces a technical pause");
    RegAdminCmd("sm_forcetechnical", Command_ForceTechPause, ADMFLAG_GENERIC, "Forces a technical pause");
    RegAdminCmd("sm_ftech", Command_ForceTechPause, ADMFLAG_GENERIC, "Forces a technical pause");
    RegAdminCmd("sm_ftec", Command_ForceTechPause, ADMFLAG_GENERIC, "Forces a technical pause");
    RegAdminCmd("sm_ft", Command_ForceTechPause, ADMFLAG_GENERIC, "Forces a technical pause");
    RegAdminCmd("sm_forcepause", Command_ForcePause, ADMFLAG_GENERIC, "Forces a pause");
    RegAdminCmd("sm_fp", Command_ForcePause, ADMFLAG_GENERIC, "Forces a pause");
    RegAdminCmd("sm_forceunpause", Command_ForceUnpause, ADMFLAG_GENERIC, "Forces an unpause");
    RegAdminCmd("sm_fup", Command_ForceUnpause, ADMFLAG_GENERIC, "Forces an unpause");
   
    /** Pause Commands **/
    RegConsoleCmd("sm_pause", Command_Pause, "Requests a pause");
    RegConsoleCmd("sm_p", Command_Pause, "Requests a pause");
    RegConsoleCmd("sm_tac", Command_Pause, "Requests a pause");
    RegConsoleCmd("sm_tactical", Command_Pause, "Requests a pause");

    /** Technical Pause Commands **/
    RegConsoleCmd("sm_tech", Command_TechPause, "Calls for a tech pause");
    RegConsoleCmd("sm_t", Command_TechPause, "Requests a pause");

    /** Unpause Commands **/
    RegConsoleCmd("sm_unpause", Command_Unpause, "Requests an unpause");
    RegConsoleCmd("sm_up", Command_Unpause, "Requests an unpause");
}

public OnMapStart() {
    g_ctUnpaused = false;
    g_tUnpaused = false;

    // Team 0 = None || Team 1 = Spectators || Team 2 = T's || Team 3 = CT's
    g_vcount[0] = max_usage;
    g_vcount[1] = max_usage;
    g_vcount[2] = 0;
    g_vcount[3] = 0;

    // Kill the timer if it already exists
    if(g_vtrack_timer != null)
    {
        delete g_vtrack_timer;
    }
}

/** Force Tech Pause **/
public Action Command_ForceTechPause(int client, int args){
    if (IsPaused())
        return Plugin_Handled;

    ServerCommand("mp_pause_match");
    PrintToChatAll("%t", "ForceTechPauseMessage", client);
    return Plugin_Handled;
}

/** Force Pause **/
public Action Command_ForcePause(int client, int args) {
    if (IsPaused())
        return Plugin_Handled;

    ServerCommand("mp_pause_match");
    PrintToChatAll("%t", "ForcePause", client);
    return Plugin_Handled;
}

/** Force Unpause **/
public Action Command_ForceUnpause(int client, int args) {
    if (!IsPaused())
        return Plugin_Handled;
    
    ServerCommand("mp_unpause_match");
    PrintToChatAll("%t", "ForceUnpause", client);
    return Plugin_Handled;
}

/** Technical Pause **/
public Action Command_TechPause(int client, int args){
    if (IsPaused())
        return Plugin_Handled;

    ServerCommand("mp_pause_match");
    PrintToChatAll("%t", "TechPauseMessage", client, client);
    return Plugin_Handled;
}

/** Pause **/
public Action Command_Pause(int client, int args) {
    if(g_vtrack_timer != null)
    {
        // Timer is still running. Kill the timer.
        return Plugin_Handled;
    }
    
    if (IsPaused() || !IsValidClient(client))
    {
        // Is the game paused or is the client invalid? Terminate process.
        return Plugin_Handled;
    }

    g_ctUnpaused = false;
    g_tUnpaused = false;

    int team_index = GetClientTeam(client);

    if(g_vcount[team_index] >= max_usage)
    {
        ReplyToCommand(client, "There are no more pauses left (%i)", max_usage);
        return Plugin_Handled;
    }

    g_vcount[team_index] = g_vcount[team_index] + 1;
    g_vtrack_timer = CreateTimer(timer_delay, timer_callback);

    PrintToChatAll("%t", "Pause", client, g_vcount[team_index]);
    ServerCommand("mp_pause_match");

    return Plugin_Handled;
}

/** Unpause **/
public Action Command_Unpause(int client, int args) {
    if (!IsPaused() || !IsValidClient(client))
        return Plugin_Handled;

    new team = GetClientTeam(client);

    if (team == CS_TEAM_T)
        g_tUnpaused = true;
    else if (team == CS_TEAM_CT)
        g_ctUnpaused = true;

    if (g_tUnpaused && g_ctUnpaused)  {
        ServerCommand("mp_unpause_match");
    } else if (g_tUnpaused && !g_ctUnpaused) {
        CPrintToChatAll("%t", "tUnpause", client);
    } else if (!g_tUnpaused && g_ctUnpaused) {
        CPrintToChatAll("%t", "ctUnpause", client);
    }

    return Plugin_Handled;
}

/**
public Action timer_callback(Handle timer){
    if(global_variable_track_timer = null);

    ServerCommand("mp_unpause_match");
    PrintToChatAll("%t", "Auto Unpause");
    return Plugin_Continue;
}
**/

/** New Callback Timer **/
public Action timer_callback(Handle timer)
{
	if (GetConVarBool(g_bTimerEnd))
	{
		Handle hTmp;
		hTmp = FindConVar("mp_timelimit");
		int iTimeLimit;
		iTimeLimit = GetConVarInt(hTmp);
		if (hTmp != null)
			CloseHandle(hTmp);

		if (iTimeLimit > 0)
		{
			int timeleft;
			GetPauseTimeLeft(timeleft);
			switch (timeleft)
			{
				case 30:PrintToChatAll("%t", "Timeleft", timeleft);
				case 20:PrintToChatAll("%t", "Timeleft", timeleft);
				case 10:PrintToChatAll("%t", "Timeleft", timeleft);
				case 3:PrintToChatAll("%t", "Timeleft", timeleft);
				case 2:PrintToChatAll("%t", "Timeleft", timeleft);
				case 1:PrintToChatAll("%t", "Timeleft", timeleft);	
				case -1:
				{
					if (!g_bTimerEnd)
					{
						g_bTimerEnd = true;
						ServerCommand("mp_unpause_match");
					}
				}
			}
		}

		if (timeleft == 30 || timeleft == 20 || timeleft == 10 || timeleft == 3 || timeleft == 2 || timeleft == 1)
		{
				CPrintToChatAll("%t", "Auto Unpause");
		}
	}
}
		    

/** Valid client state **/
stock bool:IsValidClient(client) 
{
    if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
        return true;
    return false;
}

/** IsPaused state **/
stock bool:IsPaused() 
{
    return bool:GameRules_GetProp("m_bMatchWaitingForResume");
}