#pragma semicolon 1
#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <colors>

public Plugin:myinfo = {
    name = "CS:GO Pause Commands",
    author = "splewis & ^kS",
    description = "Adds simple pause/unpause commands for players",
    version = "1.0.3",
    url = "https://forums.alliedmods.net"
};

/* Bools */
new bool:g_pause_freezetime = false;
new bool:g_pause_offered_t = false;
new bool:g_pause_offered_ct = false;
new bool:g_paused = false;

/* Handles */
new Handle:sv_pausable;
new Handle:g_h_auto_unpause = INVALID_HANDLE;
new Handle:g_h_auto_unpause_delay = INVALID_HANDLE;
//new Handle:g_h_pause_freezetime = INVALID_HANDLE;
new Handle:g_h_pause_confirm = INVALID_HANDLE;
new Handle:g_h_pause_limit = INVALID_HANDLE;
new g_t_pause_count = 0;
new g_ct_pause_count = 0;
new Handle:g_h_stored_timer = INVALID_HANDLE;

public void OnPluginStart() {

    /** Load Translations **/
    LoadTranslations("pauseplugin.phrases");

    // Pause and Unpause stuff
    sv_pausable = FindConVar ("sv_pausable");
    g_h_pause_confirm = CreateConVar("sm_pause_confirm", "0", "Wait for other team to confirm pause: 0 = off, 1 = on", FCVAR_NOTIFY);
    g_h_auto_unpause = CreateConVar("sm_auto_unpause", "1", "Sets auto unpause: 0 = off, 1 = on", FCVAR_NOTIFY);
//    g_h_pause_freezetime = CreateConVar("wm_pause_freezetime", "1", "Wait for freeze time to pause: 0 = off, 1 = on", FCVAR_NOTIFY);
    g_h_auto_unpause_delay = CreateConVar("sm_auto_unpause_delay", "30", "Sets the seconds to wait before auto unpause", FCVAR_NOTIFY, true, 0.0);
    g_h_pause_limit = CreateConVar("sm_pause_limit", "2", "Sets max pause count per team per half", FCVAR_NOTIFY);
}

public Action:SayChat(client, args)
{
    if (!IsActive(0, true) || args < 1)
    {
        // If no args
        return Plugin_Continue;
    }
    
    new String:type[64];
    GetCmdArg(0, type, sizeof(type));
    
    new bool:teamOnly = false;
    new bool:silence = false;
    
    if (StrEqual(type, "say_team", false))
    {
        // true if not console, as console is always global
        teamOnly = !! client;
    }
    
    new String:message[192];
    GetCmdArgString(message, sizeof(message));
    StripQuotes(message);
    
    if (message[0] == '!' || message[0] == '.' || message[0] == '/')
    {
        if (StrEqual(command, "pause", false) || StrEqual(command, "pauses", false) || StrEqual(command, "p", false))
        {
            Pause(client, args);
        }
        else if (StrEqual(command, "unpause", false) || StrEqual(command, "unpauses", false) || StrEqual(command, "up", false))
        {
            Unpause(client, args);
        }
    }
}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!IsActive(0, true))
    {
        return;
    }
    
    //Pause command fire on round end May change to on round start
    if (g_pause_freezetime == true)
    {
        g_pause_freezetime = false;
        PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", "Unpause Notice", LANG_SERVER);
        if(GetConVarBool(g_h_auto_unpause))
        {
            PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %i %T", GetConVarInt(g_h_auto_unpause_delay), "Unpause Timer", LANG_SERVER);
            g_h_stored_timer = CreateTimer(GetConVarFloat(g_h_auto_unpause_delay), UnPauseTimer);
        }
        g_paused = true;
        //ServerCommand("mp_pause_match 1");
    }
}


