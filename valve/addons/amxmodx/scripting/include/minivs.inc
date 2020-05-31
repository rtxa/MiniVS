#if defined _minivs_included
	#endinput
#endif
#define _minivs_included

#include <hl_wpnmod_const>

#define Claw_Ofs_PowerTimeLeft  Offset_iuser3
#define Stake_Ofs_IsPowerOn     Offset_iuser4

native vs_claw_special_attack(const name[]);

stock vs_claw_get_power_timeleft(ent) {
    return wpnmod_get_offset_int(ent, Claw_Ofs_PowerTimeLeft);
}

// make sure to use it in a stake...
stock vs_stake_is_powerup_on(ent) {
	return wpnmod_get_offset_int(ent, Stake_Ofs_IsPowerOn);
}