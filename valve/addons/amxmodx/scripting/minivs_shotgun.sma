/*
*	Weapon:KSG-12
*	Author:BIGs & X - RaY
*	
*	Thanks - Lev
*
*	Community HL-HEV | All For Half-Life [https://hl-hev.ru/]
*/

// used this gun as a base, wasn't easy, lot of things have to be fixed like the insertion, reload, delay, etc.

#include <amxmodx>
#include <hl_wpnmod>
#include <fakemeta_util>
#include <hamsandwich>

#pragma semicolon 1

#define PLUGIN "MiniVS Shotgun"
#define VERSION "0.3"
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
#define WEAPON_SMOKE_SPR	"sprites/explode1.spr"

// Sounds
#define SOUND_FIRE	"minivs/weapons/sbarrel1.wav"
#define SOUND_DFIRE	"minivs/weapons/dbarrel1.wav"
#define SOUND_REL_1 "weapons/scock1.wav"
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
new g_sSmoke;

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
	g_sSmoke = PRECACHE_MODEL(WEAPON_SMOKE_SPR);
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
		
	FireBulletsPlayer
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
		
	FireBulletsPlayer
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

// ======================= stocks ==================================

stock FireBulletsPlayer(iPlayer, iAttacker, iShotsCount, Float:vecSpread[3], Float:flDistance, Float:flDamage, bitsDamageType, iTracerFreq) {
	new Float:x, Float:y, Float:z;
	static tracerCount;
	new tr;

	// Vector vecSrc = pPlayer->v.origin + pPlayer->v.view_ofs;
	new Float:plrOrigin[3], Float:plrViewOfs[3];
	pev(iPlayer, pev_origin, plrOrigin);
	pev(iPlayer, pev_view_ofs, plrViewOfs);

	new Float:vecSrc[3];
	xs_vec_add(plrOrigin, plrViewOfs, vecSrc);
	
	// MAKE_VECTORS(pPlayer->v.v_angle + pPlayer->v.punchangle);
	new Float:plrAngle[3], Float:plrPunchAngle[3];
	pev(iPlayer, pev_punchangle, plrPunchAngle);
	pev(iPlayer, pev_v_angle, plrAngle);
	{
		new Float:temp[3];
		xs_vec_add(plrAngle, plrPunchAngle, temp);
		engfunc(EngFunc_MakeVectors, temp);
	}

	new Float:vecDirShooting[3], Float:vecRight[3], Float:vecUp[3];
	global_get(glb_v_forward, vecDirShooting);
	global_get(glb_v_right, vecRight);
	global_get(glb_v_up, vecUp);

	if (!iAttacker) {
		iAttacker = iPlayer; // the default attacker is ourselves
	}

	wpnmod_clear_multi_damage();

	for (new iShot = 1; iShot <= iShotsCount; iShot++) {
		// get circular gaussian spread
		do { 
			x = random_float(-0.5, 0.5) + random_float(-0.5, 0.5);
			y = random_float(-0.5, 0.5) + random_float(-0.5, 0.5);
			z = x*x + y*y;
		} while (z > 1);

		// Vector vecDir = vecDirShooting +
		//	 	  x * vecSpread.x * vecRight +
		//	 	  y * vecSpread.y * vecUp;
		new Float:mulX[3], Float:mulY[3];
		xs_vec_mul_scalar(vecRight, x * vecSpread[0], mulX);
		xs_vec_mul_scalar(vecUp, y * vecSpread[1], mulY);

		new Float:vecDir[3];
		xs_vec_add(vecDir, vecDirShooting, vecDir);
		xs_vec_add(vecDir, mulX, vecDir);
		xs_vec_add(vecDir, mulY, vecDir);

		// Vector vecEnd = vecDir * flDistance + vecSrc;
		new Float:vecEnd[3];
		xs_vec_mul_scalar(vecDir, flDistance, vecEnd);
		xs_vec_add(vecEnd, vecSrc, vecEnd); // aca s epuede jod

		tr = create_tr2();
		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, iPlayer, tr);

		if (iTracerFreq != 0 && (tracerCount++ % iTracerFreq) == 0) {
			new Float:vecF[3], Float:vecR[3];
			global_get(glb_v_forward, vecF);
			global_get(glb_v_right, vecR);

			// adjust tracer position for player
			// Vector vecTracerSrc = vecSrc + Vector (0 , 0 , -4) + gpGlobals->v_right * 2 + gpGlobals->v_forward * 16;
			new Float:vecTracerSrc[3];
			
			xs_vec_add(vecTracerSrc, vecSrc, vecTracerSrc);

			xs_vec_add(vecTracerSrc, Float:{0.0, 0.0, -4.0}, vecTracerSrc);

			xs_vec_mul_scalar(vecR, 2.0, vecR);
			xs_vec_add(vecTracerSrc, vecR, vecTracerSrc);

			xs_vec_mul_scalar(vecF, 16.0, vecF);
			xs_vec_add(vecTracerSrc, vecF, vecTracerSrc);

			new Float:vecEndPos[3];
			get_tr2(tr, TR_vecEndPos, vecEndPos);

			message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecTracerSrc);
			write_byte(TE_TRACER);
			write_coord_f(vecTracerSrc[0]);
			write_coord_f(vecTracerSrc[1]);
			write_coord_f(vecTracerSrc[2]);
			write_coord_f(vecEndPos[0]);
			write_coord_f(vecEndPos[1]);
			write_coord_f(vecEndPos[2]);
			message_end();
		}

		new iHit = get_tr2(tr, TR_pHit);

		if (iHit == FM_NULLENT)
			iHit = 0;
		
		new Float:flFraction;
		get_tr2(tr, TR_flFraction, flFraction);
		
		// do damage, paint decals
		if (flFraction != 1.0) {
			ExecuteHamB(Ham_TraceAttack, iHit, iAttacker, flDamage, vecDir, tr, bitsDamageType);
			TEXTURETYPE_PlaySound(tr, vecSrc, vecEnd);
			UTIL_DecalGunshot(tr);
		}
	}

	wpnmod_apply_multi_damage(iPlayer, iAttacker);

	free_tr2(tr);
}

