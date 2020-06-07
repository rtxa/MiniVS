/*
*	Weapon:KSG-12
*	Author:BIGs & X - RaY
*	
*	Thanks - Lev
*
*	Community HL-HEV | All For Half-Life [https://hl-hev.ru/]
*/

// used this gun as a base for this shotgun, something ahve to be fixed like the insertion, reload, dile ,etc

// añadir humo cuando dispare (revidsar como se dibuja un decal, ahi mismo debe estar el origen)
// tengo q ver cmo obtener el end origin de cada bullet, y ahi dibujar el sprite d ehumo
// su nombre es vssmoke.spr, hasta q sepa como, no voy a agregar nada, salu2

#include <amxmodx>
#include <hl_wpnmod>
#include <fakemeta_util>
#include <hamsandwich>

#pragma semicolon 1

#define PLUGIN "MiniVS Shotgun"
#define VERSION "0.2"
#define AUTHOR "rtxA"

//Configs
#define WEAPON_NAME "weapon_vsshotgun"
#define WEAPON_SLOT	3
#define WEAPON_POSITION	4
#define WEAPON_PRIMARY_AMMO	"buckshot"
#define WEAPON_PRIMARY_AMMO_MAX	125
#define WEAPON_SECONDARY_AMMO	""
#define WEAPON_SECONDARY_AMMO_MAX	-1
#define WEAPON_MAX_CLIP	8
#define WEAPON_DEFAULT_AMMO	 125
#define WEAPON_FLAGS	0
#define WEAPON_WEIGHT	10
#define WEAPON_DAMAGE	15.0

// Models
#define MODEL_WORLD	    "models/w_weaponbox.mdl"
#define MODEL_VIEW	    "models/minivs/v_shotgun.mdl"
#define MODEL_PLAYER	"models/minivs/p_shotgun.mdl"
#define MODEL_SHELL		"models/shotgunshell.mdl"


// Hud
#define WEAPON_HUD_TXT		"sprites/weapon_vsshotgun.txt"
#define WEAPON_HUD_SPR1		"sprites/vs_640hud1.spr"
#define WEAPON_HUD_SPR2		"sprites/vs_640hud4.spr"

 // i can fix the issue with reloading and
// Sounds
#define SOUND_FIRE	"minivs/weapons/sbarrel1.wav"
#define SOUND_DFIRE	"minivs/weapons/dbarrel1.wav"
#define SOUND_REL_1 	"weapons/scock1.wav"
// not used, but cool
#define SOUND_INSERT "weapons/reload3.wav"

// Animation
#define ANIM_EXTENSION	"shotgun"
	
#define Offset_Mod Offset_iuser1

#define VECTOR_CONE_DM_SHOTGUN	        Float:{ 0.08716, 0.04362, 0.00 } // 10 degrees by 5 degrees
#define VECTOR_CONE_DM_DOUBLESHOTGUN    Float:{ 0.17365, 0.04362, 0.00 } // 20 degrees by 5 degrees

enum _:cz_VUL
{
	ANIM_IDLE,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_RELOAD,
	ANIM_PUMP, 
	ANIM_START_RELOAD,
	ANIM_DRAW,
	ANIM_REHOLSTER,
	ANIM_IDLE4,
	ANIM_DEEPIDLE
}; 

new g_iShell;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	new KSG = wpnmod_register_weapon
	(
		WEAPON_NAME,
		WEAPON_SLOT,
		WEAPON_POSITION,
		WEAPON_PRIMARY_AMMO,
		WEAPON_PRIMARY_AMMO_MAX,
		WEAPON_SECONDARY_AMMO,
		WEAPON_SECONDARY_AMMO_MAX,
		WEAPON_MAX_CLIP,
		WEAPON_FLAGS,
		WEAPON_WEIGHT
	);
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Spawn, 	"KSG_Spawn" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Deploy, "KSG_Deploy" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Idle, "KSG_Idle" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_PrimaryAttack, "KSG_PrimaryAttack" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_SecondaryAttack, "KSG_SecondaryAttack" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Reload, "KSG_Reload" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_Holster, "KSG_Holster" );
	wpnmod_register_weapon_forward(KSG, Fwd_Wpn_ItemPostFrame, "KSG_WeaponTick");
}

