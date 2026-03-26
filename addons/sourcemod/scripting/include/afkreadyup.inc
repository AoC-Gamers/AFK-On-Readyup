#if defined _afkreadyup_included
	#endinput
#endif
#define _afkreadyup_included

#define AFKREADYUP_LIBRARY "afkreadyup"
#define AFKREADYUP_PLUGIN "AFKReadyup.smx"

/**
 * Whether AFKReadyup is currently tracking AFK timers during readyup.
 *
 * @return          True if AFK tracking is active.
 */
native bool AFKReadyup_IsTrackingActive();

/**
 * Returns the remaining AFK time for a client.
 *
 * @param client    Client to query.
 * @return          Remaining seconds before the AFK action triggers.
 */
native int AFKReadyup_GetClientSecondsRemaining(int client);

/**
 * Resets the AFK timer for a client if AFKReadyup is active and the client is eligible.
 *
 * @param client    Client to reset.
 * @return          True if the timer was reset.
 */
native bool AFKReadyup_ResetClientTimer(int client);

/**
 * Returns whether the delayed kick timer is pending for a client.
 *
 * @param client    Client to query.
 * @return          True if a kick timer is pending.
 */
native bool AFKReadyup_IsKickPending(int client);

/**
 * Returns the lowest remaining AFK time among currently tracked players.
 *
 * @return          Lowest remaining AFK time in seconds.
 */
native int AFKReadyup_GetLowestRemainingTime();

/**
 * Fired after AFKReadyup starts tracking players for the current readyup.
 */
forward void AFKReadyup_OnTrackingStarted();

/**
 * Fired after AFKReadyup stops tracking players for the current readyup.
 */
forward void AFKReadyup_OnTrackingStopped();

/**
 * Fired before AFKReadyup moves a client to spectator for inactivity.
 * Return Plugin_Handled or Plugin_Stop to block the default action.
 *
 * @param client            Client that is about to be moved.
 * @param timeoutSeconds    Configured AFK timeout used for the move.
 * @return                  Plugin_Continue to allow the move.
 */
forward Action AFKReadyup_OnClientMoveToSpectator(int client, int timeoutSeconds);

/**
 * Fired after AFKReadyup moves a client to spectator for inactivity.
 *
 * @param client            Client that was moved.
 * @param timeoutSeconds    Configured AFK timeout used for the move.
 */
forward void AFKReadyup_OnClientMovedToSpectator(int client, int timeoutSeconds);

/**
 * Fired before AFKReadyup kicks a spectator after the delayed kick timer expires.
 * Return Plugin_Handled or Plugin_Stop to block the default kick.
 *
 * @param client        Client that is about to be kicked.
 * @param kickDelay     Configured kick delay in seconds.
 * @return              Plugin_Continue to allow the kick.
 */
forward Action AFKReadyup_OnClientKick(int client, int kickDelay);

/**
 * Fired after AFKReadyup kicks a client for staying AFK too long.
 *
 * @param client        Client that was kicked.
 */
forward void AFKReadyup_OnClientKicked(int client);

public SharedPlugin __pl_afkreadyup =
{
	name = AFKREADYUP_LIBRARY,
	file = AFKREADYUP_PLUGIN,
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_afkreadyup_SetNTVOptional()
{
	MarkNativeAsOptional("AFKReadyup_IsTrackingActive");
	MarkNativeAsOptional("AFKReadyup_GetClientSecondsRemaining");
	MarkNativeAsOptional("AFKReadyup_ResetClientTimer");
	MarkNativeAsOptional("AFKReadyup_IsKickPending");
	MarkNativeAsOptional("AFKReadyup_GetLowestRemainingTime");
}
#endif