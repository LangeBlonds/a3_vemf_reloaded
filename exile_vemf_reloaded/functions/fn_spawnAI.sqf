/*
	Author: original by Vampire, completely rewritten by IT07

	Description:
	spawns AI using given _pos and unit/group count.

	Params:
	_this select 0: POSITION - where to spawn the units around
	_this select 1: SCALAR - how many groups to spawn
	_this select 2: SCALAR - how many units to put in each group
	_this select 3: SCALAR - AI mode

	Returns:
	ARRAY of UNITS
*/

private // Make sure that the vars in this function do not interfere with vars in the calling script
[
	"_pos","_grpCount","_unitsPerGrp","_sldrClass","_groups","_settings","_hc","_skills","_newPos","_return","_waypoints","_wp","_cyc","_units",
	"_accuracy","_aimShake","_aimSpeed","_stamina","_spotDist","_spotTime","_courage","_reloadSpd","_commanding","_general","_loadInv","_noHouses","_cal50sVehs","_mode"
];

_spawned = [[],[]];
_pos = param [0, [], [[]]];
if (count _pos isEqualTo 3) then
{
	_grpCount = param [1, 1, [0]];
	if (_grpCount > 0) then
	{
		_unitsPerGrp = param [2, 1, [0]];
		if (_unitsPerGrp > 0) then
		{
			_mode = param [3, -1, [0]];
			_sldrClass = "unitClass" call VEMFr_fnc_getSetting;
			_groups = [];
			_hc = "headLessClientSupport" call VEMFr_fnc_getSetting;
			_aiDifficulty = [["aiSkill"],["difficulty"]] call VEMFr_fnc_getSetting param [0, "Veteran", [""]];
			_skills = [["aiSkill", _aiDifficulty],["accuracy","aimingShake","aimingSpeed","endurance","spotDistance","spotTime","courage","reloadSpeed","commanding","general"]] call VEMFr_fnc_getSetting;
			_accuracy = _skills select 0;
			_aimShake = _skills select 1;
			_aimSpeed = _skills select 2;
			_stamina = _skills select 3;
			_spotDist = _skills select 4;
			_spotTime = _skills select 5;
			_courage = _skills select 6;
			_reloadSpd = _skills select 7;
			_commanding = _skills select 8;
			_general = _skills select 9;

			_houses = nearestTerrainObjects [_pos, ["House"], 200]; // Find some houses to spawn in
			_notTheseHouses = "housesBlackList" call VEMFr_fnc_getSetting;
			_goodHouses = [];
			{ // Filter the houses that are too small for one group
				if not(typeOf _x in _notTheseHouses) then
				{
					if ([_x, _unitsPerGrp] call BIS_fnc_isBuildingEnterable) then
					{
						_goodHouses pushBack _x;
					};
				};
			} forEach _houses;
			_goodHouses = _goodHouses call BIS_fnc_arrayShuffle;
			_noHouses = false;
			if (count _goodHouses < _grpCount) then
			{
				_noHouses = true;
			};

			_cal50s = [["DynamicLocationInvasion"],["cal50s"]] call VEMFr_fnc_getSetting param [0, 3, [0]];
			if (_cal50s > 0) then
			{
				_cal50sVehs = [];
			};
			_units = []; // Define units array. the for loops below will fill it with units
			for "_g" from 1 to _grpCount do // Spawn Groups near Position
			{
				if not _noHouses then
				{
					if (count _goodHouses < 1) then
					{
						_noHouses = true
					};
				};
				private ["_unitSide","_grp","_unit"];
				_unitSide = getText (configFile >> "CfgVehicles" >> ("unitClass" call VEMFr_fnc_getSetting) >> "faction");
				switch _unitSide do
				{
					case "BLU_G_F":
					{
						_grp = createGroup WEST;
					};
					case "CIV_F":
					{
						_grp = createGroup civilian;
					};
					case "IND_F":
					{
						_grp = createGroup independent;
					};
					case "IND_G_F":
					{
						_grp = createGroup resistance;
					};
					case "OPF_F":
					{
						_grp = createGroup EAST;
					};
					default
					{
						["fn_spawnAI", 0, format["Unknown side %1", _unitSide]] spawn VEMFr_fnc_log;
					};
				};
				if not isNil"_grp" then
				{
					if not _noHouses then
					{
						_grp enableAttack false;
					};
					_grp setBehaviour "AWARE";
					_grp setCombatMode "RED";
					_grp allowFleeing 0;
					private ["_house","_housePositions"];
					if not _noHouses then
					{
						_house = selectRandom _goodHouses;
						_houseID = _goodHouses find _house;
						_goodHouses deleteAt _houseID;
						_housePositions = [_house] call BIS_fnc_buildingPositions;
					};

					_placed50 = false;
					for "_u" from 1 to _unitsPerGrp do
					{
						private ["_spawnPos","_hmg"];
						if not _noHouses then
						{
							_spawnPos = selectRandom _housePositions;
							if not _placed50 then
							{
								_placed50 = true;
								if (_cal50s > 0) then
								{
									_hmg = createVehicle ["B_HMG_01_high_F", _spawnPos, [], 0, "CAN_COLLIDE"];
									_hmg setVehicleLock "LOCKEDPLAYER";
									(_spawned select 1) pushBack _hmg;
								};
							};
						};
						if _noHouses then
						{
							_spawnPos = [_pos,20,250,1,0,200,0] call BIS_fnc_findSafePos; // Find Nearby Position
						};

						_unit = _grp createUnit [_sldrClass, _spawnPos, [], 0, "CAN_COLLIDE"]; // Create Unit There
						if not _noHouses then
						{
							doStop _unit;
							if (_cal50s > 0) then
							{
								if not isNil"_hmg" then
								{
									if not isNull _hmg then
									{
										_unit moveInGunner _hmg;
										_hmg = nil;
										_cal50s = _cal50s - 1;
									};
								};
							};

							_houseIndex = _housePositions find _spawnPos;
							_housePositions deleteAt _houseIndex;
						};

						_unit addMPEventHandler ["mpkilled","if (isDedicated) then { [_this select 0, _this select 1] spawn VEMFr_fnc_aiKilled }"];
						(_spawned select 0) pushBack _unit;
						// Set skills
						_unit setSkill ["aimingAccuracy", _accuracy];
						_unit setSkill ["aimingShake", _aimShake];
						_unit setSkill ["aimingSpeed", _aimSpeed];
						_unit setSkill ["endurance", _stamina];
						_unit setSkill ["spotDistance", _spotDist];
						_unit setSkill ["spotTime", _spotTime];
						_unit setSkill ["courage", _courage];
						_unit setSkill ["reloadSpeed", _reloadSpd];
						_unit setSkill ["commanding", _commanding];
						_unit setSkill ["general", _general];
						_unit setRank "Private"; // Set rank
					};
					_grp selectLeader _unit; // Leader Assignment
					_groups pushBack _grp; // Push it into the _groups array
				};
			};

			_invLoaded = [_spawned select 0, "Invasion", _mode] call VEMFr_fnc_loadInv; // Load the AI's inventory
			if isNil"_invLoaded" then
			{
				["fn_spawnAI", 0, "failed to load AI's inventory..."] spawn VEMFr_fnc_log;
			};

			if (count _groups isEqualTo _grpCount) then
			{
				if not _noHouses then
				{
					{
						[_x] spawn VEMFr_fnc_signAI;
					} forEach _groups;
				};
				if _noHouses then
				{
					_waypoints =
					[
						[(_pos select 0), (_pos select 1)+50, 0],
						[(_pos select 0)+50, (_pos select 1), 0],
						[(_pos select 0), (_pos select 1)-50, 0],
						[(_pos select 0)-50, (_pos select 1), 0]
					];
					{ // Make them Patrol
						for "_z" from 1 to (count _waypoints) do
						{
							_wp = _x addWaypoint [(_waypoints select (_z-1)), 10];
							_wp setWaypointType "SAD";
							_wp setWaypointCompletionRadius 20;
						};
						_cyc = _x addWaypoint [_pos,10];
						_cyc setWaypointType "CYCLE";
						_cyc setWaypointCompletionRadius 20;
						[_x] spawn VEMFr_fnc_signAI;
					} forEach _groups;
				};
			};
		};
	};
};
_spawned
