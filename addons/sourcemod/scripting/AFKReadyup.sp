#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <colors>

#define AFKREADYUP_LIBRARY "afkreadyup"

#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

/*****************************************************************
			G L O B A L   V A R S
*****************************************************************/

ConVar
	g_cvarDebug,
	g_cvarEnable,
	g_cvarPlayerIgnore,
	g_cvarTime,
	g_cvarReadyFooter,
	g_cvarShowTimer,
	g_cvarKickDelay;

int
	g_iPlayerAFK[MAXPLAYERS + 1],
	g_iPrevButtons[MAXPLAYERS + 1],
	g_iPrevMouse[MAXPLAYERS + 1][2];

float
	g_fPlayerLastPos[MAXPLAYERS + 1][3],
	g_fPlayerLastEyes[MAXPLAYERS + 1][3];

Handle
	g_hStartTimerAFK,
	g_hKickTimer[MAXPLAYERS + 1],
	g_hFwdTrackingStarted,
	g_hFwdTrackingStopped,
	g_hFwdClientMoveToSpectator,
	g_hFwdClientMovedToSpectator,
	g_hFwdClientKick,
	g_hFwdClientKicked;

bool
	g_bLateLoad,
	g_bReadyUpAvailable,
	g_bReadyFooterSpacerAdded,
	g_bGamePaused		= false;

int g_iReadyFooterIndex = -1;

enum L4DTeam
{
	L4DTeam_Unassigned = 0,
	L4DTeam_Spectator  = 1,
	L4DTeam_Survivor   = 2,
	L4DTeam_Infected   = 3
}

/*****************************************************************
			P L U G I N   I N F O
*****************************************************************/

public Plugin myinfo =
{
	name		= "AFK on Readyup",
	author		= "lechuga, heize",
	description = "Manage AFK players in the readyup",
	version		=	"1.2.0",
	url			= "https://github.com/lechuga16/AFK-on-readyup"
};

/*****************************************************************
			F O R W A R D   P U B L I C S
*****************************************************************/
public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)
{
	AFKReadyup_RegisterApi();
	g_bLateLoad = bLate;
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	g_bReadyUpAvailable = LibraryExists("readyup");
}

public void OnLibraryAdded(const char[] sName)
{
	if (StrEqual(sName, "readyup"))
		g_bReadyUpAvailable = true;
}

public void OnLibraryRemoved(const char[] sName)
{
	if (StrEqual(sName, "readyup"))
		g_bReadyUpAvailable = false;
}