// this function is probably unsafe...
stock UTIL_DecalGunshot(pTrace) {
	new iHit = get_tr2(pTrace, TR_pHit);

	if (iHit == FM_NULLENT)
		iHit = 0;

	if (pev(iHit, pev_flags) & FL_KILLME)
		return;

	if (pev(iHit, pev_solid) == SOLID_BSP || pev(iHit, pev_movetype) == MOVETYPE_PUSHSTEP) {
		// if crash happens when using this weapon, this can be the cause
		new iDecalIndex = wpnmod_get_damage_decal(iHit);
		
		if (iDecalIndex < 0)
			return;

		new Float:flFraction;
		get_tr2(pTrace, TR_flFraction, flFraction);

		if (iDecalIndex < 0 || flFraction == 1.0) {
			return;
		}

		new Float:vecEndPos[3], Float:vecPlaneNormal[3];
		get_tr2(pTrace, TR_vecEndPos, vecEndPos);
		get_tr2(pTrace, TR_vecPlaneNormal, vecPlaneNormal);

		message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecEndPos);
		write_byte(TE_GUNSHOTDECAL);
		write_coord_f(vecEndPos[0]);
		write_coord_f(vecEndPos[1]);
		write_coord_f(vecEndPos[2]);
		write_short(iHit);
		write_byte(iDecalIndex);
		message_end();

		// move 5 units backwards or the smoke won't be visible
		// todo: make smoke visible when shooting to the ceil
		message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecEndPos);
		write_byte(TE_EXPLOSION);
		write_coord_f(vecEndPos[0] + (5.0 * vecPlaneNormal[0]));
		write_coord_f(vecEndPos[1] + (5.0 * vecPlaneNormal[1]));
		write_coord_f(vecEndPos[2] + (5.0 * vecPlaneNormal[2]));
		write_short(g_sSmoke);
		write_byte(5);
		write_byte(15);
		write_byte(TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND);
		message_end();

		message_begin_f(MSG_PAS, SVC_TEMPENTITY, vecEndPos);
		write_byte(TE_STREAK_SPLASH);
		write_coord_f(vecEndPos[0]);
		write_coord_f(vecEndPos[1]);
		write_coord_f(vecEndPos[2]);
		write_coord_f(vecPlaneNormal[0]);
		write_coord_f(vecPlaneNormal[1]);
		write_coord_f(vecPlaneNormal[2]);
		write_byte(5);
		write_short(random_num(30, 40));
		write_short(1);
		write_short(150);
		message_end();
	}
}

#define CBTEXTURENAMEMAX	13			// only load first n chars of name

#define CHAR_TEX_CONCRETE	'C'			// texture types
#define CHAR_TEX_METAL		'M'
#define CHAR_TEX_DIRT		'D'
#define CHAR_TEX_VENT		'V'
#define CHAR_TEX_GRATE		'G'
#define CHAR_TEX_TILE		'T'
#define CHAR_TEX_SLOSH		'S'
#define CHAR_TEX_WOOD		'W'
#define CHAR_TEX_COMPUTER	'P'
#define CHAR_TEX_GLASS		'Y'
#define CHAR_TEX_FLESH		'F'

