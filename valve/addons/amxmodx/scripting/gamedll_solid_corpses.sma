#include <amxmisc>
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hlstocks>
#include <xs>

#define PLUGIN  "FixSolidCorpses"
#define VERSION "0.1"
#define AUTHOR  "rtxA"

new g_PutInServer[MAX_PLAYERS + 1];
new g_SendToSpec[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
	register_forward(FM_AddToFullPack, "FM_client_AddToFullPack_Post", 1)
    register_forward(FM_PlayerPreThink, "OnPlayerPreThink_Pre");
}



public FM_client_AddToFullPack_Post(es, e, iEnt, id, hostflags, player, pSet) {
	if( player && id != iEnt && get_orig_retval() && is_user_alive(id) ) {
        if (!is_user_alive(iEnt)) {
			set_es(es, ES_Solid, SOLID_NOT)
        }
	}
}


public OnPlayerPreThink_Pre(id) {
    if (!g_SendToSpec[id]) {
        if (!is_user_bot(id))
            set_pev(id, pev_iuser1, OBS_ROAMING);
        g_SendToSpec[id] = true;
    }
}

public client_putinserver(id) {
    g_PutInServer[id] = true;
}

public client_disconnected(id) {
    g_PutInServer[id] = false;
    g_SendToSpec[id] = false;
}