public void OnPluginStart()
{
	LoadTranslations("AFKReadyup.phrases");
	g_cvarDebug		   = CreateConVar("sm_afk_debug", "0", "Debug messages", FCVAR_NONE, true, 0.0, true, 1.0);
	g_cvarEnable	   = CreateConVar("sm_afk_enable", "1", "Activate the plugin", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarPlayerIgnore = CreateConVar("sm_afk_ignore", "1", "Ignore players ready", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarTime		   = CreateConVar("sm_afk_time", "90", "Time to move players during readyup", FCVAR_NOTIFY, true, 0.0);
	g_cvarReadyFooter  = CreateConVar("sm_afk_footer", "1", "Show ready footer (0 = disabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvarShowTimer	   = CreateConVar("sm_afk_show", "10", "Show timer to players (0 = disabled)", FCVAR_NOTIFY, true, 0.0);
	g_cvarKickDelay	   = CreateConVar("sm_afk_kick_delay", "360", "Delay (in seconds) before kicking player from server after moving to spectator (0 = disabled)", FCVAR_NOTIFY, true, 0.0);

	AutoExecConfig(true, "AFKReadyup");

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);

	HookEvent("entity_shoved", Event_PlayerAction_Attacker);
	HookEvent("weapon_fire", Event_PlayerAction_UserID);
	HookEvent("weapon_reload", Event_PlayerAction_UserID);
	HookEvent("player_use", Event_PlayerAction_UserID);
	HookEvent("player_jump", Event_PlayerAction_UserID);
	HookEvent("player_team", Event_PlayerTeam);

	AddCommandListener(OnCommandExecute, "spec_mode");
	AddCommandListener(OnCommandExecute, "spec_next");
	AddCommandListener(OnCommandExecute, "spec_prev");
	AddCommandListener(OnCommandExecute, "say");
	AddCommandListener(OnCommandExecute, "say_team");
	AddCommandListener(OnCommandExecute, "callvote");
	AddCommandListener(OnCommandExecute, "pause");
	AddCommandListener(OnCommandExecute, "unpause");

	if (!g_bLateLoad)
		return;

	g_bReadyUpAvailable = LibraryExists("readyup");
}

void AFKReadyup_RegisterApi()
{
	CreateNative("AFKReadyup_IsTrackingActive", Native_AFKReadyupIsTrackingActive);
	CreateNative("AFKReadyup_GetClientSecondsRemaining", Native_AFKReadyupGetClientSecondsRemaining);
	CreateNative("AFKReadyup_ResetClientTimer", Native_AFKReadyupResetClientTimer);
	CreateNative("AFKReadyup_IsKickPending", Native_AFKReadyupIsKickPending);
	CreateNative("AFKReadyup_GetLowestRemainingTime", Native_AFKReadyupGetLowestRemainingTime);

	g_hFwdTrackingStarted		  = CreateGlobalForward("AFKReadyup_OnTrackingStarted", ET_Ignore);
	g_hFwdTrackingStopped		  = CreateGlobalForward("AFKReadyup_OnTrackingStopped", ET_Ignore);
	g_hFwdClientMoveToSpectator = CreateGlobalForward("AFKReadyup_OnClientMoveToSpectator", ET_Hook, Param_Cell, Param_Cell);
	g_hFwdClientMovedToSpectator = CreateGlobalForward("AFKReadyup_OnClientMovedToSpectator", ET_Ignore, Param_Cell, Param_Cell);
	g_hFwdClientKick			  = CreateGlobalForward("AFKReadyup_OnClientKick", ET_Hook, Param_Cell, Param_Cell);
	g_hFwdClientKicked			  = CreateGlobalForward("AFKReadyup_OnClientKicked", ET_Ignore, Param_Cell);

	RegPluginLibrary(AFKREADYUP_LIBRARY);
}

Action Command_Say(int iClient, int iArgs)
{
	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady())
		return Plugin_Continue;

	if (!IsValidClientIndex(iClient) || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return Plugin_Continue;

	ResetTimers(iClient);
	return Plugin_Continue;
}

public void OnPluginEnd()
{
	PrintDebug("Plugin End, timer null (%s)", (g_hStartTimerAFK != null) ? "true" : "false");
	StopAfkTimer();
	ResetAllClientState();
}

public void OnMapEnd()
{
	/*
	 * Sometimes the event 'round_start' is called before OnMapStart()
	 * and the timer handle is not reset, so it's better to do it here.
	 */
	StopAfkTimer();
	ResetAllClientState();
	g_bGamePaused = false;
}

/*****************************************************************
			F O R W A R D   P L U G I N S
*****************************************************************/
public OnReadyUpInitiate()
{
	if (!g_cvarEnable.BoolValue)
		return;
	StartReadyupAfkTracking();
}

public OnRoundIsLive()
{
	if (!g_cvarEnable.BoolValue)
		return;

	PrintDebug("Round is Live, timer null (%s)", (g_hStartTimerAFK != null) ? "true" : "false");
	StopAfkTimer();
	ResetAllClientState();
	g_bGamePaused = false;
	ResetReadyFooterState();
}

public void OnReadyCountdownCancelled(int client, char[] sDisruptReason)
{
	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady())
		return;

	PrintDebug("Ready countdown cancelled by client %d. reason=%s", client, sDisruptReason);
	StartReadyupAfkTracking();
}

public void OnPlayerReady(int client)
{
	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady() || !IsHumanClient(client) || !CheckTeam(client))
		return;

	ResetTimers(client, false);
}

public void OnPlayerUnready(int client)
{
	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady() || !IsHumanClient(client) || !CheckTeam(client))
		return;

	ResetTimers(client, false);
}

/****************************************************************
			C A L L B A C K   F U N C T I O N S
****************************************************************/

