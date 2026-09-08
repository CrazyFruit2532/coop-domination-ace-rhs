// by Xeno, edited by Babayka
//#define __DEBUG__
#include "..\x_setup.sqf"

params ["_ma"];
private _bpos = markerPos _ma;
private _box = createVehicle [d_the_base_box, _bpos, [], 0, "NONE"];
_box setPos _bpos;
_box setDir (markerDir _ma);
if (surfaceIsWater _bpos && {!isNil "d_the_carrier"}) then {
	// we assume it is the carrier
	private _aslh = d_the_carrier getVariable "d_asl_height";
	if (!isNil "_aslh") then {
		_box setPosASL [_bpos # 0, _bpos # 1, _aslh];
	};
};
_box setVariable ["d_bpos", getPosASL _box];
_box setVariable ["d_bdir", markerDir _ma];
clearWeaponCargoGlobal _box;
clearMagazineCargoGlobal _box;
clearBackpackCargoGlobal _box;
clearItemCargoGlobal _box;

if (d_with_ace) then { // added Babayka
	d_actionID2 = [
		_box, 
		"<t color='#FFC300' size='1.2'>ACE Arsenal</t>",
		"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",       
		"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
		"isNull objectParent player && {alive _this}",      
		"isNull objectParent player && {alive _this}", 
		{params ["_target", "_caller", "_actionId", "_arguments"]}, 
		{[player, player, false] call ace_arsenal_fnc_openBox},
		{},       
		{},     
		[_box],     
		12,     
		-1,     
		false,     
		false     
		] remoteExec ["BIS_fnc_holdActionAdd", 0, _box];
}else{
	d_actionID2 = [
		_box, 
		"<t color='#FFC300' size='1.2'>Arsenal</t>",
		"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",       
		"\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
		"isNull objectParent player && {alive _this}",      
		"isNull objectParent player && {alive _this}", 
		{params ["_target", "_caller", "_actionId", "_arguments"]}, 
		{["Open", [nil, player]] call bis_fnc_arsenal},
		{},       
		{},     
		[_box],     
		12,     
		-1,     
		false,     
		false     
		] remoteExec ["BIS_fnc_holdActionAdd", 0, _box];
};

_box enableRopeAttach false;
_box enableSimulationGlobal false;
_box addEventhandler ["killed", {call d_fnc_playerboxkilled}];
_box
