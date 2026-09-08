// by Xeno
//#define __DEBUG__
#include "..\x_setup.sqf"
diag_log [diag_frameno, diag_ticktime, time, "Executing Dom initcommon.sqf"];

if (isNil "paramsArray") then {
	if (isClass (getMissionConfig "Params")) then {
		private _conf = getMissionConfig "Params";
		private ["_paramName", "_paramval", "_tidx"];
		for "_i" from 0 to (count _conf - 1) do {
			_paramName = configName (_conf select _i);
			_paramval = getNumber (_conf>>_paramName>>"default");
			if (_paramval != -66) then {
				missionNamespace setVariable [_paramName, _paramval];
#ifndef __SPE__
				_tidx = getArray (_conf>>_paramName>>"values") find _paramval;
				diag_log ["Mission parameter: ", getText (_conf>>_paramName>>"title"), _paramName, " Value: ", getArray (_conf>>_paramName>>"texts") # _tidx, " Index: ", _paramval];
#endif
			} else {
#ifndef __SPE__
				diag_log ["Mission parameter: ", getText (_conf>>_paramName>>"title")];
#endif
			};
		};
	};
} else {
	private _conf = getMissionConfig "Params";
	private ["_paramName", "_paramval", "_tidx"];
	for "_i" from 0 to (count paramsArray - 1) do {
		_paramName = configName (_conf select _i);
		_paramval = paramsArray select _i;
		if (_paramval != -66) then {
			missionNamespace setVariable [configName (_conf select _i), _paramval];
#ifndef __SPE__
			_tidx = getArray (_conf>>_paramName>>"values") find _paramval;
			diag_log ["Mission parameter: ", getText (_conf>>_paramName>>"title"), _paramName, " Value: ", getArray (_conf>>_paramName>>"texts") # _tidx, " Index: ", _paramval];
#endif
		} else {
#ifndef __SPE__
			diag_log ["Mission parameter: ", getText (_conf>>_paramName>>"title")];
#endif
		};
	};
};

d_no_ranked_weapons = d_with_ranked == 2;
d_with_ranked = d_with_ranked == 0 || {d_with_ranked == 2};
#ifndef __TT__
d_ai_no_statics = d_with_ai == 2 || {d_with_ai == 4};
d_ai_dyn_recruit = d_with_ai == 3 || {d_with_ai == 4};
d_with_ai = d_with_ai == 0 || {d_with_ai > 1};
#else
d_with_ai = false;
d_with_ai_features = 1;
d_WithJumpFlags = 1;
d_MaxNumAmmoboxes = d_MaxNumAmmoboxes * 2;
d_pilots_only = 1;
#endif
d_no_ai = !d_with_ai && {d_with_ai_features == 1};
d_enemy_mode_current_maintarget = nil; // nil unless d_WithLessArmor is set to random

if (d_with_ace && {d_ACEMedicalR == 1}) then {
	d_WithRevive = 1;
	ace_medical_enableRevive = 1;
	ace_medical_maxReviveTime = 300;
	ace_medical_amountOfReviveLives = -1;
};

if (d_WithRevive == 0 && {hasInterface}) then {
	xr_pl_can_revive = true;
	xr_uncon_units = [];
};

if (d_sub_kill_points != 0 && {d_sub_kill_points > 0}) then {
	d_sub_kill_points = d_sub_kill_points * -1;
};

if (d_with_ace) then {
	d_pylon_lodout = 1;
};

#ifdef __TT__
if (isNil "d_tt_points") then {
	d_tt_points = [
		30, // очки за победу команды, выполнившей главную задачу
		7, // очки в случае ничьей (главная задача)
		15, // очки за уничтожение радиовышки главной задачи
		5, // очки за выполнение миссии главной задачи
		10, // очки за выполнение побочной миссии
		5, // очки за захват лагеря (главная задача)
		10, // очки, которые вычитаются при повторной потере лагеря главной задачи
		4, // очки за уничтожение техники противоположной команды
		2 // очки за убийство участника противоположной команды
	];
};
#endif

if (isNil "d_cas_available_time") then {
	d_cas_available_time = 600; // time till CAS is available again!
};

if (isNil "d_cas_available_time_low") then {
	d_cas_available_time_low = 100; // time CAS low cooldown setting
};

if (isServer) then {
	skipTime d_TimeOfDay;

#ifdef __UNSUNG__
	d_WithLessArmor = 1;
	d_WithLessArmor_side = 1;
#endif
#ifdef __VN__
	d_WithLessArmor = 1;
	d_WithLessArmor_side = 1;
#endif

	// set enemy mode
	d_WithLessArmor call d_fnc_setenemymode;

	// навык вражеского ИИ: [базовый навык, случайное значение (random 0.3), которое добавляется к базовому навыку]
	d_skill_array = [[0.1,0.05], [0.2,0.1], [0.4,0.2], [0.6,0.3], [0.65,0.3]] select d_EnemySkill;
	
	if (isNil "d_addscore_a") then {
		d_addscore_a = [
			5, // 1 - здание казармы уничтожено на главной задаче
			5, // 2 - здание мобильного штаба уничтожено на главной задаче
			5, // 3 - радиовышка уничтожена на главной задаче
			5, // 4 - игрок захватил лагерь
			5, // 5 - игрок выполнил миссию главной задачи
			30, // 6 - дополнительные очки за захват главной задачи
			10, // 7 - очки за реанимацию другого игрока
			10, // 8 - очки за помощь в выполнении побочной миссии, 
			[3,2,1,0], // 9 - очки за ремонт/заправку техники
			5, // 10 - очки за лечение другого бойца
			3, // 11 - очки, когда другой игрок лечится в полевом госпитале игрока
			5, // 12 - очки, когда другой игрок возрождается на лидере отряда
			1, // 13 - очки за транспортировку другого игрока в технике
			20 // 14 - очки за доставку обломков на точку ремонта техники
		];
	};
};

if (isNil "d_ranked_a") then {
	d_ranked_a = [
	20, // очки, которые должен иметь инженер для ремонта/заправки техники, 
	[3,2,1,0], // очки, которые получают инженеры за ремонт воздушной техники, танка, машины, прочего
	10, // очки, необходимые оператору артиллерии для вызова удара
	3, // очки в версии с ИИ за наём одного солдата
	1, // очки, необходимые игроку для прыжка с парашютом (AAHALO)
	10, // очки, которые вычитаются за создание техники на мобильном штабе (MHQ)
	20, // очки, необходимые для создания техники на мобильном штабе (MHQ)
	3, // очки, которые получает медик, если кто-то лечится в его полевом госпитале (Mash)
	["Corporal","Sergeant","Lieutenant","Lieutenant","Sergeant","Corporal"], // Звания, необходимые для управления разной техникой, начиная с: колёсный БТР, танк, вертолёт (кроме первых 4-х), самолёт, корабли/лодки, стационарное орудие
	30, // очки, которые добавляются, если игрок находится в пределах xxx м от главной задачи в момент её зачистки
	400, // расстояние (в метрах), на котором должен находиться игрок, чтобы получить доп. очки за главную задачу
	10, // очки, которые добавляются, если игрок находится в пределах xxx м от побочной миссии в момент её выполнения
	200, // расстояние (в метрах), на котором должен находиться игрок, чтобы получить доп. очки за побочную миссию
	20, // очки, необходимые инженеру для восстановления построек поддержки на базе
	10, // больше не используется !!! Раньше это были очки, необходимые для постройки пулемётного гнезда
	5, // очки, необходимые в режиме AI Ranked для вызова воздушного такси
	20, // очки, необходимые для вызова сброса груза с воздуха (air drop)
	4, // очки, которые получает медик, когда лечит другого бойца
	1, // очки, которые получает игрок за транспортировку других игроков
	20, // очки, необходимые для активации спутникового режима обзора
	20, // очки, необходимые для постройки передового пункта заправки и снабжения (FARP) (для инженера)
	10, // очки, которые получает игрок за реанимацию другого игрока
	20, // очки, необходимые лидеру отряда для вызова авиаподдержки (CAS)
	20, // очки, которые получает игрок за доставку обломков на точку ремонта
	30 // очки, необходимые игроку для использования боевого БПЛА (UAV)
	];
} else {
	if (count d_ranked_a < 25) then {
		if (count d_ranked_a == 22) then {
			d_ranked_a append [20, 20, 30];
		};
		if (count d_ranked_a == 23) then {
			d_ranked_a append [20, 30];
		};
		if (count d_ranked_a == 24) then {
			d_ranked_a append [30];
		};
	};
};

if (isServer) then {
	d_sc_hash = createHashMapFromArray [
		[0, (d_ranked_a # 3) * -1],
		[1, (d_ranked_a # 2) * -1],
		[2, (d_ranked_a # 15) * -1],
		[3, (d_ranked_a # 5) * -1],
		[4, (d_ranked_a # 16) * -1],
		[5, d_ranked_a # 17],
		[6, (d_ranked_a # 19) * -1],
		[7, d_ranked_a # 17],
		[8, (d_ranked_a # 4) * -1],
		[9, (d_ranked_a # 19) * -1],
		[10, (d_ranked_a # 20) * -1],
		[11, (d_ranked_a # 24) * -1]
	];
};

// имя переменной вертолёта, тип (0 = транспортный/грузовой, 1 = эвакуатор обломков, 2 = обычный), имя маркера, уникальный номер (такой же, как в d_init.sqf), тип маркера, цвет маркера, текст маркера, строковое имя вертолёта
#ifndef __TT__
d_choppers = [
	["D_HR1",0,"d_chopper1",3001,"n_air","ColorWhite","1", localize "STR_DOM_MISSIONSTRING_7"], ["D_HR2",0,"d_chopper2",3002,"n_air","ColorWhite","2",""],
	["D_HR3",2,"d_chopper3",3003,"n_air","ColorWhite","3",""], ["D_HR4",1,"d_chopper4",3004,"n_air","ColorWhite","W", localize "STR_DOM_MISSIONSTRING_10"],
	["D_HR5",2,"d_chopper5",3005,"n_air","ColorWhite","5",""], ["D_HR6",2,"d_chopper6",3006,"n_air","ColorWhite","6",""]
];
#else
d_choppers_blufor = [
	["D_HR1",0,"d_chopper1",3001,"n_air","ColorWhite","1", localize "STR_DOM_MISSIONSTRING_7"], ["D_HR2",0,"d_chopper2",3002,"n_air","ColorWhite","2",""],
	["D_HR3",2,"d_chopper3",3003,"n_air","ColorWhite","3",""], ["D_HR4",1,"d_chopper4",3004,"n_air","ColorWhite","W", localize "STR_DOM_MISSIONSTRING_10"],
	["D_HR5",2,"d_chopper5",3005,"n_air","ColorWhite","5",""], ["D_HR6",2,"d_chopper6",3006,"n_air","ColorWhite","6",""]
];
d_choppers_opfor = [
	["D_HRO1",0,"d_choppero1",4001,"n_air","ColorWhite","1", localize "STR_DOM_MISSIONSTRING_7"], ["D_HRO2",0,"d_choppero2",4002,"n_air","ColorWhite","2",""],
	["D_HRO3",2,"d_choppero3",4003,"n_air","ColorWhite","3",""], ["D_HRO4",1,"d_choppero4",4004,"n_air","ColorWhite","W", localize "STR_DOM_MISSIONSTRING_10"],
	["D_HRO5",2,"d_choppero5",4005,"n_air","ColorWhite","5",""], ["D_HRO6",2,"d_choppero6",4006,"n_air","ColorWhite","6",""]
];
#endif

// имя переменной техники, уникальный номер (такой же, как в d_init.sqf), имя маркера, тип маркера, цвет маркера, текст маркера, строковое имя техники
#ifndef __TT__
d_p_vecs = [
	["D_MRR1",0,"d_mobilerespawn1","b_hq","ColorYellow","1",localize "STR_DOM_MISSIONSTRING_12"],["D_MRR2",1,"d_mobilerespawn2","b_hq","ColorYellow","2",localize "STR_DOM_MISSIONSTRING_13"],
	["D_MEDVEC",100,"d_medvec","n_med","ColorGreen","M",""],["D_TR1",200,"d_truck1","n_maint","ColorGreen","R1",""],
	["D_TR2",201,"d_truck2","n_support","ColorGreen","F1",""],["D_TR3",202,"d_truck3","n_support","ColorGreen","A1",""],
	["D_TR6",203,"d_truck4","n_maint","ColorGreen","R2",""],["D_TR5",204,"d_truck5","n_support","ColorGreen","F2",""],
	["D_TR4",205,"d_truck6","n_support","ColorGreen","A2",""],["D_TR7",300,"d_truck7","n_service","ColorGreen","E1",""],
	["D_TR8",301,"d_truck8","n_service","ColorGreen","E2",""],["D_TR9",400,"d_truck9","n_support","ColorGreen","T2",""],
	["D_TR10",401,"d_truck10","n_support","ColorGreen","T1",""]
];
if (d_ifa3 || {d_spe}) then {
	d_p_vecs pushBack ["D_TR11",500,"d_truck11","n_support","ColorGreen","W1",""];
};
if (d_gmcwg) then {
	d_p_vecs append [
		["D_TR11",500,"d_truck11","n_support","ColorGreen","W1",""],
		["D_TR12",501,"d_truck11","n_support","ColorGreen","W2",""],
		["D_TR13",502,"d_truck12","n_support","ColorGreen","W3",""],
		["D_TR14",503,"d_truck13","n_support","ColorGreen","W4",""],
		["D_TR15",504,"d_truck14","n_support","ColorGreen","W5",""],
		["D_TR16",505,"d_truck15","n_support","ColorGreen","W6",""],
		["D_TR17",506,"d_truck16","n_support","ColorGreen","W7",""]
	];
};
#else
d_p_vecs_blufor = [
	["D_MRR1",0,"d_mobilerespawn1","b_hq","ColorYellow","1",localize "STR_DOM_MISSIONSTRING_12"],["D_MRR2",1,"d_mobilerespawn2","b_hq","ColorYellow","2",localize "STR_DOM_MISSIONSTRING_13"],
	["D_MEDVEC",100,"d_medvec","n_med","ColorGreen","M",""],["D_TR1",200,"d_truck1","n_maint","ColorGreen","R1",""],
	["D_TR2",201,"d_truck2","n_support","ColorGreen","F1",""],["D_TR3",202,"d_truck3","n_support","ColorGreen","A1",""],
	["D_TR6",203,"d_truck4","n_maint","ColorGreen","R2",""],["D_TR5",204,"d_truck5","n_support","ColorGreen","F2",""],
	["D_TR4",205,"d_truck6","n_support","ColorGreen","A2",""],["D_TR7",300,"d_truck7","n_service","ColorGreen","E1",""],
	["D_TR8",301,"d_truck8","n_service","ColorGreen","E2",""],["D_TR9",400,"d_truck9","n_support","ColorGreen","T2",""],
	["D_TR10",401,"d_truck10","n_support","ColorGreen","T1",""]
];
d_p_vecs_opfor = [
	["D_MRRO1",1000,"d_mobilerespawno1","o_hq","ColorYellow","1",localize "STR_DOM_MISSIONSTRING_12"],["D_MRRO2",1001,"d_mobilerespawno2","o_hq","ColorYellow","2",localize "STR_DOM_MISSIONSTRING_13"],
	["D_MEDVECO",1100,"d_medveco","n_med","ColorGreen","M",""],["D_TRO1",1200,"d_trucko1","n_maint","ColorGreen","R1",""],
	["D_TRO2",1201,"d_trucko2","n_support","ColorGreen","F1",""],["D_TRO3",1202,"d_trucko3","n_support","ColorGreen","A1",""],
	["D_TRO6",1203,"d_trucko4","n_maint","ColorGreen","R2",""],["D_TRO5",1204,"d_trucko5","n_support","ColorGreen","F2",""],
	["D_TRO4",1205,"d_trucko6","n_support","ColorGreen","A2",""],["D_TRO7",1300,"d_trucko7","n_service","ColorGreen","E1",""],
	["D_TRO8",1301,"d_trucko8","n_service","ColorGreen","E2",""],["D_TRO9",1400,"d_trucko9","n_support","ColorGreen","T2",""],
	["D_TRO10",1401,"d_trucko10","n_support","ColorGreen","T1",""]
];
#endif


if (hasInterface) then {
	if (d_weather == 1) then {
		0 setOvercast 0;
	};
	
	if (d_with_ai) then {d_current_ai_num = 0};

	// расстояние, на которое игрок должен перевезти других, чтобы получить очки
	d_transport_distance = 500;

	// звание, необходимое для пилотирования вертолёта-эвакуатора обломков
	d_wreck_lift_rank = "LIEUTENANT";

	d_disable_viewdistance = d_ViewdistanceChange == 1;
	
	d_mob_respawns = [];
#ifndef __TT__
	{
		d_mob_respawns pushBack [_x # 0, _x # 6];
	} forEach (d_p_vecs select {_x # 1 < 100});
#else
	d_mob_respawns_blufor = [];
	{
		d_mob_respawns_blufor pushBack [_x # 0, _x # 6];
	} forEach (d_p_vecs_blufor select {_x # 1 < 100});
	d_mob_respawns_opfor = [];
	{
		d_mob_respawns_opfor pushBack [_x # 0, _x # 6];
	} forEach (d_p_vecs_opfor select {_x # 1 < 1100});
#endif

	if (d_with_ai) then {
		// дополнительные здания для найма ИИ-бойцов
		// они должны быть размещены в редакторе, задайте им имя переменной в редакторе
		// обрабатываются только на стороне клиента, то есть урон по этим зданиям не просчитывается (в отличие от стандартного барака ИИ)
		// пример:
		// d_additional_recruit_buildings = [my_ai_building1, my_ai_building2];
		d_additional_recruit_buildings = [];
	};
	
	// d_reserved_slot позволяет добавлять резервные слоты для администраторов
	// если вы заняли этот слот и не вошли в систему (как админ), вас кикнет примерно через 20 секунд после завершения интро
	// по умолчанию проверка отключена, пример: d_reserved_slot = ["d_artop_1"];
	if (isNil "d_reserved_slot") then {
		d_reserved_slot = [];
	};

	// d_uid_reserved_slots и d_uids_for_reserved_slots дают возможность ограничить доступ к слотам
	// вам нужно добавить имена переменных юнитов в d_uid_reserved_slots, а в d_uids_for_reserved_slots — UID разрешенных игроков
	// d_uid_reserved_slots = ["d_alpha_1", "d_bravo_3"];
	// d_uids_for_reserved_slots = ["1234567", "7654321"];
	if (isNil "d_uid_reserved_slots") then {
		d_uid_reserved_slots = [];
		d_uids_for_reserved_slots = [];
	};
	
	if (isNil "d_uids_def_choppers") then {
		// Если массив d_uids_initial_vecs заполнен строками с UID игроков, то игроки, которых нет в этом списке,
		// будут автоматически выбрасываться из изначально размещенных на базе вертолётов и мобильных штабов (MHQ)
		// d_uids_initial_vecs = ["1234567", "7654321"];
		d_uids_def_choppers = [];
	};
	
	// очки, необходимые для получения определенного звания
	// используется даже в версиях без ранговой системы (unranked)
#ifndef __TT__
	if (isNil "d_points_needed") then {
		d_points_needed = [
			10, // Corporal
			30, // Sergeant
			60, // Lieutenant
			90, // Captain
			120, // Major
			150, // Colonel
			300 // General
		];
	};

	if (isNil "d_points_needed_db") then {
		d_points_needed_db = [
			10, // Corporal
			30, // Sergeant
			60, // Lieutenant
			90, // Captain
			120, // Major
			150, // Colonel
			300 // General
		];
	};
#else
	if (isNil "d_points_needed") then {
		d_points_needed = [
			10, // Corporal
			30, // Sergeant
			60, // Lieutenant
			90, // Captain
			120, // Major
			150, // Colonel
			300 // General
		];
	};

	if (isNil "d_points_needed_db") then {
		d_points_needed_db = [
			10, // Corporal
			30, // Sergeant
			60, // Lieutenant
			90, // Captain
			120, // Major
			150, // Colonel
			300 // General
		];
	};
#endif
	// теперь это массив, чтобы игроки могли выбирать разные типы воздушного такси
	if (d_with_airtaxi == 0) then {
		d_taxi_aircrafts =
#ifdef __OWN_SIDE_INDEPENDENT__
			call {
				if (d_pracs) exitWith {
					["PRACS_UH1H","PRACS_CH53","PRACS_Sa330_Puma"]
				};
				if (d_spe) exitWith {
					[]
				};
				["I_Heli_Transport_02_F"]
			};
#endif
#ifdef __OWN_SIDE_BLUFOR__
			call {
				if (d_cup) exitWith {
					["CUP_B_UH60M_US", "CUP_B_MH6J_USA", "CUP_B_CH47F_USA"]
				};
				if (d_gmcwg) exitWith {
					if (d_gmcwgwinter) exitWith {
						["gm_ge_army_ch53g_un"]
					};
					["gm_ge_army_ch53g"]
				};
				if (d_rhs) exitWith {
					["RHS_UH60M2"]
				};
				if (d_unsung) exitWith {
					["uns_UH1H_m60"]
				};
				if (d_vn) exitWith {
					["vn_b_air_uh1c_07_04"]
				};
				if (d_spe) exitWith {
					[]
				};
				["B_T_VTOL_01_infantry_F", "B_Heli_Transport_03_unarmed_F", "B_Heli_Light_01_F", "B_Heli_Transport_01_F"]
			};
#endif
#ifdef __OWN_SIDE_OPFOR__
			call {
				if (d_rhs) exitWith {
					["RHS_Mi8mt_Cargo_vv"]
				};
				if (d_csla) exitWith {
					["CSLA_Mi17"]
				};
				if (d_pracs) exitWith {
					["PRACS_SLA_Mi8amt"]
				};
				["O_T_VTOL_02_infantry_dynamicLoadout_F"]
			};
#endif
#ifdef __TT__
			["O_Heli_Light_02_unarmed_F"];
#endif
	} else {
		d_taxi_aircrafts = [];
	};

	if (isNil "d_launcher_cooldown") then {
		// время перезарядки (кулдаун) для противотанковых пусковых установок игрока. Это значит, что игрок не сможет использовать управляемые ПУ (такие как «Титан») в течение 60 секунд.
		// выпущенный снаряд удаляется, а магазин возвращается обратно в инвентарь игрока.
		// также этот параметр можно изменить в таблице dom_settings базы данных.
		d_launcher_cooldown = d_launcher_cooldownp;
	};
	
	if (d_no_mortar_ar == 1) then {
		(d_remove_from_arsenal # 5) append [{_this isKindOf "Weapon_Bag_Base" || {_this isKindOf "B_Mortar_01_support_F"}}];
	};
};

diag_log [diag_frameno, diag_ticktime, time, "Dom initcommon.sqf processed"];