void Event_PlayerAction_Attacker(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady())
		return;

	int iClient = GetClientOfUserId(hEvent.GetInt("attacker"));
	if (!IsValidClientIndex(iClient) || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return;

	ResetTimers(iClient);
}

void Event_PlayerAction_UserID(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady())
		return;

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsValidClientIndex(iClient) || !IsClientInGame(iClient) || IsFakeClient(iClient))
		return;

	ResetTimers(iClient);
}

void Event_PlayerTeam(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady())
		return;

	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (!IsClientInGame(iClient) || IsFakeClient(iClient))
		return;

	L4DTeam Team = view_as<L4DTeam>(GetEventInt(hEvent, "team"));
	if (Team == L4DTeam_Survivor || Team == L4DTeam_Infected)
		ResetTimers(iClient, false);
}

/*****************************************************************
			P L U G I N   F U N C T I O N S
*****************************************************************/

Action Timer_CheckAFK(Handle timer)
{
	if (g_bGamePaused)
		return Plugin_Continue;

	bool bIgnoreReady		 = g_cvarPlayerIgnore.BoolValue;
	int	 iAfkTimeout		 = g_cvarTime.IntValue;
	int	 iShowTimerThreshold = g_cvarShowTimer.IntValue;
	bool bShowTimer			 = (iShowTimerThreshold > 0);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsHumanClient(i))
			continue;

		if (!CheckTeam(i))
			continue;

		if (bIgnoreReady && IsReady(i))
			continue;

		if (bShowTimer && g_iPlayerAFK[i] <= iShowTimerThreshold)
			CPrintToChat(i, "%t %t", "Tag", "ShowTimer", g_iPlayerAFK[i]);

		if (PlayerPositionChanged(i))
		{
			ResetTimers(i, false);
			continue;
		}

		if (PlayerEyesChanged(i))
		{
			ResetTimers(i, false);
			continue;
		}

		g_iPlayerAFK[i] = g_iPlayerAFK[i] - 1;

		if (g_iPlayerAFK[i] > 0)
			continue;

		if (!AFKReadyup_OnClientMoveToSpectatorPre(i, iAfkTimeout))
		{
			ResetTimers(i, false);
			continue;
		}

		L4D_ChangeClientTeam(i, L4DTeam_Spectator);
		AFKReadyup_OnClientMovedToSpectatorPost(i, iAfkTimeout);
		CPrintToChatAll("%t %t", "Tag", "MoveToSpec", i);
		StartKickTimer(i);	  // Start the kick timer after moving to spectator
	}

	UpdateReadyFooter();
	return Plugin_Continue;
}

/**
 * Starts a timer to kick a player after moving to spectator.
 *
 * @param iClient The client index.
 */
void StartKickTimer(int iClient)
{
	// Check if the kick delay is set to 0, if so, do not start the kick timer
	if (g_cvarKickDelay.FloatValue <= 0.0)
	{
		return;
	}

	// Check if the player is in spectator mode
	if (L4D_GetClientTeam(iClient) != L4DTeam_Spectator)
	{
		return;
	}

	SafeDeleteHandle(g_hKickTimer[iClient]);

	g_hKickTimer[iClient] = CreateTimer(g_cvarKickDelay.FloatValue, Timer_KickPlayer, GetClientUserId(iClient));
}

/**
 * Timer callback to kick a player.
 *
 * @param timer The timer handle.
 */
Action Timer_KickPlayer(Handle timer, int iUserId)
{
	int iClient = GetClientOfUserId(iUserId);

	if (iClient > 0 && iClient <= MaxClients)
	{
		g_hKickTimer[iClient] = null;
	}

	if (iClient == 0 || !IsClientInGame(iClient) || IsFakeClient(iClient))
	{
		return Plugin_Stop;
	}

	if (g_cvarKickDelay.FloatValue <= 0.0)
	{
		return Plugin_Stop;
	}

	// Check if the player is still in spectator mode
	if (L4D_GetClientTeam(iClient) != L4DTeam_Spectator)
	{
		return Plugin_Stop;
	}

	char sName[MAX_NAME_LENGTH];
	int iKickDelay = RoundToNearest(g_cvarKickDelay.FloatValue);
	if (!AFKReadyup_OnClientKickPre(iClient, iKickDelay))
	{
		return Plugin_Stop;
	}

	GetClientName(iClient, sName, sizeof(sName));
	CPrintToChatAll("%t %T", "Tag", "KickMessage", LANG_SERVER, sName);
	KickClient(iClient, "You were kicked for being AFK for too long.");
	AFKReadyup_OnClientKickedPost(iClient);

	return Plugin_Stop;
}

