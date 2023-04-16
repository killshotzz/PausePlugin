#pragma semicolon 1
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <colors>

public Plugin:myinfo = {
    name = "CS:GO Pause Commands",
    version = "1.0.5a",
    author = "splewis & ^kS",
    description = "Adds pause/unpause commands for players",
};

public void OnPluginStart() {
    /** Load Translations **/
    LoadTranslations("pauseplugin.phrases");
    
    // Admin Commands
    RegAdminCmd("sm_forcetechpause|sm_forcetechnical|sm_ftech", Command_ForceTechPause, ADMFLAG_GENERIC, "Forces a technical pause");
    RegAdminCmd("sm_forcepause|sm_fp", Command_ForcePause, ADMFLAG_GENERIC, "Forces a pause");
    RegAdminCmd("sm_forceunpause|sm_fup", Command_ForceUnpause, ADMFLAG_GENERIC, "Forces an unpause");
   
    /** Register Commands **/
    new ConfigFile:commands = new ConfigFile("commands.cfg");
    for (new i = 0; i < commands.GetNumKeys(); i++) {
        new command[64], function[64];
        commands.GetKeyValue(i, command, sizeof(command), function, sizeof(function));
        RegConsoleCmd(command, function, ADMFLAG_GENERIC, "");
    }

    RegConsoleCmd("sm_pause|sm_tac", Command_Pause, "Requests a pause");
}

/** Force Tech Pause - Pause the game without allowing players to unpause it manually. */
public Action Command_ForceTechPause(int client, int args) {
    if (IsPaused()) {
        PrintToChat(client, "%t", "GameAlreadyPaused");
        return Plugin_Handled;
    }

    ServerCommand("mp_pause_no_pause");
    PrintToChatAll("%t", "ForceTechPause", client);
    return Plugin_Handled;
}

/** Force Pause **/
public Action Command_ForcePause(int client, int args) {
    if (IsPaused()) {
        PrintToChat(client, "%t", "GameAlreadyPaused");
        return Plugin_Handled;
    }

    ServerCommand("mp_pause_match");
    PrintToChatAll("%t", "ForcePause", client);
    return Plugin_Handled;
}

/** Force Unpause **/
public Action Command_ForceUnpause(int client, int args) {
    if (!IsPaused()) {
        PrintToChat(client, "%t", "GameNotPaused");
        return Plugin_Handled;
    }
    
    ServerCommand("mp_unpause_match");
    PrintToChatAll("%t", "ForceUnpause", client);
    return Plugin_Handled;
}

/** Technical Pause **/
public Action Command_TechPause(int client, int args) {
    if (IsPaused()) {
        return Plugin_Handled;
    }

    ServerCommand("mp_pause_no_pause");
    PrintToChatAll("%t", "TechPause", client);

    return Plugin_Handled;
}

/** Unpause Command **/
public Action Command_Unpause(int client, int args)
{
if (!IsValidClient(client))
{
// Is the client invalid? Terminate process.
return Plugin_Handled;
}

if (!IsPaused())
{
    PrintToChat(client, "%t", "GameNotPaused");
    return Plugin_Handled;
}

// Check if a player from each team has used !unpause
int numPlayers = GetClientCount();
bool unpauseRequired = true;
bool team1Unpaused = false;
bool team2Unpaused = false;

for (int i = 1; i <= numPlayers; i++)
{
    int player = GetClientOfIndex(i);
    if (!IsValidClient(player))
    {
        continue;
    }

    if (IsClientInGame(player) && IsPlayerAlive(player))
    {
        int team = GetClientTeam(player);
        if (team == CS_TEAM_T && HasClientCommand(player, "!unpause"))
        {
            team1Unpaused = true;
        }
        else if (team == CS_TEAM_CT && HasClientCommand(player, "!unpause"))
        {
            team2Unpaused = true;
        }

        if (team1Unpaused && team2Unpaused)
        {
            unpauseRequired = false;
            break;
        }
    }
}

if (unpauseRequired)
{
    // Check if the player who executed the !unpause command is in one of the teams
    int clientTeam = GetClientTeam(client);
    if (clientTeam != CS_TEAM_T && clientTeam != CS_TEAM_CT)
    {
        PrintToChat(client, "%t", "UnpauseRequired");
        return Plugin_Handled;
    }

    // Mark the team as unpaused
    if (clientTeam == CS_TEAM_T)
    {
        team1Unpaused = true;
    }
    else
    {
        team2Unpaused = true;
    }

    PrintToChatAll("%n %t", client, "UnpauseRequest", GetClientName(client));
}
else
{
    ServerCommand("mp_unpause_match");
    PrintToChatAll("%t", "UnpauseSuccess", client);
}

return Plugin_Handled;
}

/** Pause Command **/
public Action Command_Pause(int client, int args)
{
    if (IsPaused() || !IsValidClient(client))
    {
        // Is the game paused or is the client invalid? Terminate process.
        return Plugin_Handled;
    }

    int clientTeam = GetClientTeam(client);
    bool canPause = false;

    if (clientTeam == CS_TEAM_T || clientTeam == CS_TEAM_CT)
    {
        // Check if a player from each team has used !pause
        int numPlayers = GetClientCount();
        bool team1Paused = false;
        bool team2Paused = false;

        for (int i = 1; i <= numPlayers; i++)
        {
            int player = GetClientOfIndex(i);
            if (!IsValidClient(player))
            {
                continue;
            }

            if (IsClientInGame(player) && IsPlayerAlive(player))
            {
                int team = GetClientTeam(player);
                if (team == CS_TEAM_T && HasClientCommand(player, "!pause"))
                {
                    team1Paused = true;
                }
                else if (team == CS_TEAM_CT && HasClientCommand(player, "!pause"))
                {
                    team2Paused = true;
                }

                if (team1Paused && team2Paused)
                {
                    canPause = true;
                    break;
                }
            }
        }
    }
    else
    {
        // The client is a spectator, so they can always pause
        canPause = true;
    }

    if (canPause)
    {
        ServerCommand("mp_pause_match");
        PrintToChatAll("%t", "PauseRequest", client);

        // Add 30-second timer
        Timer.CreateTimer("unpause_timer", 30.0f, () =>
        {
            // Check if the game is still paused
            if (IsPaused())
            {
                ServerCommand("mp_unpause_match");
                PrintToChatAll("%t", "UnpauseAutomatic");
            }
        });
    }
    else
    {
        PrintToChat(client, "%t", "PauseRequired");
    }

    return Plugin_Handled;
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