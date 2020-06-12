#include <amxmodx>
#include <fakemeta>

#define PLUGIN  "GameDLL Fix Solid Corpses"
#define VERSION "0.2"
#define AUTHOR  "rtxA"

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	register_forward(FM_AddToFullPack, "OnAddToFullPack_Post", true);
}

public OnAddToFullPack_Post(es, e, ent, id, hostflags, player, pSet) {
	if (player && id != ent && get_orig_retval() && is_user_alive(id)) {
		if (!is_user_alive(ent)) {
			set_es(es, ES_Solid, SOLID_NOT)
		}
	}
}