Action OnCommandExecute(int client, const char[] command, int argc)
{
	if (g_cvarEnable.BoolValue && g_bReadyUpAvailable && IsInReady() && IsHumanClient(client) && CheckTeam(client))
	{
		ResetTimers(client, false);
	}

	// Handle pause/unpause state tracking
	if (StrEqual(command, "pause", false))
	{
		g_bGamePaused = true;
	}
	else if (StrEqual(command, "unpause", false)) {
		g_bGamePaused = false;
	}

	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
	if (g_bGamePaused || !g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady())
		return;

	if (!IsHumanClient(client) || !CheckTeam(client))
		return;

	if (g_iPrevButtons[client] != buttons || g_iPrevMouse[client][0] != mouse[0] || g_iPrevMouse[client][1] != mouse[1])
	{
		g_iPrevButtons[client]	= buttons;
		g_iPrevMouse[client][0] = mouse[0];
		g_iPrevMouse[client][1] = mouse[1];
		ResetTimers(client, false);
	}
}

public void OnClientConnected(int client)
{
	ResetClientState(client);
}

public void OnClientDisconnect_Post(int client)
{
	ResetClientState(client);
}

public void OnClientPutInServer(int client)
{
	ResetClientState(client);

	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady())
		return;

	if (!IsHumanClient(client) || !CheckTeam(client))
		return;

	ResetTimers(client);
}

/**
 * Checks the team of a client.
 *
 * @param iClient The client index.
 * @return True if the client is on the Survivor or Infected team, false otherwise.
 */
bool CheckTeam(int iClient)
{
	L4DTeam Team = L4D_GetClientTeam(iClient);
	return Team == L4DTeam_Survivor || Team == L4DTeam_Infected;
}

/**
 * Checks if the position of a player has changed.
 *
 * @param iClient The client index of the player.
 * @return True if the player's position has changed by more than 80 units, false otherwise.
 */
bool PlayerPositionChanged(int iClient)
{
	float fPos[3];
	GetClientAbsOrigin(iClient, fPos);
	return GetVectorDistance(fPos, g_fPlayerLastPos[iClient], true) > 6400.0;
}

/**
 * Checks if the eyes of a player have changed.
 *
 * @param iClient The client index of the player.
 * @return True if the eyes have changed, false otherwise.
 */
bool PlayerEyesChanged(int iClient)
{
	float fEyes[3];
	GetClientEyeAngles(iClient, fEyes);

	float fPitchDelta = FloatAbs(fEyes[0] - g_fPlayerLastEyes[iClient][0]);
	float fYawDelta	  = FloatAbs(fEyes[1] - g_fPlayerLastEyes[iClient][1]);
	if (fYawDelta > 180.0)
		fYawDelta = 360.0 - fYawDelta;

	return fPitchDelta >= 2.0 || fYawDelta >= 2.0;
}

/**
 * Resets the timers for a client.
 *
 * @param iClient The client index.
 * @param bCheckTeam Whether to check the client's team before resetting the timers. Default is true.
 */
void ResetTimers(int iClient, bool bCheckTeam = true)
{
	PrintDebug("Resetting timers for client %d", iClient);

	if (bCheckTeam && !CheckTeam(iClient))
		return;

	g_iPlayerAFK[iClient] = g_cvarTime.IntValue;
	GetClientAbsOrigin(iClient, g_fPlayerLastPos[iClient]);
	GetClientEyeAngles(iClient, g_fPlayerLastEyes[iClient]);
	SafeDeleteHandle(g_hKickTimer[iClient]);
}

