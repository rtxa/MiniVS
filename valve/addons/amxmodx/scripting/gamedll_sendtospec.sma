#include <amxmisc>
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <hlstocks>
#include <xs>

#define PLUGIN  "GameDLL Send to Spec"
#define VERSION "0.2"
#define AUTHOR  "rtxA"

new g_PutInServer[MAX_PLAYERS + 1];

public plugin_init() {
    register_plugin(PLUGIN, VERSION, AUTHOR);
    RegisterHamPlayer(Ham_Spawn, "OnPlayerSpawn_Post", true);
    RegisterHamPlayer(Ham_Player_UpdateClientData, "OnUpdateClientData_Pre");
}

public OnUpdateClientData_Pre(id) {
    // avoid sending update client data to players who haven't join yet
    // or they scoreboard will get screwed
    if (!g_PutInServer[id]) {
        set_pev(id, pev_iuser1, OBS_ROAMING);
        return HAM_SUPERCEDE;
    }
    return HAM_IGNORED;
}

public client_putinserver(id) {
    // bots don't initialize pev data until spawn
    if (!is_user_bot(id)) {
        hl_set_user_spectator(id);
        g_PutInServer[id] = true;
    }
}

public client_disconnected(id) {
    g_PutInServer[id] = false;
}

public OnPlayerSpawn_Post(id) {
    // Send joining player to spectator
    if (!g_PutInServer[id] && !is_user_bot(id)) {
        set_user_spectator(id);
    }

    // Send joining bot to spectator
    if (g_PutInServer[id] <= 1 && is_user_bot(id)) {
        set_user_spectator(id);
        g_PutInServer[id]++;
    }
}

// use this only before player spawn (no putinserver)
// it's better to use spectator cmd but it doesn't work unitl putinserver
stock set_user_spectator(id)
{
    new Float:origin[3];
    pev(id, pev_origin, origin);

    message_begin_f(MSG_PAS, SVC_TEMPENTITY, origin);
    write_byte(TE_KILLPLAYERATTACHMENTS);
    write_byte(id);
    message_end();

    new pTank = get_ent_data_entity(id, "CBasePlayer", "m_pTank");
    if (pTank != FM_NULLENT)
        ExecuteHamB(Ham_Use, pTank, id, id, USE_OFF, 0.0);

    // fixed in putinserver
    //hl_strip_user_weapons(id);
    set_pev(id, pev_weapons, 0);

    // Set HEV sounds off
    for (new i; i < get_ent_data_size("CBasePlayer", "m_rgSuitPlayList"); i++)
        set_ent_data(id, "CBasePlayer", "m_rgSuitPlayList", i);

    static CurWeapon;
    if (CurWeapon || (CurWeapon = get_user_msgid("CurWeapon"))) {
        message_begin(MSG_ONE, CurWeapon, .player = id);
        write_byte(0);
        write_byte(0);
        write_byte(0);
        message_end();
    }

    set_ent_data(id, "CBasePlayer", "m_iClientFOV", 0);
    set_ent_data(id, "CBasePlayer", "m_iFOV", 0);
    set_pev(id, pev_fov, 0);

    static SetFOV;
    if (SetFOV || (SetFOV = get_user_msgid("SetFOV"))) {
        message_begin(MSG_ONE, get_user_msgid("SetFOV"), .player = id);
        write_byte(0);
        message_end();
    }

    // store view_ofs
    new Float:view_ofs[3];
    pev(id, pev_view_ofs, view_ofs);

    // setup flags
    set_ent_data(id, "CBasePlayer", "m_iHideHUD", HIDEHUD_WEAPONS | HIDEHUD_HEALTH);
    set_ent_data(id, "CBasePlayer", "m_afPhysicsFlags", get_ent_data(id, "CBasePlayer", "m_afPhysicsFlags") | PFLAG_OBSERVER);
    set_pev(id, pev_view_ofs, NULL_VECTOR);
    set_pev(id, pev_fixangle, 1);
    set_pev(id, pev_solid, SOLID_NOT);
    set_pev(id, pev_takedamage, DAMAGE_NO);
    set_pev(id, pev_movetype, MOVETYPE_NONE);
    set_ent_data(id, "CBasePlayer", "m_afPhysicsFlags", get_ent_data(id, "CBasePlayer", "m_afPhysicsFlags") & ~PFLAG_DUCKING);
    set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_DUCKING);
    set_pev(id, pev_deadflag, DEAD_RESPAWNABLE);
    set_pev(id, pev_health, 1.0);
    set_pev(id, pev_effects, EF_NODRAW);

    set_ent_data(id, "CBasePlayer", "m_fInitHUD", 1);

    // set spectator at te same position of spawn
    new Float:specPos[3];
    xs_vec_add(origin, view_ofs, specPos);
    entity_set_origin(id, specPos);

    set_ent_data_float(id, "CBasePlayer", "m_flNextObserverInput", 0.0);
    
    // Observer_SetMode()
    set_pev(id, pev_iuser1, OBS_ROAMING);
    set_pev(id, pev_iuser3, 0);

    static TeamInfo;
    if (TeamInfo || (TeamInfo = get_user_msgid("TeamInfo")))
    {
        message_begin(MSG_ALL, TeamInfo);
        write_byte(id);
        write_string("");
        message_end();
    }

    // note: isn't possible to register this message from AMXX
    // a metamod or amxx module is required for this, perhaps orpheu too
    static Spectator;
    if (Spectator || (Spectator = get_user_msgid("Spectator"))) {
        message_begin(MSG_ALL, Spectator);
        write_byte(id);
        write_byte(1);
        message_end();
    }
}