//Pause and Unpause Commands + timers
public Action:Pause(client, args)
{
    if (GetConVarBool(sv_pausable))
    {
        if (GetConVarBool(g_h_pause_confirm))
        {
            if (GetClientTeam(client) == 2 && g_pause_offered_ct == true)
            {
                if(g_h_stored_timer != INVALID_HANDLE)
                {
                    KillTimer(g_h_stored_timer);
                    g_h_stored_timer = INVALID_HANDLE;
                }
                
                g_pause_offered_ct = false;
                g_ct_pause_count++;
                
                //if (GetConVarBool(g_h_pause_freezetime))
                //{
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", "Pause Freeze Time", LANG_SERVER);
                g_pause_freezetime = true;
                /*}
                else
                {
                    PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", CHAT_PREFIX, "Unpause Notice", LANG_SERVER);
                    if (GetConVarBool(g_h_auto_unpause))
                    {
                        PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %i %T", CHAT_PREFIX, GetConVarInt(g_h_auto_unpause_delay), "Unpause Timer", LANG_SERVER);
                        g_h_stored_timer = CreateTimer(GetConVarFloat(g_h_auto_unpause_delay), UnPauseTimer);
                    }*/
                g_paused = true;
                ServerCommand("mp_pause_match 1");
                return;
                //}
            }
            else if (GetClientTeam(client) == 3 && g_pause_offered_t == true)
            {
                if(g_h_stored_timer != INVALID_HANDLE)
                {
                    KillTimer(g_h_stored_timer);
                    g_h_stored_timer = INVALID_HANDLE;
                }
                g_pause_offered_t = false;
                g_t_pause_count++;
                
                //if (GetConVarBool(g_h_pause_freezetime))
                //{
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", "Pause Round End", LANG_SERVER);
                g_pause_freezetime = true;
                /*}
                else
                {
                    PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", CHAT_PREFIX, "Unpause Notice", LANG_SERVER);
                    if (GetConVarBool(g_h_auto_unpause))
                    {
                        PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %i %T", CHAT_PREFIX, GetConVarInt(g_h_auto_unpause_delay), "Unpause Timer", LANG_SERVER);
                        g_h_stored_timer = CreateTimer(GetConVarFloat(g_h_auto_unpause_delay), UnPauseTimer);
                    }*/
                g_paused = true;
                ServerCommand("mp_pause_match 1");
                return;
                //}
            }
            else if (GetClientTeam(client) == 2 && g_t_pause_count == GetConVarInt(g_h_pause_limit))
            {
                PrintToChat(client, "\x01 \x09[\x04%s\x09]\x01 %T", "Pause Limit", LANG_SERVER);
            }
            else if (GetClientTeam(client) == 3 && g_ct_pause_count == GetConVarInt(g_h_pause_limit))
            {
                PrintToChat(client, "\x01 \x09[\x04%s\x09]\x01 %T", "Pause Limit", LANG_SERVER);
            }
            else if (GetClientTeam(client) < 2 )
            {
                PrintToChat(client, "\x01 \x09[\x04%s\x09]\x01 %T", "Pause Non-player", LANG_SERVER);
            }
            else if (GetClientTeam(client) == 3 && g_ct_pause_count != GetConVarInt(g_h_pause_limit) && g_pause_offered_ct == false)
            {
                g_pause_offered_ct = true;
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %s %T", "Pause Offer", LANG_SERVER);
                g_h_stored_timer = CreateTimer(30.0, PauseTimeout);
            }
            else if (GetClientTeam(client) == 2 && g_t_pause_count != GetConVarInt(g_h_pause_limit) && g_pause_offered_t == false)
            {
                g_pause_offered_t = true;
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %s %T", "Pause Offer", LANG_SERVER);
                g_h_stored_timer = CreateTimer(30.0, PauseTimeout);
            }
        }
        else if (GetClientTeam(client) == 3 && g_ct_pause_count != GetConVarInt(g_h_pause_limit) && !GetConVarBool(g_h_pause_confirm))
        {
            g_ct_pause_count++;
            //if (GetConVarBool(g_h_pause_freezetime))
            //{
            PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", "Pause Freeze Time", LANG_SERVER);
            g_pause_freezetime = true;
            /*}
            else
            {
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", CHAT_PREFIX, "Unpause Notice", LANG_SERVER);
                if(GetConVarBool(g_h_auto_unpause))
                {
                    PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %i %T", CHAT_PREFIX, GetConVarInt(g_h_auto_unpause_delay), "Unpause Timer", LANG_SERVER);
                    g_h_stored_timer = CreateTimer(GetConVarFloat(g_h_auto_unpause_delay), UnPauseTimer);
                }*/
            g_paused = true;
            ServerCommand("mp_pause_match 1");
            return;
            //}
        }
        else if (GetClientTeam(client) == 2 &&  g_t_pause_count != GetConVarInt(g_h_pause_limit) && GetConVarBool(g_h_pause_confirm) == false)
        {
            g_t_pause_count++;
            //if (GetConVarBool(g_h_pause_freezetime))
            //{
            PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", "Pause Freeze Time", LANG_SERVER);
            g_pause_freezetime = true;
            /*}
            else
            {
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", CHAT_PREFIX, "Unpause Notice", LANG_SERVER);
                if(GetConVarBool(g_h_auto_unpause))
                {
                    PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %i %T", CHAT_PREFIX, GetConVarInt(g_h_auto_unpause_delay), "Unpause Timer", LANG_SERVER);
                    g_h_stored_timer = CreateTimer(GetConVarFloat(g_h_auto_unpause_delay), UnPauseTimer);
                }*/
            g_paused = true;
            ServerCommand("mp_pause_match 1");
            return;
            //}
        }
        else if (GetClientTeam(client) == 2 && g_t_pause_count == GetConVarInt(g_h_pause_limit))
        {
            PrintToChat(client, "\x01 \x09[\x04%s\x09]\x01 %T", "Pause Limit", LANG_SERVER);
        }
        else if (GetClientTeam(client) == 3 && g_ct_pause_count == GetConVarInt(g_h_pause_limit))
        {
            PrintToChat(client, "\x01 \x09[\x04%s\x09]\x01 %T", "Pause Limit", LANG_SERVER);
        }
        else if (GetClientTeam(client) < 2)
        {
        PrintToChat(client, "\x01 \x09[\x04%s\x09]\x01 %T", "Pause Non-player", LANG_SERVER);
        }
    }
    else
    {
        PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", "Pause Not Enabled", LANG_SERVER);
    }
}

