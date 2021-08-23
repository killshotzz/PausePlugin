#pragma semicolon 1
#include <cstrike>
#include <sourcemod>
#include <sdktools>

/** Bools **/
new bool:g_ctUnpaused = false;
new bool:g_tUnpaused = false;

/** Chat aliases loaded **/
#define ALIAS_LENGTH 64
#define COMMAND_LENGTH 64
ArrayList g_ChatAliases;
ArrayList g_ChatAliasesCommands;

public Plugin:myinfo = {
    name = "CS:GO Pause Commands",
    author = "splewis & ^kS",
    description = "Adds simple pause/unpause commands for players",
    version = "1.0.2",
    url = "https://forums.alliedmods.net"
};

public void OnPluginStart() {
    /** Load Translations **/
    LoadTranslations("pauseplugin.phrases");

    /** Cmds **/
    RegAdminCmd("sm_forcetechpause", Command_ForceTechPause, ADMFLAG_GENERIC, "Forces a technical pause");
    RegAdminCmd("sm_forcepause", Command_ForcePause, ADMFLAG_GENERIC, "Forces a pause");
    RegAdminCmd("sm_forceunpause", Command_ForceUnpause, ADMFLAG_GENERIC, "Forces an unpause");
    RegConsoleCmd("sm_pause", Command_Pause, "Requests a pause");
    RegConsoleCmd("sm_unpause", Command_Unpause, "Requests an unpause");
    RegConsoleCmd("sm_tech", Command_TechPause, "Calls for a text pause");


    /** Client / Admin commands **/
    g_ChatAliases = new ArrayList(ByteCountToCells(ALIAS_LENGTH));
    g_ChatAliasesCommands = new ArrayList(ByteCountToCells(COMMAND_LENGTH));
    AddAliasedCommand("forcetechnical", Command_ForceTechPause, "Force a technical pause");
    AddAliasedCommand("ftech", Command_ForceTechPause, "Force a technical pause");
    AddAliasedCommand("ftec", Command_ForceTechPause, "Force a technical pause");
    AddAliasedCommand("ft", Command_ForceTechPause, "Force a technical pause");
    AddAliasedCommand("forcepause", Command_ForcePause, "Forces the game to pause");
    AddAliasedCommand("fp", Command_ForcePause, "Forces the game to pause");
    AddAliasedCommand("forceunpause", Command_ForceUnpause, "Forces the game to unpause");
    AddAliasedCommand("fup", Command_ForceUnpause, "Forces the game to unpause");
    AddAliasedCommand("tech", Command_TechPause, "Calls for a tech pause");
    AddAliasedCommand("t", Command_TechPause, "Calls for a tech pause");
    AddAliasedCommand("pause", Command_Pause, "Pauses the game");
    AddAliasedCommand("tac", Command_Pause, "Pauses the game");
    AddAliasedCommand("p", Command_Pause, "Pauses the game");
    AddAliasedCommand("tactical", Command_Pause, "Pauses the game");
    AddAliasedCommand("unpause", Command_Unpause, "Unpauses the game");
    AddAliasedCommand("up", Command_Unpause, "Unpauses the game");
}

public OnMapStart() {
    g_ctUnpaused = false;
    g_tUnpaused = false;
}

/** Force Tech Pause **/
public Action Command_ForceTechPause(int client, int args){
    if (IsPaused())
        return Plugin_Handled;

    ServerCommand("mp_pause_match");
    PrintToChatAll("%t, ForceTechPauseMessage", client);
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
    PrintToChatAll("%t, TechPauseMessage", client, client);
    return Plugin_Handled;
}

/** Pause **/
public Action Command_Pause(int client, int args) {
    if (IsPaused() || !IsValidClient(client))
        return Plugin_Handled;

    g_ctUnpaused = false;
    g_tUnpaused = false;

    ServerCommand("mp_pause_match");
    PrintToChatAll("%t", "Pause", client, client);

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
        PrintToChatAll("%t", "tUnpause", client);
    } else if (!g_tUnpaused && g_ctUnpaused) {
        PrintToChatAll("%t", "ctUnpause", client);
    }

    return Plugin_Handled;
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

/** Add Aliased Command callback **/
public void AddAliasedCommand(const char[] command, ConCmd callback, const char[] description) {
  char smCommandBuffer[COMMAND_LENGTH];
  Format(smCommandBuffer, sizeof(smCommandBuffer), "sm_%s", command);
  RegConsoleCmd(smCommandBuffer, callback, description);

  char dotCommandBuffer[ALIAS_LENGTH];
  Format(dotCommandBuffer, sizeof(dotCommandBuffer), ".%s", command);
  AddChatAlias(dotCommandBuffer, smCommandBuffer);
}

/** Add Chat Alias Callback */
public void AddChatAlias(const char[] alias, const char[] command) {
  // Don't allow duplicate aliases to be added.
  if (g_ChatAliases.FindString(alias) == -1) {
    g_ChatAliases.PushString(alias);
    g_ChatAliasesCommands.PushString(command);
  }
}

/** Check to chat alias callback **/
public void CheckForChatAlias(int client, const char[] command, const char[] sArgs) {
  // Splits to find the first word to do a chat alias command check.
  char chatCommand[COMMAND_LENGTH];
  char chatArgs[255];
  int index = SplitString(sArgs, " ", chatCommand, sizeof(chatCommand));

  if (index == -1) {
    strcopy(chatCommand, sizeof(chatCommand), sArgs);
  } else if (index < strlen(sArgs)) {
    strcopy(chatArgs, sizeof(chatArgs), sArgs[index]);
  }

  if (chatCommand[0] && IsValidClient(client)) {
    char alias[ALIAS_LENGTH];
    char cmd[COMMAND_LENGTH];
    for (int i = 0; i < GetArraySize(g_ChatAliases); i++) {
      GetArrayString(g_ChatAliases, i, alias, sizeof(alias));
      GetArrayString(g_ChatAliasesCommands, i, cmd, sizeof(cmd));
      if (CheckChatAlias(alias, cmd, chatCommand, chatArgs, client)) {
        break;
      }
    }
  }
}

/* Checking if the alias is a command callback */
static bool CheckChatAlias(const char[] alias, const char[] command, const char[] chatCommand,
                           const char[] chatArgs, int client) {
  if (StrEqual(chatCommand, alias, false)) {
    // Get the original cmd reply source so it can be restored after the fake client command.
    // This means and ReplyToCommand will go into the chat area, rather than console, since
    // *chat* aliases are for *chat* commands.
    ReplySource replySource = GetCmdReplySource();
    SetCmdReplySource(SM_REPLY_TO_CHAT);
    char fakeCommand[256];
    Format(fakeCommand, sizeof(fakeCommand), "%s %s", command, chatArgs);
    FakeClientCommand(client, fakeCommand);
    SetCmdReplySource(replySource);
    return true;
  }
  return false;
}