void StopAfkTimer()
{
	bool bWasTracking = (g_hStartTimerAFK != null);
	SafeDeleteHandle(g_hStartTimerAFK);
	if (bWasTracking)
		AFKReadyup_OnTrackingStoppedPost();
}

void StartReadyupAfkTracking()
{
	StopAfkTimer();
	ResetAllClientState();
	ResetReadyFooterState();

	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsHumanClient(iClient) || !CheckTeam(iClient))
			continue;

		ResetTimers(iClient, false);
	}

	UpdateReadyFooter();
	g_hStartTimerAFK = CreateTimer(1.0, Timer_CheckAFK, _, TIMER_REPEAT);
	AFKReadyup_OnTrackingStartedPost();
}

bool AFKReadyup_OnClientMoveToSpectatorPre(int client, int timeoutSeconds)
{
	if (g_hFwdClientMoveToSpectator == null)
		return true;

	Action result = Plugin_Continue;
	Call_StartForward(g_hFwdClientMoveToSpectator);
	Call_PushCell(client);
	Call_PushCell(timeoutSeconds);
	Call_Finish(result);

	return (result < Plugin_Handled);
}

void AFKReadyup_OnClientMovedToSpectatorPost(int client, int timeoutSeconds)
{
	if (g_hFwdClientMovedToSpectator == null)
		return;

	Call_StartForward(g_hFwdClientMovedToSpectator);
	Call_PushCell(client);
	Call_PushCell(timeoutSeconds);
	Call_Finish();
}

bool AFKReadyup_OnClientKickPre(int client, int kickDelay)
{
	if (g_hFwdClientKick == null)
		return true;

	Action result = Plugin_Continue;
	Call_StartForward(g_hFwdClientKick);
	Call_PushCell(client);
	Call_PushCell(kickDelay);
	Call_Finish(result);

	return (result < Plugin_Handled);
}

void AFKReadyup_OnClientKickedPost(int client)
{
	if (g_hFwdClientKicked == null)
		return;

	Call_StartForward(g_hFwdClientKicked);
	Call_PushCell(client);
	Call_Finish();
}

void AFKReadyup_OnTrackingStartedPost()
{
	if (g_hFwdTrackingStarted == null)
		return;

	Call_StartForward(g_hFwdTrackingStarted);
	Call_Finish();
}

void AFKReadyup_OnTrackingStoppedPost()
{
	if (g_hFwdTrackingStopped == null)
		return;

	Call_StartForward(g_hFwdTrackingStopped);
	Call_Finish();
}

public any Native_AFKReadyupIsTrackingActive(Handle plugin, int numParams)
{
	return (g_hStartTimerAFK != null);
}

public any Native_AFKReadyupGetClientSecondsRemaining(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsValidClientIndex(client))
		return 0;

	return g_iPlayerAFK[client];
}

public any Native_AFKReadyupResetClientTimer(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!g_cvarEnable.BoolValue || !g_bReadyUpAvailable || !IsInReady() || !IsHumanClient(client) || !CheckTeam(client))
		return false;

	ResetTimers(client, false);
	return true;
}

public any Native_AFKReadyupIsKickPending(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (!IsValidClientIndex(client))
		return false;

	return (g_hKickTimer[client] != null);
}

public any Native_AFKReadyupGetLowestRemainingTime(Handle plugin, int numParams)
{
	return GetLowestTrackedAfkTime();
}

void ResetClientState(int client)
{
	if (!IsValidClientIndex(client))
		return;

	g_iPlayerAFK[client]		 = 0;
	g_iPrevButtons[client]		 = 0;
	g_iPrevMouse[client][0]		 = 0;
	g_iPrevMouse[client][1]		 = 0;
	g_fPlayerLastPos[client][0]	 = 0.0;
	g_fPlayerLastPos[client][1]	 = 0.0;
	g_fPlayerLastPos[client][2]	 = 0.0;
	g_fPlayerLastEyes[client][0] = 0.0;
	g_fPlayerLastEyes[client][1] = 0.0;
	g_fPlayerLastEyes[client][2] = 0.0;
	SafeDeleteHandle(g_hKickTimer[client]);
}

