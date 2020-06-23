#include <amxmisc>
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hlstocks>

#define PLUGIN  "MiniVS BSP Compat"
#define VERSION "0.3"
#define AUTHOR  "rtxA"

new const WEAPONS_CLASSES[][] = {
	"weapon_357",
	"weapon_9mmAR",
	"weapon_9mmhandgun",
	"weapon_crossbow",
	"weapon_egon",
	"weapon_gauss",
	"weapon_handgrenade",
	"weapon_hornetgun",
	"weapon_rpg",
	"weapon_satchel",
	"weapon_shotgun",
	"weapon_snark",
	"weapon_tripmine",
	"weaponbox"
};

new const AMMO_CLASSES[][] = {
	"ammo_357",
	"ammo_9mmAR",
	"ammo_9mmbox",
	"ammo_9mmclip",
	"ammo_ARgrenades",
	"ammo_buckshot",
	"ammo_crossbow",
	"ammo_egonclip",
	"ammo_gaussclip",
	"ammo_glockclip",
	"ammo_mp5clip",
	"ammo_mp5grenades",
	"ammo_rpgclip"
};

new const ITEM_CLASSES[][] = {
	"item_longjump",
	"item_suit",
	"item_battery",
	"item_healthkit",
};

enum {
	TEAM_NONE = 0,
	TEAM_SLAYER = 4, // green color
	TEAM_VAMPIRE = 2 // red color
};

new bool:g_CustomSpawnsExist;

#define Pev_BreakPoints pev_iuser3

new Array:g_BreakPointsList;

public plugin_precache() {
	g_BreakPointsList = ArrayCreate();
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	// spawn all func_breakpoints
	for (new i; i < ArraySize(g_BreakPointsList); i++) {
		dllfunc(DLLFunc_Spawn, ArrayGetCell(g_BreakPointsList, i));
	}

	// create working team spawns
	if (g_CustomSpawnsExist) {
		CreateGameTeamMaster("team1", TEAM_SLAYER);
		CreateGameTeamMaster("team2", TEAM_VAMPIRE);
		RemoveNoTeamSpawns();
	}

	RemoveItems();
	DisableChargers();
}

public plugin_end() {
	ArrayDestroy(g_BreakPointsList);
}

/* Get data of entities from this gamemode
 */
public pfn_keyvalue(ent) {
	new classname[32], key[16], value[64];
	copy_keyvalue(classname, sizeof classname, key, sizeof key, value, sizeof value);

	new Float:vector[3];
	StrToVec(value, vector);

	// info_player_slayer and info_player_vampire
	static spawn;
	if (equal(classname, "info_player_slayer")) {
		g_CustomSpawnsExist = true;
		if (equal(key, "origin")) {
			spawn = create_entity("info_player_deathmatch");
			entity_set_origin(spawn, vector);
			set_pev(spawn, pev_netname, "team1");
		} else if (equal(key, "angles")) {
			set_pev(spawn, pev_angles, vector);
		}
	} else if (equal(classname, "info_player_vampire")) {
		g_CustomSpawnsExist = true;
		if (equal(key, "origin")) {
			spawn = create_entity("info_player_deathmatch");
			entity_set_origin(spawn, vector);
			set_pev(spawn, pev_netname, "team2");
		} else if (equal(key, "angles")) {
			set_pev(spawn, pev_angles, vector);
		}
	}

	// func_breakpoints
	static entity;
	if (equal(classname, "func_breakpoints")) {
		if (equal(key, "model")) {
			entity = create_entity("func_breakable");
			// no need to change classname for now, is useful to leave 
			// intact the classname so restore map api can restore the breakable
			//set_pev(entity, pev_classname, "func_breakpoints");
			ArrayPushCell(g_BreakPointsList, entity);
		} else if (equal(key, "points")) {
			set_pev(entity, Pev_BreakPoints, str_to_num(value));			
		}
		DispatchKeyValue(entity, key, value);
	}

	return PLUGIN_CONTINUE;
}

// ================= stocks ===========================

// the parsed string is in this format "x y z" e.g "128 0 256"
stock Float:StrToVec(const string[], Float:vector[3]) {
	new arg[3][12]; // hold parsed vector
	parse(string, arg[0], charsmax(arg[]), arg[1], charsmax(arg[]), arg[2], charsmax(arg[]));

	for (new i; i < sizeof arg; i++)
		vector[i] = str_to_float(arg[i]);
}

stock CreateGameTeamMaster(name[], teamid) {
	new ent = create_entity("game_team_master");
	set_pev(ent, pev_targetname, name);
	DispatchKeyValue(ent, "teamindex", fmt("%i", teamid - 1));
	return ent;
}

// remove deathmatch spawns so the team spawns can work correctly
stock RemoveNoTeamSpawns() {
	new ent, master[32];
	while ((ent = find_ent_by_class(ent, "info_player_deathmatch"))) {
		pev(ent, pev_netname, master, charsmax(master));
		if (!equal(master, "team1") && !equal(master, "team2")) {
			remove_entity(ent);
		} 
	}
}

stock RemoveItems() {
	for (new i; i < sizeof(WEAPONS_CLASSES); i++) {
		new ent;
		while ((ent = find_ent_by_class(ent, WEAPONS_CLASSES[i]))) {
			set_pev(ent, pev_flags, FL_KILLME);
		}
	}

	for (new i; i < sizeof(AMMO_CLASSES); i++) {
		new ent;
		while ((ent = find_ent_by_class(ent, AMMO_CLASSES[i]))) {
			set_pev(ent, pev_flags, FL_KILLME);
		}
	}

	for (new i; i < sizeof(ITEM_CLASSES); i++) {
		new ent;
		while ((ent = find_ent_by_class(ent, ITEM_CLASSES[i]))) {
			set_pev(ent, pev_flags, FL_KILLME);
		}
	}
}

stock DisableChargers() {
	new ent;
	while ((ent = find_ent_by_class(ent, "func_recharge"))) {
		new ptr = pev(ent, pev_model);
		remove_entity(ent);
		
		new ent2 = create_entity("func_wall");
		set_pev_string(ent2, pev_model, ptr);
		DispatchSpawn(ent2);
	}

	ent = 0;
	while ((ent = find_ent_by_class(ent, "func_healthcharger"))) {
		new ptr = pev(ent, pev_model);
		remove_entity(ent);
		
		new ent2 = create_entity("func_wall");
		set_pev_string(ent2, pev_model, ptr);
		DispatchSpawn(ent2);
	}
}