stock Float:TEXTURETYPE_PlaySound(tr, Float:vecSrc[3], Float:vecEnd[3]) {
	new chTextureType;
	new Float:fvol;
	new Float:fvolbar;
	new szbuffer[64];
	new szTextureName[32];
	new rgsz[4][32];
	new cnt;
	new Float:fattn = ATTN_NORM;

	new iEntity = get_tr2(tr, TR_pHit);

	if (iEntity == FM_NULLENT)
		iEntity = 0;

	chTextureType = 0;

	new classify = ExecuteHam(Ham_Classify, iEntity);
	if (iEntity && classify != CLASS_NONE && classify != CLASS_MACHINE) {
		// hit body
			chTextureType = CHAR_TEX_FLESH;
	} else {
		// hit world
		// find texture under strike, get material type

		// get texture from entity or world (world is ent(0))
		engfunc(EngFunc_TraceTexture, iEntity, vecSrc, vecEnd, szTextureName, charsmax(szTextureName));

		if (szTextureName[0]) {
			// strip leading '-0' or '+0~' or '{' or '!'
			if (szTextureName[0] == '-' || szTextureName[0] == '+')
				copy(szTextureName, charsmax(szTextureName), szTextureName[2]);			

			if (szTextureName[0] == '{' || szTextureName[0] == '!' || szTextureName[0] == '~' || szTextureName[0] == ' ')
				copy(szTextureName, charsmax(szTextureName), szTextureName[1]);			
			// '}}'
			copy(szbuffer, charsmax(szbuffer), szTextureName);
			szbuffer[CBTEXTURENAMEMAX - 1] = 0;

			// get texture type
			chTextureType = dllfunc(DLLFunc_PM_FindTextureType, szbuffer);
		}
	}

// ==========================================
	switch (chTextureType) {
		case CHAR_TEX_CONCRETE: {
			fvol = 0.9;	fvolbar = 0.6;
			copy(rgsz[0], charsmax(rgsz[]), "player/pl_step1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "player/pl_step2.wav");
			cnt = 2;
		}
		case CHAR_TEX_METAL: {
			fvol = 0.9; fvolbar = 0.3;
			copy(rgsz[0], charsmax(rgsz[]), "player/pl_metal1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "player/pl_metal2.wav");
			cnt = 2;
		}
		case CHAR_TEX_DIRT: {	
			fvol = 0.9; fvolbar = 0.1;
			copy(rgsz[0], charsmax(rgsz[]), "player/pl_dirt1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "player/pl_dirt2.wav");
			copy(rgsz[2], charsmax(rgsz[]), "player/pl_dirt3.wav");
			cnt = 3;
		}
		case CHAR_TEX_VENT: {	
			fvol = 0.5; fvolbar = 0.3;
			copy(rgsz[0], charsmax(rgsz[]), "player/pl_duct1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "player/pl_duct1.wav");
			cnt = 2;
		}
		case CHAR_TEX_GRATE: { 
			fvol = 0.9; fvolbar = 0.5;
			copy(rgsz[0], charsmax(rgsz[]), "player/pl_grate1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "player/pl_grate4.wav");
			cnt = 2;
		}
		case CHAR_TEX_TILE: {	
			fvol = 0.8; fvolbar = 0.2;
			copy(rgsz[0], charsmax(rgsz[]), "player/pl_tile1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "player/pl_tile3.wav");
			copy(rgsz[2], charsmax(rgsz[]), "player/pl_tile2.wav");
			copy(rgsz[3], charsmax(rgsz[]), "player/pl_tile4.wav");
			cnt = 4;
		}
		case CHAR_TEX_SLOSH: { 
			fvol = 0.9; fvolbar = 0.0;
			copy(rgsz[0], charsmax(rgsz[]), "player/pl_slosh1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "player/pl_slosh3.wav");
			copy(rgsz[2], charsmax(rgsz[]), "player/pl_slosh2.wav");
			copy(rgsz[3], charsmax(rgsz[]), "player/pl_slosh4.wav");
			cnt = 4;
		}
		case CHAR_TEX_WOOD: { 
			fvol = 0.9; fvolbar = 0.2;
			copy(rgsz[0], charsmax(rgsz[]), "debris/wood1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "debris/wood2.wav");
			copy(rgsz[2], charsmax(rgsz[]), "debris/wood3.wav");
			cnt = 3;
		}
		case CHAR_TEX_COMPUTER, CHAR_TEX_GLASS: {
			fvol = 0.8; fvolbar = 0.2;
			copy(rgsz[0], charsmax(rgsz[]), "debris/glass1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "debris/glass2.wav");
			copy(rgsz[2], charsmax(rgsz[]), "debris/glass3.wav");
			cnt = 3;
		}
		case CHAR_TEX_FLESH: {
			fvol = 1.0; fvolbar = 0.2;
			copy(rgsz[0], charsmax(rgsz[]), "weapons/bullet_hit1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "weapons/bullet_hit2.wav");
			fattn = 1.0;
			cnt = 2;
		}
		default: { // CHAR_TEX_CONCRETE too
			fvol = 0.9;	fvolbar = 0.6;
			copy(rgsz[0], charsmax(rgsz[]), "player/pl_step1.wav");
			copy(rgsz[1], charsmax(rgsz[]), "player/pl_step2.wav");
			cnt = 2;
		}
	}

	// debug
	//log_amx("Texture name %s Type %c fvol %f fvolbar %f", szTextureName, chTextureType, fvol, fvolbar);
	
	// play material hit sound
	new Float:vecEndPos[3];
	get_tr2(tr, TR_vecEndPos, vecEndPos);
	engfunc(EngFunc_EmitAmbientSound, 0, vecEndPos, rgsz[random_num(0, cnt - 1)], fvol, fattn, 0, 96 + random_num(0, 15));
	
	return fvolbar;
}