public Action:Unpause(client, args)
{
    if (g_paused)
    {
        if (GetConVarBool(g_h_pause_confirm))
        {
            if (GetClientTeam(client) == 3 && g_pause_offered_ct == false && g_pause_offered_t == false)
            {
                g_pause_offered_ct = true;
                PrintToConsoleAll("CT have asked to unpause the game. Please type /unpause to unpause the match.");
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %s %T", "Unpause Offer", LANG_SERVER);
            }
            else if (GetClientTeam(client) == 2 && g_pause_offered_t == false && g_pause_offered_ct == false)
            {
                g_pause_offered_t = true;
                PrintToConsoleAll("T have asked to unpause the game. Please type /unpause to unpause the match.");
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %s %T", "Unpause Offer", LANG_SERVER);
            }
            else if (GetClientTeam(client) == 2 && g_pause_offered_ct == true)
            {
                g_pause_offered_ct = false;
                g_paused = false;
                ServerCommand("mp_unpause_match 1");
            }
            else if (GetClientTeam(client) == 3 && g_pause_offered_t == true)
            {
                g_pause_offered_t = false;
                g_paused = false;
                ServerCommand("mp_unpause_match 1");
            }
            else if (GetClientTeam(client) < 2 )
            {
                PrintToConsole(client, " You must be on T or CT to enable /unpause");
                PrintToChat(client, "\x01 \x09[\x04%s\x09]\x01 %T", "Unpause Non-player", LANG_SERVER);
            }
        }
        else
        {
            if (GetClientTeam(client) == 2)
            {
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %s %T", "Unpaused Match", LANG_SERVER);
                g_paused = false;
                ServerCommand("mp_unpause_match 1");
            }
            else if (GetClientTeam(client) == 3)
            {
                PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %s %T", "Unpaused Match", LANG_SERVER);
                g_paused = false;
                ServerCommand("mp_unpause_match 1");
            }
            else if (GetClientTeam(client) < 2 )
            {
                PrintToConsole(client, "You must be on T or CT to enable /unpause");
                PrintToChat(client, "\x01 \x09[\x04%s\x09]\x01 %T", "Unpause Non-player", LANG_SERVER);
            }
        }
    }
    else
    {
        PrintToChat(client,"\x01 \x09[\x04%s\x09]\x01 %T", "Paused Via Rcon", LANG_SERVER);
        PrintToConsole(client,"Server is not paused or was paused via rcon");
    }
}

public Action:PauseTimeout(Handle:timer)
{
    g_h_stored_timer = INVALID_HANDLE;
    PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", "Pause Offer Not Confirmed", LANG_SERVER);
    g_pause_offered_ct = false;
    g_pause_offered_t = false;
}

public Action:UnPauseTimer(Handle:timer)
{
    g_h_stored_timer = INVALID_HANDLE;
    PrintToChatAll("\x01 \x09[\x04%s\x09]\x01 %T", "Unpause Auto", LANG_SERVER);
    ServerCommand("mp_unpause_match 1");
    g_pause_offered_ct = false;
    g_pause_offered_t = false;
} 