#include <amxmisc>
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hlstocks>

#define PLUGIN  "GameDLL Fixes"
#define VERSION "0.1"
#define AUTHOR  "rtxA"

new g_SpectatorMsg;

public plugin_precache() {
	// sends observer status on entering and exiting observer mode (it's not used in vanilla client dll)
	//g_SpectatorMsg = engfunc(EngFunc_RegUserMsg, "Spectator", 2);
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	// block suicide when already dead
	register_forward(FM_ClientKill, "OnClientKill");
}

public TaskPutInServer(id) {
	ShowSpecs_Fix(id);
}

public client_putinserver(id) {
	set_task(0.1, "TaskPutInServer", id);
}

public client_disconnected(id) {
	remove_task(id);
}

public OnClientKill(id) {
	if (hl_get_user_spectator(id)) {
		client_print(id, print_console, "Can't suicide! Already dead.");
		return HAM_SUPERCEDE;
	}

	if (pev(id, pev_deadflag) != DEAD_NO)
		return HAM_SUPERCEDE;

	return HAM_IGNORED;
}

stock ShowSpecs_Fix(id) {
	// Set in scoreboard players in spectator mode when he enters
	static TeamInfo;
	if (TeamInfo || (TeamInfo = get_user_msgid("TeamInfo"))) {
		for (new i = 1; i <= MaxClients; i++) {
			if (is_user_connected(i) && hl_get_user_spectator(i)) {
				message_begin(MSG_ONE, TeamInfo, .player = id);
				write_byte(i);
				write_string("");
				message_end();
			}
		}
	}

	// Message used in some clients (AG and BHL)
	//for (new i = 1; i <= MaxClients; i++) {
	//	if (is_user_connected(i) && hl_get_user_spectator(i)) {
	//		message_begin(MSG_ONE, g_SpectatorMsg, .player = id);
	//		write_byte(i);
	//		write_byte(1);
	//		message_end();
	//	}
	//}
}