public plugin_precache()
{
	PRECACHE_MODEL(MODEL_VIEW);
	PRECACHE_MODEL(MODEL_WORLD);
	PRECACHE_MODEL(MODEL_PLAYER);

	PRECACHE_SOUND(SOUND_FIRE);
	PRECACHE_SOUND(SOUND_DFIRE);
	PRECACHE_SOUND(SOUND_REL_1);
	PRECACHE_SOUND(SOUND_INSERT);
	
	PRECACHE_GENERIC(WEAPON_HUD_TXT);
	PRECACHE_GENERIC(WEAPON_HUD_SPR1);
	PRECACHE_GENERIC(WEAPON_HUD_SPR2);

	g_iShell = PRECACHE_MODEL(MODEL_SHELL);
}

public KSG_Spawn(const iItem)
{
	//Set model to floor
	SET_MODEL(iItem, MODEL_WORLD);
	
	// Give a default ammo to weapon
	wpnmod_set_offset_int(iItem, Offset_iDefaultAmmo, WEAPON_DEFAULT_AMMO);
}

public KSG_Deploy(const iItem, const iPlayer, const iClip)
{
	return wpnmod_default_deploy(iItem, MODEL_VIEW, MODEL_PLAYER, ANIM_DRAW, ANIM_EXTENSION);
}

public KSG_Holster(const iItem ,iPlayer)
{
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}

public KSG_Idle(const iItem, const iPlayer, const iClip, const iAmmo)
{
	wpnmod_reset_empty_sound(iItem);

	if (wpnmod_get_offset_float(iItem, Offset_flTimeWeaponIdle) > 0.0)
	{
		return;
	}
	
	new fInSpecialReload = wpnmod_get_offset_int( iItem, Offset_iInSpecialReload );
	
	if( !iClip && !fInSpecialReload && iAmmo )
	{
		KSG_Reload( iItem, iPlayer, iClip, iAmmo );
	}
	else if( fInSpecialReload != 0)
	{
		if( iClip != WEAPON_MAX_CLIP && iAmmo)
		{
			KSG_Reload( iItem, iPlayer, iClip, iAmmo );
		}
		else
		{
			wpnmod_set_offset_float( iItem, Offset_flPumpTime, get_gametime() + 0.35);
			wpnmod_send_weapon_anim( iItem, ANIM_PUMP);
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 0 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 1.5 );
		}
	}
	else 
	{
		new iAnim;
		new Float:flRand = random_float(0.0, 1.0);
		if (flRand <= 0.8)
		{
			iAnim = ANIM_IDLE;
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 15.0);
		}
		else if (flRand <= 0.95)
		{
			iAnim = ANIM_IDLE4;
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 15.0);
		}
		else
		{
			iAnim = ANIM_DEEPIDLE;
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 15.0);
		}
		wpnmod_send_weapon_anim( iItem, iAnim);
	}
}

public KSG_ItemPostFrame(const iItem, const iPlayer, const iClip, const iAmmo) {
	KSG_WeaponTick(iItem, iPlayer, iClip, iAmmo);
}

public KSG_WeaponTick(const iItem, const iPlayer, const iClip, const iAmmo) {
	new Float:pumpTime = wpnmod_get_offset_float(iItem, Offset_flPumpTime);
	if ( pumpTime && pumpTime < get_gametime() )
	{	
		// play pumping sound
		emit_sound(iPlayer, CHAN_ITEM, SOUND_REL_1, VOL_NORM, ATTN_NORM, 0, 95 + random_num(0, 31));
		wpnmod_set_offset_float(iItem, Offset_flPumpTime, 0.0);
	}
}

