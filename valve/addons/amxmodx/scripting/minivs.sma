#include <amxmisc>
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hl_player_models_api>
#include <hlstocks>
#include <xs>
#include <msgstocks>
#include <hl_wpnmod>
#include <minivs>

#define PLUGIN  "MiniVS"
#define VERSION "0.3"
#define AUTHOR  "rtxA"

#pragma semicolon 1

#define IsPlayer(%0) (%0 > 0 && %0 <= MaxClients)

// i raised the limit of 4 corpses by default
// to make sure there are enough corpses to drink blood
#define MAX_BODY_CORPSES 8

// --------------------------------- CLASSES ---------------------------------
#define VAMP_HIGHJUMP_HEIGHT 550.0
#define VAMP_MAXSPEED 320.0

#define VAMP_EDGAR_WAKEUP_HEALTH 20
#define VAMP_EDGAR_KNOCKOUT_DURATION 5.0

#define VAMP_LOUIS_WAKEUP_HEALTH 25
#define VAMP_LOUIS_KNOCKOUT_DURATION 4.0

#define VAMP_NINA_WAKEUP_HEALTH 30
#define VAMP_NINA_KNOCKOUT_DURATION 3.0

#define SLAYER_MAXSPEED 270.0

// --------------------------------- Sounds ---------------------------------
new const SND_PLR_FALLPAIN1[] 		= "player/pl_fallpain1.wav";

new const SND_INTRO[]               = "minivs/items/intro1.wav";
new const SND_INTERMISSION[]        = "minivs/items/intermission.wav";

new const SND_ROUND_HUMANSWINS[]    = "minivs/items/messiah.wav";
new const SND_ROUND_VAMPSWIN[]      = "minivs/items/toccata.wav";
new const SND_ROUND_DRAW[]          = "minivs/items/draw.wav";

new const SND_VAMP_DRINKING[]       = "minivs/items/feed.wav";
new const SND_VAMP_LAUGH_MALE[]     = "minivs/player/evilaugh.wav";
new const SND_VAMP_LAUGH_FEMALE[]   = "minivs/player/ninalaugh.wav";
new const SND_VAMP_LONGJUMP[]       = "minivs/player/flap-long2.wav";
new const SND_VAMP_HIGHJUMP[]       = "minivs/player/flap-short1.wav";
new const SND_VAMP_DYING_MALE[]     = "minivs/player/vampsc.wav";
new const SND_VAMP_DYING_FEMALE[]   = "minivs/player/vampscf.wav";

new const SND_VAMP_ATTACK1[]		= "minivs/weapons/vattack1.wav";
new const SND_VAMP_ATTACK2[]		= "minivs/weapons/vattack2.wav";
new const SND_VAMP_ATTACK3[]		= "minivs/weapons/vattack3.wav";

new const SND_DECAPITATE1[] 		= "minivs/player/head1.wav";
new const SND_DECAPITATE2[] 		= "minivs/player/head2.wav";

// --------------------------------- Models ---------------------------------

new const MDL_VAMP_EDGAR[]      = "models/player/edgar-hl/edgar-hl.mdl";
new const MDL_VAMP_LOUIS[]      = "models/player/louis-hl/louis-hl.mdl";
new const MDL_VAMP_NINA[]       = "models/player/nina-hl/nina-hl.mdl";
new const MDL_HUMAN_FATHER[]    = "models/player/fatherd-hl/fatherd-hl.mdl";
new const MDL_HUMAN_MOLLY[]     = "models/player/molly-hl/molly-hl.mdl";
new const MDL_HUMAN_EIGHTBALL[] = "models/player/eightball-hl/eightball-hl.mdl";

// --------------------------------- Sprites ---------------------------------
new g_SprBloodDrop;
new g_SprBloodSpray;

#define TEAMNAME_SLAYER "SLAYER"
#define TEAMNAME_VAMPIRE "VAMPIRE"

enum {
	TEAM_NONE = 0,
	TEAM_VAMPIRE = 2, // red color
	TEAM_SLAYER = 4 // green color
};

enum {
	CLASS_NOCLASS = 0,
	CLASS_VAMP_LOUIS,
	CLASS_VAMP_EDGAR,
	CLASS_VAMP_NINA,
	CLASS_HUMAN_FATHER,
	CLASS_HUMAN_EIGHTBALL,
	CLASS_HUMAN_MOLLY
};

#define SCORE_POINTS 1

enum (+= 100) {
	TASK_ROUNDCOUNTDOWN = 1959,
	TASK_ROUNDSTART,
	TASK_PUTINSERVER,
	TASK_DISPLAYTIMER,
	TASK_PLAYERTRAIL,
	TASK_SENDTOSPEC
} 

// gamemode
new g_DisableDeathPenalty;
new g_RoundTime;
new g_RoundStarted;
new g_RoundWinner;
new g_TeamScore[HL_MAX_TEAMS];

// global variables for players
new bool:g_SendToSpecVictim[MAX_PLAYERS + 1];
new g_FallSoundPlayed[MAX_PLAYERS + 1];

// vampire data
new g_WakeUpHealth[MAX_PLAYERS + 1];
new g_HasToBeKnockOut[MAX_PLAYERS + 1];
new bool:g_IsKnockOut[MAX_PLAYERS + 1];
new Float:g_KnockOutTime[MAX_PLAYERS + 1];
new Float:g_KnockOutEndTime[MAX_PLAYERS + 1];
new Float:g_NextDrinkSound[MAX_PLAYERS + 1];
new g_DrinkingBloodEnt[MAX_PLAYERS + 1];

// hud handlers
new g_ScoreHudSync;

// cvars
new g_pCvarRoundTime;

// model index humans
new stock g_MdlFather;
new stock g_MdlMolly;
new stock g_MdlEightBall;