void ResetAllClientState()
{
	for (int client = 1; client <= MaxClients; client++)
		ResetClientState(client);
}

void ResetReadyFooterState()
{
	g_iReadyFooterIndex		  = -1;
	g_bReadyFooterSpacerAdded = false;
}

int GetLowestTrackedAfkTime()
{
	int	 iLowest	  = g_cvarTime.IntValue;
	bool bFound		  = false;
	bool bIgnoreReady = g_cvarPlayerIgnore.BoolValue;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsHumanClient(client) || !CheckTeam(client))
			continue;

		if (bIgnoreReady && IsReady(client))
			continue;

		if (!bFound || g_iPlayerAFK[client] < iLowest)
		{
			iLowest = g_iPlayerAFK[client];
			bFound	= true;
		}
	}

	return bFound ? iLowest : g_cvarTime.IntValue;
}

void UpdateReadyFooter()
{
	if (!g_cvarReadyFooter.BoolValue || !g_bReadyUpAvailable || !IsInReady())
		return;

	char sBuffer[64];
	Format(sBuffer, sizeof(sBuffer), "%T", "Footer", LANG_SERVER, g_cvarTime.IntValue);

	if (g_iReadyFooterIndex != -1 && EditFooterStringAtIndex(g_iReadyFooterIndex, sBuffer))
		return;

	if (!g_bReadyFooterSpacerAdded)
	{
		AddStringToReadyFooter("");
		g_bReadyFooterSpacerAdded = true;
	}

	g_iReadyFooterIndex = AddStringToReadyFooter(sBuffer);
}

/**
 * Safely deletes a handle.
 *
 * @param h The handle to delete.
 */
void SafeDeleteHandle(Handle &h)
{
	if (h != null && IsValidHandle(h))
	{
		delete h;
		h = null;
	}
}

/**
 * Check if the translation file exists
 *
 * @param translation	Translation name.
 * @noreturn
 */
stock void LoadTranslation(const char[] translation)
{
	char
		sPath[PLATFORM_MAX_PATH],
		sName[64];

	Format(sName, sizeof(sName), "translations/%s.txt", translation);
	BuildPath(Path_SM, sPath, sizeof(sPath), sName);
	if (!FileExists(sPath))
		SetFailState("Missing translation file %s.txt", translation);

	LoadTranslations(translation);
}

/**
 * Returns the clients team using L4DTeam.
 *
 * @param client		Player's index.
 * @return				Current L4DTeam of player.
 * @error				Invalid client index.
 */
stock L4DTeam L4D_GetClientTeam(int client)
{
	int team = GetClientTeam(client);
	return view_as<L4DTeam>(team);
}

/**
 * Changes the team of a client in Left 4 Dead.
 *
 * @param client The client index.
 * @param team The new team for the client.
 */
stock void L4D_ChangeClientTeam(int client, L4DTeam team)
{
	ChangeClientTeam(client, view_as<int>(team));
}

/**
 * Checks if a client index is valid.
 *
 * @param client The client index to check.
 */
stock bool IsValidClientIndex(int iClient)
{
	return iClient > 0 && iClient <= MaxClients;
}

stock bool IsHumanClient(int iClient)
{
	return IsValidClientIndex(iClient) && IsClientInGame(iClient) && !IsFakeClient(iClient);
}

/**
 * Prints a debug message to the server console.
 *
 * @param sMessage The message to be printed.
 * @param ... Additional arguments to be formatted into the message.
 */
void PrintDebug(const char[] sMessage, any...)
{
	if (!g_cvarDebug.BoolValue)
		return;

	static char sFormat[512];
	VFormat(sFormat, sizeof(sFormat), sMessage, 2);

	PrintToServer("[AFK] %s", sFormat);
}

// =======================================================================================
// Bibliography
// https://developer.valvesoftware.com/wiki/List_of_L4D2_Cvars
// https://wiki.alliedmods.net/Generic_Source_Events
// https://wiki.alliedmods.net/Left_4_dead_2_events
// https://github.com/fbef0102/L4D1_2-Plugins/blob/master/L4DVSAutoSpectateOnAFK/scripting/L4DVSAutoSpectateOnAFK.sp
// =======================================================================================
