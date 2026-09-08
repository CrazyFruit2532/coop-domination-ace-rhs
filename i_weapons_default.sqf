// by Xeno
//#define __DEBUG__
#include "x_setup.sqf"

// please note that in the non ranked version all weapons and items are available, no matter which rank the player has

__TRACE("i_weapons.sqf")


private "_all_weapons_items";
if (!d_tt_ver) then {
#ifdef __OWN_SIDE_BLUFOR__
	_all_weapons_items = ["arsenal_west"] call arsenal_fnc_config_blufor;
#endif
#ifdef __OWN_SIDE_OPFOR__
	_all_weapons_items = ["arsenal_east"] call arsenal_fnc_config_opfor;
#endif
} else {
	if (side (group player) == blufor) then {
		__TRACE("Player is blufor")
		_all_weapons_items = ["arsenal_west"] call arsenal_fnc_config_blufor;
	} else {
		__TRACE("Player is opfor")
		_all_weapons_items = ["arsenal_east"] call arsenal_fnc_config_opfor;
	};
};

#include "i_weapons_base.sqf"