public plugin_precache() {
	g_MdlFather = precache_model(MDL_HUMAN_FATHER);
	g_MdlMolly = precache_model(MDL_HUMAN_MOLLY);
	g_MdlEightBall = precache_model(MDL_HUMAN_EIGHTBALL);

	precache_model(MDL_VAMP_EDGAR);
	precache_model(MDL_VAMP_LOUIS);
	precache_model(MDL_VAMP_NINA);

	precache_sound(SND_PLR_FALLPAIN1);

	precache_sound(SND_ROUND_HUMANSWINS);
	precache_sound(SND_ROUND_VAMPSWIN);
	precache_sound(SND_ROUND_DRAW);
	precache_sound(SND_INTERMISSION);
	precache_sound(SND_INTRO);

	precache_sound(SND_VAMP_DRINKING);
	precache_sound(SND_VAMP_LAUGH_MALE);
	precache_sound(SND_VAMP_LAUGH_FEMALE);
	precache_sound(SND_VAMP_LONGJUMP);
	precache_sound(SND_VAMP_HIGHJUMP);
	precache_sound(SND_VAMP_DYING_MALE);
	precache_sound(SND_VAMP_DYING_FEMALE);

	precache_sound(SND_VAMP_ATTACK1);
	precache_sound(SND_VAMP_ATTACK2);
	precache_sound(SND_VAMP_ATTACK3);

	precache_sound(SND_DECAPITATE1);
	precache_sound(SND_DECAPITATE2);

	g_SprBloodDrop = precache_model("sprites/blood.spr");
	g_SprBloodSpray = precache_model("sprites/bloodspray.spr");

	g_pCvarRoundTime = create_cvar("mp_roundtime", "180");
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_dictionary("minivs.txt");

	register_forward(FM_GetGameDescription, "OnGetGameDescription");
	
	register_clcmd("say !team", "CmdTeamMenu");
	register_clcmd("say !class", "CmdClassMenu");

	// player hooks
	RegisterHamPlayer(Ham_Spawn, "OnPlayerSpawn_Pre");
	RegisterHamPlayer(Ham_Spawn, "OnPlayerSpawn_Post", true);
	RegisterHamPlayer(Ham_TakeDamage, "OnPlayerTakeDamage_Pre");
	RegisterHamPlayer(Ham_TakeDamage, "OnPlayerTakeDamage_Post", true);
	RegisterHamPlayer(Ham_Killed, "OnPlayerKilled_Post", true);
	RegisterHamPlayer(Ham_Player_Jump, "OnPlayerJump_Post", true);
	
	// vampire hook
	vs_claw_special_attack("OnClawSpecialAttack");
	
	register_clcmd("spectate", "CmdSpectate");
	register_clcmd("drop", "CmdDrop");

	RegisterHam(Ham_Spawn, "weaponbox", "OnWeaponBox_Spawn", .Post = true);
	register_touch("weaponbox", "worldspawn", "OnWeaponBox_OnGround");
	register_forward(FM_PlayerPreThink, "OnPlayerPreThink");

	// hook intermission mode
	register_event_ex("30", "EventIntermissionMode", RegisterEvent_Global);
	
	g_ScoreHudSync = CreateHudSyncObj();

	// body corpses related
	SetBodyCorpsesLimit(MAX_BODY_CORPSES);
	SetPevAllCorpses(pev_nextthink, get_gametime() + 0.1);
	register_think("bodyque", "OnCorpse_Think");

	RoundStart();
}

// crashea cuando se desconecta despues del delay
public OnClawSpecialAttack(iItem, iPlayer) {
	if (vs_claw_get_power_timeleft(iItem) == 25) {
		SetSpecialPower(iPlayer, false);
	} else if (vs_claw_get_power_timeleft(iItem) == 30) {
		SetSpecialPower(iPlayer);
	}
}

SetSpecialPower(id, value = true) {
	if (value)
		set_user_rendering(id, kRenderFxNone, .render = kRenderTransTexture, .amount = 50);
	else
		set_user_rendering(id, kRenderFxNone, .render = kRenderNormal);
}

