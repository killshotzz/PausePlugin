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

/** Global Variables **/
int global_variable_count[4]; 
Handle global_variable_track_timer;

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
    global_variable_count[0] = max_usage;
    global_variable_count[1] = max_usage;
    global_variable_count[2] = 0;
    global_variable_count[3] = 0;

    // Kill the timer if it already exists
    if(global_variable_track_timer != null)
    {
        delete global_variable_track_timer;
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
    if(global_variable_track_timer != null)
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

    if(global_variable_count[team_index] >= max_usage)
    {
        ReplyToCommand(client, "There are no more pauses left (%i)", max_usage);
        return Plugin_Handled;
    }

    global_variable_count[team_index] = global_variable_count[team_index] + 1;
    global_variable_track_timer = CreateTimer(timer_delay, timer_callback);

    PrintToChatAll("%t", "Pause", client, global_variable_count[team_index]);
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

/** Timer Callback **/
public Action timer_callback(Handle timer){
    global_variable_track_timer = null;

    ServerCommand("mp_unpause_match");
    PrintToChatAll("\n30 second pause has ended. Resuming game!\n");
    return Plugin_Continue;
}

/** Valid client state **/
stock bool:IsValidClient(client) {
    if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
        return true;
    return false;
}

/** IsPaused state **/
stock bool:IsPaused() {
    return bool:GameRules_GetProp("m_bMatchWaitingForResume");
}