public KSG_Reload(const iItem, const iPlayer, const iClip, const iAmmo )
{
	if (iAmmo <= 0 || iClip >= WEAPON_MAX_CLIP)
	{
		return;
	}
	
	// don't reload until recoil is done
	if (wpnmod_get_offset_float( iItem, Offset_flNextPrimaryAttack ) + get_gametime() > get_gametime())
		return;

	switch (wpnmod_get_offset_int(iItem, Offset_iInSpecialReload))
	{
		case 0: // start to reload
		{
			wpnmod_send_weapon_anim( iItem, ANIM_START_RELOAD);
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
			wpnmod_set_offset_float( iItem, Offset_flNextPrimaryAttack, 1.0 );
			wpnmod_set_offset_float( iItem, Offset_flNextSecondaryAttack, 1.0 );
			wpnmod_set_offset_float(iItem, Offset_flPumpTime, 0.0); // block pumptime sound just in case
		}
		case 1: // insert animation
		{
			if ( wpnmod_get_offset_float( iItem, Offset_flTimeWeaponIdle ) > 0.0 )
				return;

			// was waiting for gun to move to side
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 2 );
			
			wpnmod_send_weapon_anim( iItem, ANIM_RELOAD);
			wpnmod_set_offset_float( iItem, Offset_flTimeWeaponIdle, 0.5 );
			emit_sound(iPlayer, CHAN_WEAPON, SOUND_INSERT, 0.9, ATTN_NORM, 0, PITCH_NORM);
		}
		default: // logic of inserting bullet and removing ammo internally
		{
			wpnmod_set_offset_int( iItem, Offset_iClip, iClip + 1 );
			wpnmod_set_player_ammo( iPlayer, WEAPON_PRIMARY_AMMO, iAmmo - 1 );
			wpnmod_set_offset_int( iItem, Offset_iInSpecialReload, 1 );
		}
	}

}

public KSG_PrimaryAttack(const iItem, const iPlayer, iClip)
{
	if (pev(iPlayer, pev_waterlevel) == 3 || iClip <= 0)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_FIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);

	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 1);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.75);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 0.75);
	wpnmod_set_offset_float(iItem, Offset_flPumpTime, get_gametime() + 0.5);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 15.0);
	
	wpnmod_send_weapon_anim( iItem, ANIM_SHOOT1);
		
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		4, 
		VECTOR_CONE_DM_SHOTGUN, 
		2048.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET, 
		1
	);
	
	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	set_pev(iPlayer, pev_punchangle, Float: {-6.0, 0.0, 0.0});
	
	wpnmod_eject_brass(iPlayer, g_iShell, TE_BOUNCE_SHELL, 16.0, -18.0, 6.0);

	// there is a case when you reload and you shoot later, the weaponwill continue to reload
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}

public KSG_SecondaryAttack(const iItem, const iPlayer, iClip, iAmmo)
{
	// play empty sound if we are in water or magazine is empty
	if (pev(iPlayer, pev_waterlevel) == 3)
	{
		wpnmod_play_empty_sound(iItem);
		wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 0.15);
		return;
	}  

	if (iClip <= 1) {
		// auto reload
		KSG_Reload(iItem, iPlayer, iClip, iAmmo);
		if (iClip == 0) {
			wpnmod_play_empty_sound(iItem);
		}
		return;
	}

	emit_sound(iPlayer, CHAN_WEAPON, SOUND_DFIRE, 0.9, ATTN_NORM, 0, PITCH_NORM);

	wpnmod_set_offset_int(iItem, Offset_iClip, iClip -= 2);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponVolume, LOUD_GUN_VOLUME);
	wpnmod_set_offset_int(iPlayer, Offset_iWeaponFlash, BRIGHT_GUN_FLASH);
	wpnmod_set_offset_float(iItem, Offset_flNextPrimaryAttack, 1.5);
	wpnmod_set_offset_float(iItem, Offset_flNextSecondaryAttack, 1.5);
	wpnmod_set_offset_float(iItem, Offset_flPumpTime, get_gametime() + 0.95);
	wpnmod_set_offset_float(iItem, Offset_flTimeWeaponIdle, 15.0);
	

	wpnmod_send_weapon_anim(iItem, ANIM_SHOOT2);
		
	wpnmod_fire_bullets
	(
		iPlayer, 
		iPlayer, 
		8, 
		VECTOR_CONE_DM_DOUBLESHOTGUN, 
		2048.0, 
		WEAPON_DAMAGE, 
		DMG_BULLET, 
		1
	);
	
	wpnmod_eject_brass(iPlayer, g_iShell, TE_BOUNCE_SHELL, 16.0, -18.0, 6.0);
	wpnmod_eject_brass(iPlayer, g_iShell, TE_BOUNCE_SHELL, 16.0, -18.0, 6.0);

	set_pev(iPlayer, pev_effects, pev(iPlayer, pev_effects) | EF_MUZZLEFLASH);
	set_pev(iPlayer, pev_punchangle, Float: {-12.0, 0.0, 0.0});

	// player "shoot" animation
	wpnmod_set_player_anim(iPlayer, PLAYER_ATTACK1);

	// there is a case when you reload and you shoot later, the weaponwill continue to reload
	wpnmod_set_offset_int(iItem, Offset_iInSpecialReload, 0);
}