public OnPlayerPreThink(id) {
	// play body corpse fall sound
	if (!g_FallSoundPlayed[id]) {
		if (pev(id, pev_deadflag) >= DEAD_DYING && pev(id, pev_movetype) != MOVETYPE_NONE && pev(id, pev_flags) & FL_ONGROUND) {
			emit_sound(id, CHAN_STATIC, SND_PLR_FALLPAIN1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			g_FallSoundPlayed[id] = true;
		}
	}

	// hack: fix player creating multiple corpses when trying to respawn
	if (g_SendToSpecVictim[id] && !hl_get_user_spectator(id)) {
		set_ent_data_float(id, "CBasePlayer", "m_fDeadTime", get_gametime());
		set_pev(id, pev_button, 0);
		set_pev(id, pev_oldbuttons, 0);
	}

	if (g_IsKnockOut[id]) {
		// hack to avoid player create a deadcorpse
		set_ent_data_float(id, "CBasePlayer", "m_fDeadTime", get_gametime());
		set_pev(id, pev_button, 0);
		set_pev(id, pev_oldbuttons, 0);

		if (g_KnockOutEndTime[id] < get_gametime()) {
			VS_WakeUp(id);
		}
	}

	return FMRES_IGNORED;
}

public EventIntermissionMode() {
	// reproduce intermission music
	PlaySound(0, SND_INTERMISSION);
}

public CmdDrop(id) {
	return PLUGIN_HANDLED;
}

public OnWeaponBox_Spawn(ent) {
	set_pev(ent, pev_effects, EF_NODRAW);
	set_pev(ent, pev_solid, SOLID_NOT);
}

public OnWeaponBox_OnGround(ent) {
	WeaponBox_Kill(ent);
}

public OnCorpse_Think(this) {
	set_pev(this, pev_nextthink, get_gametime() + 0.1);

	new modelindex = pev(this, pev_modelindex);
	// only you can drin blood humans corpses
	if (modelindex != g_MdlFather && modelindex != g_MdlMolly && modelindex != g_MdlEightBall) {
		return;
	}

	new Float:origin[3];
	pev(this, pev_origin, origin);

	new ent;
	while ((ent = find_ent_in_sphere(ent, origin, 16.0))) {
		if (!is_user_connected(ent))
			continue;

		if (pev_valid(ent) != 2)
			continue;
		
		new playerPos[3], bodyPos[3];

		// get player aim origin and body origin
		get_user_origin(ent, playerPos, Origin_Eyes);
		{
			new Float:fBodyPos[3];
			pev(this, pev_origin, fBodyPos);		
			FVecIVec(fBodyPos, bodyPos);
		}

		// check if player is close enough to drink of the corpse
		// todo: i should check if player is facing the corpse (KISS)
		if (get_distance(playerPos, bodyPos) > 25)
			continue;

		// now check he's pressing use to drink blood
		if (pev(ent, pev_button) & IN_USE) {
			OnCorpse_Use(this, ent);
		} else {
			g_DrinkingBloodEnt[ent] = 0;
		}
	}				
}

// player is always connected and has valid pev data
public OnCorpse_Use(this, player) {
	if (GetPlayerTeam(player) != TEAM_VAMPIRE)
		return;

	// make sure player drinks from only one corpse
	// (solves case where two corpses are too close to each other and you can drink from both)
	if (g_DrinkingBloodEnt[player] == 0) {
		g_DrinkingBloodEnt[player] = this;
	}

	if (g_DrinkingBloodEnt[player] != this)
		return;

	new origin[3];

	// get player origin
	{
		new Float:fOrigin[3];
		pev(this, pev_origin, fOrigin);
		FVecIVec(fOrigin, origin);
	}

	if (g_NextDrinkSound[player] < get_gametime()) {
		// make the blood appear in the floor
		origin[2] -= 28;
		te_display_falling_sprite(origin, g_SprBloodSpray, g_SprBloodDrop, BLOOD_COLOR_RED);
		te_display_falling_sprite(origin, g_SprBloodSpray, g_SprBloodDrop, BLOOD_COLOR_RED, .scale = 15); // bright red
		
		emit_sound(player, CHAN_ITEM, SND_VAMP_DRINKING, 1.0, ATTN_NORM, 0, PITCH_NORM);
		g_NextDrinkSound[player] = get_gametime() + 0.45;	
	}

	ExecuteHam(Ham_TakeHealth, player, 0.5, DMG_GENERIC);
}

public VS_KnockOut(id) {
	g_FallSoundPlayed[id] = false;
	g_KnockOutEndTime[id] = get_gametime() + g_KnockOutTime[id];
	g_IsKnockOut[id] = true;

	hl_user_silentkill(id);

	set_ent_data(id, "CBasePlayer", "m_iHideHUD", HIDEHUD_WEAPONS | HIDEHUD_HEALTH);
}

public VS_WakeUp(id) {
	hl_set_user_health(id, VAMP_EDGAR_WAKEUP_HEALTH);

	// restore
	set_pev(id, pev_deadflag, DEAD_NO);
	set_pev(id, pev_solid, SOLID_SLIDEBOX);
	set_pev(id, pev_effects, pev(id, pev_effects) & ~EF_NODRAW);

	// set normal eye position again
	new Float:viewofs[3];
	pev(id, pev_view_ofs, viewofs);
	if (pev(id, pev_flags) & FL_DUCKING)
		viewofs[2] = 12.0;
	else 
		viewofs[2] = 28.0;
	set_pev(id, pev_view_ofs, viewofs);

	wpnmod_give_item(id, "weapon_vsclaw");
	set_ent_data(id, "CBasePlayer", "m_iHideHUD", 0);

	// avoid claw WeapPickUp message by resetting hud
	set_ent_data(id, "CBasePlayer", "m_fInitHUD", 1);

	// hide claw from weapons slots
	set_pev(id, pev_weapons, 1 << HLW_SUIT);

	// emit laugh sound
	if (GetPlayerClass(id) != CLASS_VAMP_NINA)
		emit_sound(id, CHAN_STATIC, SND_VAMP_LAUGH_MALE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
	else
		emit_sound(id, CHAN_STATIC, SND_VAMP_LAUGH_FEMALE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

	client_print(0, print_chat, "%l", "NOTIF_RESURRECTED", id);

	// remove corpse when he wakeups
	g_IsKnockOut[id] = false;
}

// only way to fix  prediction clientside jump is to use another commnad, example +superjump
public OnPlayerJump_Post(id) {
	if (GetPlayerTeam(id) != TEAM_VAMPIRE)
		return;

	if (!is_user_alive(id)) // don't allow to jump "dead" players
		return;

	if (pev(id, pev_flags) & FL_ONGROUND) {
		static Float:velocity[3];
		pev(id, pev_velocity, velocity);

		// long jump (no need to check if he has lj, vampire always has this ability)
		// thanks ConnorMcLeod for code to detect LJ
		// bug: +ljump from BHL does a LJ jump without the animation sequence, how can i fix this?
		if (get_ent_data(id, "CBaseMonster", "m_IdealActivity") == 8 && pev(id, pev_frame) == 0) {
			emit_sound(id, CHAN_BODY, SND_VAMP_LONGJUMP, 1.0, ATTN_NORM, 0, PITCH_NORM);
		// high jump
		} else if (!(pev(id, pev_oldbuttons) & IN_DUCK)) {
			new Float:velocity[3];
			pev(id, pev_velocity, velocity);
			velocity[2] += VAMP_HIGHJUMP_HEIGHT;
			set_pev(id, pev_velocity, velocity);
			emit_sound(id, CHAN_BODY, SND_VAMP_HIGHJUMP, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

// Game mode name that should be displayed in server browser
public OnGetGameDescription() {
	forward_return(FMV_STRING, PLUGIN + " " + VERSION);
	return FMRES_SUPERCEDE;
}

/* Player functions
 */

public OnPlayerSpawn_Pre(id) {
	// used in dead players
	if (g_SendToSpecVictim[id]) {
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public OnPlayerSpawn_Post(id) {
	g_FallSoundPlayed[id] = false;
	g_HasToBeKnockOut[id] = false;

	// player is trying to spawn and is still dead, ignore...
	if (!is_user_alive(id))
		return;
		
 	if (GetPlayerTeam(id) != TEAM_NONE && GetPlayerClass(id) != CLASS_NOCLASS) {
		SetClassAtribbutes(id);
	}
	
}

public OnPlayerTakeDamage_Pre(victim, inflictor, attacker, Float:damage, damagetype) {
	new victimTeam = GetPlayerTeam(victim);
	new attackerTeam = GetPlayerTeam(attacker);

	if (victimTeam == TEAM_VAMPIRE) {
		// vampires don't suffer fall damage (still i need to block fall sound)
		if (!attacker && damagetype & DMG_FALL)
			return HAM_SUPERCEDE;
	}

	new classname[32];

	if (victimTeam == TEAM_SLAYER && attackerTeam == TEAM_VAMPIRE) {
		new wpn = hl_get_user_weapon_ent(victim);
		if (wpn != FM_NULLENT) {
			pev(wpn, pev_classname, classname, charsmax(classname));
			// slayer is using his cross, block any damage
			if (equal(classname, "weapon_vsstake") && vs_stake_is_powerup_on(wpn)) {
				return HAM_SUPERCEDE;
			}
		}

		// play decapitation sound, even if it's not implemented
		if (damage >= hl_get_user_health(victim) && get_ent_data(victim, "CBaseMonster", "m_LastHitGroup") == HIT_HEAD) {
			switch (random_num(1, 2)) {
				case 1: emit_sound(attacker, CHAN_STATIC, SND_DECAPITATE1, 1.0, ATTN_NORM, 0, PITCH_NORM);
				case 2: emit_sound(attacker, CHAN_STATIC, SND_DECAPITATE2, 1.0, ATTN_NORM, 0, PITCH_NORM);
			}
			return HAM_IGNORED;
		}
	}

	if (victimTeam == TEAM_VAMPIRE && attackerTeam == TEAM_SLAYER) {
		// slayer has done enough damage, knockdown vampire
		if (damage >= hl_get_user_health(victim) && !g_IsKnockOut[victim]) {
			// hack: we don't block damage so the knockback can work
			// anyway, we are going to knock him down
			set_pev(victim, pev_health, 10000.0);
			g_HasToBeKnockOut[victim] = true;
			return HAM_IGNORED;
		}

		// vampire is down, time to kill him
		if (g_IsKnockOut[victim]) {
			new wpn = hl_get_user_weapon_ent(attacker);

			// don't know why sometimes this fails...
			if (wpn == FM_NULLENT)
				return HAM_SUPERCEDE;

			pev(wpn, pev_classname, classname, charsmax(classname));
			
			if (!equal(classname, "weapon_vsstake"))
				return HAM_SUPERCEDE;

			client_print(0, print_chat, "%l", "NOTIF_STAKED", attacker, victim);

			// don't let player kill the vampire at least one second later
			if (g_KnockOutEndTime[victim] - get_gametime() < 1.0) {
				return HAM_SUPERCEDE;
			}

			// kill vampire
			set_pev(victim, pev_health, 1);
			set_pev(victim, pev_deadflag, DEAD_NO);
			SetHamParamFloat(4, 500.0);
			SetHamParamInteger(5, DMG_ALWAYSGIB);
			g_IsKnockOut[victim] = false;
		}
	}

	return HAM_IGNORED;
}

public OnPlayerTakeDamage_Post(victim, inflictor, attacker, Float:damage, damagetype) {
	new victimTeam = GetPlayerTeam(victim);
	new attackerTeam = GetPlayerTeam(attacker);

	if (victimTeam == TEAM_VAMPIRE && attackerTeam == TEAM_SLAYER) {
		// slayer has done enough damage, knockdown vampire
		if (g_HasToBeKnockOut[victim] && !g_IsKnockOut[victim]) {
			VS_KnockOut(victim);
			client_print(0, print_chat, "%l", "NOTIF_KNOCKOUT", attacker, victim);
			g_HasToBeKnockOut[victim] = false;
		}
	}
}

public OnPlayerKilled_Post(victim, attacker, shouldGib) {
	new victimTeam = GetPlayerTeam(victim);
	new attackerTeam = GetPlayerTeam(attacker);

	// if there aren't enough players, ignore score of this round
	if (g_DisableDeathPenalty) {
		hl_set_user_deaths(victim, hl_get_user_deaths(victim) - 1);
		if (IsPlayer(attacker)) {
			if (victimTeam != attackerTeam && victim != attacker)
				hl_set_user_frags(attacker, hl_get_user_frags(attacker) - 1);
			else
				hl_set_user_frags(attacker, hl_get_user_frags(attacker) + 1);
		}
	}

	if (g_RoundStarted) {
		if (g_IsKnockOut[victim])
			return;

		// send victim to spec
		g_SendToSpecVictim[victim] = true;
		set_task(3.0, "SendToSpec", TASK_SENDTOSPEC + victim);

		if (!RoundNeedsToContinue())
			RoundEnd();
	}


	if (victimTeam == TEAM_SLAYER && attackerTeam == TEAM_VAMPIRE) {
		switch (random_num(1, 3)) {
			case 1: emit_sound(attacker, CHAN_STATIC, SND_VAMP_ATTACK1, 1.0, ATTN_NORM, 0, PITCH_NORM);
			case 2: emit_sound(attacker, CHAN_STATIC, SND_VAMP_ATTACK2, 1.0, ATTN_NORM, 0, PITCH_NORM);
			case 3: emit_sound(attacker, CHAN_STATIC, SND_VAMP_ATTACK3, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	// note: vampire simulates being dead when is knocked down
	if (victimTeam == TEAM_VAMPIRE) {
		SetSpecialPower(victim, false);

		// play death sound
		if (!g_IsKnockOut[victim]) {
			if (GetPlayerClass(victim) != CLASS_VAMP_NINA)
				emit_sound(victim, CHAN_STATIC, SND_VAMP_DYING_MALE, 1.0, ATTN_NORM, 0, PITCH_NORM);
			else
				emit_sound(victim, CHAN_STATIC, SND_VAMP_DYING_FEMALE, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}
}

public SendToSpec(taskid) {
	new id = taskid - TASK_SENDTOSPEC;

	if (g_SendToSpecVictim[id]) {
		// hack: create player corpse manually
		set_ent_data_float(id, "CBasePlayer", "m_fDeadTime", get_gametime());
		set_pev(id, pev_button, IN_ATTACK);
		set_pev(id, pev_oldbuttons, IN_ATTACK);

		// dead player has already set CBasePlayer::PlayerDeathThink()
		call_think(id);

		// block spawn again
		set_pev(id, pev_button, 0);
		set_pev(id, pev_oldbuttons, 0);

		// now that the corpse has been created, we can finnally send the player to spec
		hl_set_user_spectator(id, true);
	}
}

stock RemoveAllPlayerTasks(taskid) {
	for (new i = 1; i <= MaxClients; i++) {
		remove_task(taskid + i);
	}
}

public TaskPutInServer(taskid) {
	new id = taskid - TASK_PUTINSERVER;

	if (!is_user_connected(id))
		return;

	new vamp[HL_TEAMNAME_LENGTH];
	new slayer[HL_TEAMNAME_LENGTH];

	// Get translated team name
	SetGlobalTransTarget(id);
	formatex(vamp, charsmax(vamp), "%l", "TITLE_VAMPIRE");
	formatex(slayer, charsmax(slayer), "%l", "TITLE_SLAYER");

	// Stylize it to uppercase
	strtoupper(vamp);
	strtoupper(slayer);

	hl_set_teamnames(id, "", vamp, "", slayer);
	hl_set_teamscore("slayer", g_TeamScore[TEAM_SLAYER - 1], id);
	hl_set_teamscore("vampire", g_TeamScore[TEAM_VAMPIRE - 1], id);

	// increase display time for center messages (default is too low, player can barely see them)
	client_cmd(id, "scr_centertime 4");

	DisplayTeamMenu(id);

	SpeakSnd(id, SND_INTRO);

	if (is_user_bot(id)) {
		ChangePlayerTeam(id, id % 2 ? TEAM_SLAYER : TEAM_VAMPIRE);
		SetPlayerTeam(id, id % 2 ? TEAM_SLAYER : TEAM_VAMPIRE);
		SetPlayerClass(id, id % 2 ? random_num(CLASS_HUMAN_FATHER, CLASS_HUMAN_EIGHTBALL) : random_num(CLASS_VAMP_LOUIS, CLASS_VAMP_NINA));
		if (g_RoundStarted && !RoundNeedsToContinue())
			RoundEnd();
	}
}

public client_putinserver(id) {
	set_task(0.1, "TaskPutInServer", TASK_PUTINSERVER + id);
}

public client_disconnected(id) {
	// todas las ids
	remove_task(TASK_SENDTOSPEC + id);

	// player that abort connection hasn't pev data
	if (!pev_valid(id)) {
		SetPlayerTeam(id, TEAM_NONE);
		SetPlayerClass(id, CLASS_NOCLASS);
	}

	g_KnockOutTime[id] = 0.0;
}

public client_remove(id) {
	if (g_RoundStarted) {
		if (!RoundNeedsToContinue()) {
			RoundEnd();
		}
	}
}

/* =============================== */

// peisno en dos ocpiones, hacer stocks para contar jugadores de la ronda y nada mas que eso
// las natives no fueron pensados para rondas, 
stock vs_get_players(players[MAX_PLAYERS], &numPlayers) {
	for (new i = 1; i <= MaxClients; i++) {
		if (!is_user_connected(i))
			continue;
		else if (is_user_hltv(i))
			continue;
		else if (GetPlayerTeam(i) == TEAM_NONE || GetPlayerClass(i) == CLASS_NOCLASS)
			continue;
		players[numPlayers++] = i;
	}
}

stock vs_get_teamnum(teamid) {
	new players[MAX_PLAYERS], numPlayers;
	vs_get_players(players, numPlayers);

	new num, plr;
	for (new i; i < numPlayers; i++) {
		plr = players[i];
		if (GetPlayerTeam(plr) == teamid && GetPlayerClass(plr) != CLASS_NOCLASS)
			num++;
	}

	return num;
}

stock vs_get_playersnum() {
	new players[32], numPlayers;
	vs_get_players(players, numPlayers); 
	return numPlayers;
}

stock vs_get_team_alives(teamid) {
	new players[MAX_PLAYERS], numPlayers;
	vs_get_players(players, numPlayers);

	new num, plr;
	for (new i; i < numPlayers; i++) {
		plr = players[i];
		if (hl_get_user_team(plr) == teamid && (is_user_alive(plr) || g_IsKnockOut[plr]))
			num++;
	}

	return num;
}

public RoundStart() {
	// añadir funcion para reiniciar el limite de rondas cada vez q no haya ningun jugador
	
	if (g_RoundStarted)
		return;

	if (vs_get_playersnum() < 1) {
		set_task(1.0, "RoundStart", TASK_ROUNDSTART);
		return;
	}

	g_DisableDeathPenalty = false;

	// ignore score of this round if there aren't enough players in both teams
	if (vs_get_teamnum(TEAM_SLAYER) < 1 || vs_get_teamnum(TEAM_VAMPIRE) < 1) {
		g_DisableDeathPenalty = true;
	}

	// get players with team and class already set
	new players[MAX_PLAYERS], numPlayers;
	vs_get_players(players, numPlayers);

	new plr;
	for (new i; i < numPlayers; i++) {
		plr = players[i];
		// new round, reset some stuff
		g_SendToSpecVictim[plr] = false;
		SetSpecialPower(plr, false);

		if (hl_get_user_spectator(plr))
			hl_set_user_spectator(plr, false);
		else
			hl_user_spawn(plr);
	}

	client_print(0, print_center, "Round Started");

	g_RoundStarted = true;

	g_RoundTime = get_pcvar_num(g_pCvarRoundTime);
	StartRoundTimer();

	// remove any screen fade
	fade_user_screen(0, _, _, ScreenFade_StayOut, 0, 0, 0, 0);
}

public bool:RoundNeedsToContinue() {
	new humans = vs_get_team_alives(TEAM_SLAYER);
	new vamps = vs_get_team_alives(TEAM_VAMPIRE);

	if (humans > 0 && vamps > 0)
		return true;

	// the score of this round is ignored
	if (g_DisableDeathPenalty) {
		g_RoundWinner = TEAM_NONE;
		return false;
	}

	// vampires win
	if (vamps > humans) {
		g_RoundWinner = TEAM_VAMPIRE;
	// humans win
	} else if (humans > vamps) {
		g_RoundWinner = TEAM_SLAYER;
	// draw
	} else {
		g_RoundWinner = TEAM_NONE;
	}

	return false;
}

public RoundEnd() {
	if (!g_RoundStarted)
		return;

	g_RoundStarted = false;

	// show team winner
	switch(g_RoundWinner) {
		case TEAM_SLAYER: {
			PlaySound(0, SND_ROUND_HUMANSWINS);
			g_TeamScore[TEAM_SLAYER - 1] += SCORE_POINTS;
			client_print(0, print_center, "%l^n^n%l : %d %l : %d", "ROUND_SLAYERSWIN", "TITLE_SLAYER", g_TeamScore[TEAM_SLAYER - 1], "TITLE_VAMPIRE", g_TeamScore[TEAM_VAMPIRE - 1]);
		}
		case TEAM_VAMPIRE: {
			PlaySound(0, SND_ROUND_VAMPSWIN);
			g_TeamScore[TEAM_VAMPIRE - 1] += SCORE_POINTS;
			client_print(0, print_center, "%l^n^n%l : %d %l : %d", "ROUND_VAMPIRESWIN", "TITLE_SLAYER", g_TeamScore[TEAM_SLAYER - 1], "TITLE_VAMPIRE", g_TeamScore[TEAM_VAMPIRE - 1]);
		}
		case TEAM_NONE: {
			client_print(0, print_center, "%l^n^n%l : %d %l : %d", "ROUND_DRAW", "TITLE_SLAYER", g_TeamScore[TEAM_SLAYER - 1], "TITLE_VAMPIRE", g_TeamScore[TEAM_VAMPIRE - 1]);
			PlaySound(0, SND_ROUND_DRAW);
		} 
	}
	hl_set_teamscore(TEAMNAME_SLAYER, g_TeamScore[TEAM_SLAYER - 1]);
	hl_set_teamscore(TEAMNAME_VAMPIRE, g_TeamScore[TEAM_VAMPIRE - 1]);

	// dark the screen a little
	fade_user_screen(0, _, _, ScreenFade_StayOut, 0, 0, 0, 150);

	set_task(5.0, "RoundStart", TASK_ROUNDSTART);
}

// get player team, the system breaks if i use hl_get_user_team(id) because in spectator he has no team... we need to check thtat internally
// if player already select blue team

// also, games need to be 2v2 at least, one goalkeeper and one player of any class in both teams
// if less than that, then we don't use autoteambalance in this case, and other thing, if player enters and he didn't slect team for 15 seconds, thed do that automacally
// but we better dont do that and we exepect player to select, so an afk player is trash

// ALso, if players enters, we will be alive, we should block any commands 0.1 seconds later

public CmdSpectate(id) {
	if (hl_get_user_spectator(id)) {
		// Don't let spectators join the round if has already started
		if (g_RoundStarted)
			return PLUGIN_HANDLED;

		// Don't let spectators join the game until they have selected team and class
		if (GetPlayerTeam(id) == TEAM_NONE || GetPlayerClass(id) == CLASS_NOCLASS)
			return PLUGIN_HANDLED;

		//hl_set_player_team(id, GetPlayerTeam(id));
		hl_user_spawn(id);
	} else {
		// don't reset his team when he's send to spec only because he die
		if (!g_SendToSpecVictim[id]) {
			SetPlayerTeam(id, TEAM_NONE);
			SetPlayerClass(id, CLASS_NOCLASS);
			DisplayTeamMenu(id);
		}
	}

	if (g_RoundStarted) {
		if (!RoundNeedsToContinue()) {
			RoundEnd();
		}
	}
	return PLUGIN_CONTINUE;
}

/* ===========================
*/

/* Display messages
*/

public TaskDisplayTimer(taskid) {
	DisplayTimer();
}

// maybe change colors for 5 seconds when a goal is made
public DisplayTimer() {
	set_hudmessage(230, 64, 64, -1.0, 0.01, 2, 0.01, 600.0, 0.05, 0.01);
	ShowSyncHudMsg(0, g_ScoreHudSync, "%d:%02d^nVampire-Slayer", g_RoundTime / 60, g_RoundTime % 60);
}

/* Team and Class Menu
*/

public CmdTeamMenu(id) {
	DisplayTeamMenu(id);
	return PLUGIN_HANDLED;
}

public DisplayTeamMenu(id) {
	new menu = menu_create(fmt("%L", id, "MENU_TEAM"), "HandlerTeamMenu");
	menu_additem(menu, fmt("%L", id, "TITLE_SLAYER"));
	menu_additem(menu, fmt("%L", id, "TITLE_VAMPIRE"));
	menu_setprop(menu, MPROP_NOCOLORS, true);
	//menu_addblank(menu, false);
	//menu_additem(menu, fmt("%l", "FB_RANDOM"));

	menu_display(id, menu);
}

public HandlerTeamMenu(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	switch (item) {
		case 0: {
			ChangePlayerTeam(id, TEAM_SLAYER, true);
			//client_print(0, print_chat, "* %n has changed to team 'SLAYER'", id);
			SetPlayerTeam(id, TEAM_SLAYER);
		}
		case 1: {
			ChangePlayerTeam(id, TEAM_VAMPIRE, true);
			//client_print(0, print_chat, "* %n has changed to team 'VAMPIRE'", id);
			SetPlayerTeam(id, TEAM_VAMPIRE);
		}
	}

	SetPlayerClass(id, CLASS_NOCLASS);

	menu_destroy(menu);

	// si esta en espectador y sin clase, luego de seleccionar equipo
	DisplayClassMenu(id);

	return PLUGIN_HANDLED;
}

// fixed, now score isn't altered
stock hl_user_silentkill(id) {
	new deaths = hl_get_user_deaths(id);
	user_silentkill(id);
	hl_set_user_deaths(id, deaths);	
}

public CmdClassMenu(id) {
	if (GetPlayerTeam(id) == TEAM_NONE) {
		DisplayTeamMenu(id);
		return PLUGIN_HANDLED;
	} 

	DisplayClassMenu(id);
	
	return PLUGIN_HANDLED;
}

public DisplayClassMenu(id) {
	new menu = menu_create(fmt("%l", "MENU_CLASS"), "HandlerClassMenu");
	if (GetPlayerTeam(id) == TEAM_SLAYER) {
		menu_additem(menu, fmt("%L", id, "CLASS_HUMAN_FATHER"), fmt("%d", CLASS_HUMAN_FATHER));
		menu_additem(menu, fmt("%L", id, "CLASS_HUMAN_MOLLY"), fmt("%d", CLASS_HUMAN_MOLLY));
		menu_additem(menu, fmt("%L", id, "CLASS_HUMAN_EIGHTBALL"), fmt("%d", CLASS_HUMAN_EIGHTBALL));
	} else if (GetPlayerTeam(id) == TEAM_VAMPIRE) {
		menu_additem(menu, fmt("%L", id, "CLASS_VAMP_LOUIS"), fmt("%d", CLASS_VAMP_LOUIS));
		menu_additem(menu, fmt("%L", id, "CLASS_VAMP_EDGAR"), fmt("%d", CLASS_VAMP_EDGAR));
		menu_additem(menu, fmt("%L", id, "CLASS_VAMP_NINA"), fmt("%d", CLASS_VAMP_NINA));
	}
	menu_setprop(menu, MPROP_NOCOLORS, true);
	menu_display(id, menu);
}

// faltan los chequeso den disconect, resetear todo cuando se vaya, o cuandos emande restart, el primeo  sea
public HandlerClassMenu(id, menu, item) {
	if (item == MENU_EXIT) {
		menu_destroy(menu);
		return PLUGIN_HANDLED;
	}

	new info[3];
	menu_item_getinfo(menu, item, _, info, charsmax(info));

	if (is_user_alive(id))
		hl_user_silentkill(id);

	new class = str_to_num(info);
	SetPlayerClass(id, class);

	// check if round needs to continue everytime we change of class
	if (!g_RoundStarted && !RoundNeedsToContinue()) {
		RoundEnd();
	}

	// block intro sound
	SpeakSnd(id, "_period");

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}
/* ====================
*/

/* Get and set functions
*/
public GetPlayerTeam(id) {
	return pev(id, pev_iuser4);
}

// one things is player model (hl_get_user_[team/model]), and other thing his team (none)
public SetPlayerTeam(id, teamid) {
	set_pev(id, pev_iuser4, teamid);
}

public SetPlayerClass(id, class) {
	set_pev(id, pev_playerclass, class);
}

public GetPlayerClass(id) {
	return pev(id, pev_playerclass);
}

public AddPointsToScore(team, value) {
	g_TeamScore[team - 1] += value;
}

public GetScorePoints(team) {
	return g_TeamScore[team - 1];
}

/* ===================
*/

/* Player Classes
*/

public SetClassAtribbutes(id) {
	switch (GetPlayerClass(id)) {
		case CLASS_VAMP_EDGAR: SetClassEdgar(id);
		case CLASS_VAMP_NINA: SetClassNina(id);
		case CLASS_VAMP_LOUIS: SetClassLouis(id);
		case CLASS_HUMAN_FATHER: SetClassFather(id);
		case CLASS_HUMAN_MOLLY: SetClassMolly(id);
		case CLASS_HUMAN_EIGHTBALL: SetClassEightBall(id);
	}
}

public SetHuman(id) {
	// remove default weapons
	hl_strip_user_weapon(id, HLW_CROWBAR);
	hl_strip_user_weapon(id, HLW_GLOCK);

	// set stats
	set_user_footsteps(id, false); // footsteps on
	set_user_maxspeed(id, SLAYER_MAXSPEED);
}

public SetClassFather(id) {
	SetPlayerClass(id, CLASS_HUMAN_FATHER);
	hl_set_player_model(id, MDL_HUMAN_FATHER);

	SetHuman(id);

	// set equipment
	wpnmod_give_item(id, "weapon_vsstake");
	wpnmod_give_item(id, "weapon_vsshotgun");
	hl_set_user_bpammo(id, HLW_SHOTGUN, 28);
}

public SetClassMolly(id) {
	SetPlayerClass(id, CLASS_HUMAN_MOLLY);
	hl_set_player_model(id, MDL_HUMAN_MOLLY);

	SetHuman(id);

	// set equipment
	wpnmod_give_item(id, "weapon_vsstake");
	wpnmod_give_item(id, "weapon_vsshotgun");
	hl_set_user_bpammo(id, HLW_SHOTGUN, 28);
}

public SetClassEightBall(id) {
	SetPlayerClass(id, CLASS_HUMAN_EIGHTBALL);
	hl_set_player_model(id, MDL_HUMAN_EIGHTBALL);

	SetHuman(id);

	// set equipment
	wpnmod_give_item(id, "weapon_vsstake");
	wpnmod_give_item(id, "weapon_vsshotgun");
	hl_set_user_bpammo(id, HLW_SHOTGUN, 28);
}

public SetVampire(id) {
	// remove default weapons
	hl_strip_user_weapon(id, HLW_CROWBAR);
	hl_strip_user_weapon(id, HLW_GLOCK);

	// set equipment
	hl_set_user_longjump(id, true);
	wpnmod_give_item(id, "weapon_vsclaw");
	set_pev(id, pev_weapons, 1 << HLW_SUIT); // hack: hide weapon from weapon slots making think player has no weapons

	// set stats
	set_user_footsteps(id, true); // silent footsteps
	set_user_maxspeed(id, VAMP_MAXSPEED);
}

public SetClassEdgar(id) {
	// set class and model
	SetPlayerClass(id, CLASS_VAMP_EDGAR);
	hl_set_player_model(id, MDL_VAMP_EDGAR);

	SetVampire(id);

	// set stats
	g_KnockOutTime[id] = VAMP_EDGAR_KNOCKOUT_DURATION;
	g_WakeUpHealth[id] = VAMP_EDGAR_WAKEUP_HEALTH;
}

public SetClassLouis(id) {
	// set class and model
	SetPlayerClass(id, CLASS_VAMP_LOUIS);
	hl_set_player_model(id, MDL_VAMP_LOUIS);

	SetVampire(id);

	// set stats
	g_KnockOutTime[id] = VAMP_LOUIS_KNOCKOUT_DURATION;
	g_WakeUpHealth[id] = VAMP_LOUIS_WAKEUP_HEALTH;
}

public SetClassNina(id) {
	// set class and model
	SetPlayerClass(id, CLASS_VAMP_NINA);
	hl_set_player_model(id, MDL_VAMP_NINA);

	SetVampire(id);

	// set stats
	g_KnockOutTime[id] = VAMP_NINA_KNOCKOUT_DURATION;
	g_WakeUpHealth[id] = VAMP_NINA_WAKEUP_HEALTH;
}

StartRoundTimer() {
	remove_task(TASK_DISPLAYTIMER);
	if (RoundTimerCheck()) {
		DisplayTimer();
		set_task_ex(1.0, "RoundTimerThink", TASK_DISPLAYTIMER, .flags = SetTask_Repeat);
	}
}

public RoundTimerThink() {
	if (RoundTimerCheck())
		g_RoundTime--;
	DisplayTimer();
}

public RoundTimerCheck() {
	return g_RoundStarted && g_RoundTime > 0 ? true : false;
}

/* ===================
*/

/*General Stocks
*/

stock SetPevAllCorpses(_pev, any:value) {
	new ent;
	while ((ent = find_ent_by_class(ent, "bodyque"))) {
		set_pev(ent, _pev, value);
	}
}

// always one bodyque has to exist or functions that call CopyBodyQue() will crash the server
stock SetBodyCorpsesLimit(limit = 4) {
	if (limit < 1)
		return;

	// first bodyque we found is the head of the queue
	new queueHead = find_ent_by_class(0, "bodyque");

	// remove all body entities (except the first one) to set a new limit
	new ent;
	while ((ent = find_ent_by_class(ent, "bodyque"))) {
		if (ent != queueHead)
			remove_entity(ent);
	}

	new body = queueHead; // set queue of the head by default in case no entities can be created
	for (new i = 1; i < limit; i++) {
		new temp = create_entity("bodyque");
		if (temp) {
			set_pev(body, pev_owner, temp);
			body = temp;
		}
	}

	// the last body needs to have the head of the queue as owner always (circular queue)
	set_pev(body, pev_owner, queueHead);
}

stock wpnmod_give_item(const iPlayer, const szItem[])
{
	 new Float: vecOrigin[3];
	 pev(iPlayer, pev_origin, vecOrigin);
	 
	 new iItem = wpnmod_create_item(szItem, vecOrigin);
	 
	 if (pev_valid(iItem))
	 {
		  set_pev(iItem, pev_spawnflags, pev(iItem, pev_spawnflags) | SF_NORESPAWN);
		  dllfunc(DLLFunc_Touch, iItem, iPlayer);
		  
		  return iItem;
	 }
	 
	 return -1;
}

stock RemoveExtension(const input[], output[], length, const ext[]) {
	copy(output, length, input);

	new idx = strlen(input) - strlen(ext);
	if (idx < 0) return 0;

	return replace(output[idx], length, ext, "");
}

stock PlaySound(id, const sound[], removeExt = true) {
	new snd[128];
	// Remove .wav file extension (console starts to print "missing sound file _period.wav" for every sound)
	// Don't remove  in case the string already has no extension
	if (removeExt) {
		RemoveExtension(sound, snd, charsmax(snd), ".wav");
	}
	client_cmd(id, "spk %s", snd);
}

stock SpeakSnd(id, const sound[], removeExt = true) {
	new snd[128];
	// Remove .wav file extension (console starts to print "missing sound file _period.wav" for every sound)
	// Don't remove  in case the string already has no extension
	if (removeExt) {
		RemoveExtension(sound, snd, charsmax(snd), ".wav");
	}
	client_cmd(id, "speak %s", snd);
}

// Change player team by teamid
stock ChangePlayerTeam(id, teamId, kill = false) {
	static gameTeamMaster, gamePlayerTeam, spawnFlags;

	if (!gameTeamMaster) {
		gameTeamMaster = create_entity("game_team_master");
		set_pev(gameTeamMaster, pev_targetname, "changeteam");
	}

	if (!gamePlayerTeam) {
		gamePlayerTeam = create_entity("game_player_team");
		DispatchKeyValue(gamePlayerTeam, "target", "changeteam");
	}

	if (kill)
		spawnFlags = spawnFlags | SF_PTEAM_KILL;

	set_pev(gamePlayerTeam, pev_spawnflags, spawnFlags);

	DispatchKeyValue(gameTeamMaster, "teamindex", fmt("%i", teamId - 1));

	ExecuteHamB(Ham_Use, gamePlayerTeam, id, 0, USE_ON, 0.0);

	static TeamInfo;
	if (hl_get_user_spectator(id)) {
		if (TeamInfo || (TeamInfo = get_user_msgid("TeamInfo")))
		{
			message_begin(MSG_ALL, TeamInfo);
			write_byte(id);
			write_string("");
			message_end();
		}
	}
}

// Execute this post client_putinserver
// Change team names from VGUI Menu and VGUI Scoreboard (the last one only works with vanilla clients)
stock hl_set_teamnames(id, any:...) {
	new teamNames[HL_MAX_TEAMS][HL_TEAMNAME_LENGTH];
	new numTeams = clamp(numargs() - 1, 0, 10);

	for (new i; i < numTeams; i++)
		format_args(teamNames[i], charsmax(teamNames[]), 1 + i);

	// Send new team names
	message_begin(MSG_ONE, get_user_msgid("TeamNames"), _, id);
	write_byte(numTeams);
	for (new i; i < numTeams; i++)
		write_string(teamNames[i]);
	message_end();
}

stock hl_set_teamscore(teamName[], points, id = 0) {
	static teamScore;

	if (!teamScore)
		teamScore = get_user_msgid("TeamScore");

	message_begin(id == 0 ? MSG_BROADCAST : MSG_ONE, teamScore, _, id);
	write_string(teamName);
	write_short(points);
	write_short(0);
	message_end();
}


stock WeaponBox_Kill(const pWeaponBox)
{
		new pWeapon, i;
		
		// destroy the weapons
		for (i = 0 ; i < HL_MAX_WEAPON_SLOTS ; i++)
		{
				pWeapon = get_ent_data_entity(pWeaponBox, "CWeaponBox", "m_rgpPlayerItems", i);
 
				while (pWeapon != FM_NULLENT)
				{
						set_pev(pWeapon, pev_flags, FL_KILLME);
						
						pWeapon = get_ent_data_entity(pWeaponBox, "CBasePlayerItem", "m_pNext");
				}
		}
 
		// remove the box
		set_pev(pWeaponBox, pev_flags, FL_KILLME);
}