#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Applies destroy-on-hit logic to items when a unit takes body damage.
 *
 * Called from the ACE medical_engine woundReceived event via items/XEH_preInit.sqf:
 * [unit, damages, shooter, ammoType] call ace_items_fnc_onBodyHit;
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Damages <ARRAY> (medical-engine damage entries, already sorted by relevance)
 * 2: Shooter <OBJECT>
 * 3: Ammo classname or damage type <STRING>
 *
 * Public: No
 */

params ["_unit", "_damages", "_shooter", "_ammoType"];
if !(local _unit) exitWith {};
if (_shooter isEqualTo _unit) exitWith {};

private _paramType= typeName _damages;
private _bodyPart = "";

if (_paramType == "STRING") then {
    _bodyPart = _damages;
}; 
if (_paramType == "ARRAY") then {
    // _damages is already sorted by medical so the first entries are the most relevant.
    // We only care about the first entry with a usable body part (not empty / structural).
    private _selected = [];

    {
        _x params ["_damage", "_bodyPart"];
        if (_bodyPart isNotEqualTo "" && {(toLowerANSI _bodyPart) != "#structural"}) exitWith {
            _selected = _x;
        };
    } forEach _damages;

    // Fallback: if we didn't find a non-structural body part, use the very first damage entry (if any)
    if (_selected isEqualTo [] && {_damages isNotEqualTo []}) then {
        _selected = _damages select 0;
    };

    if (_selected isEqualTo []) exitWith {};
    _bodyPart = _selected select 1;
};


if (_bodyPart isEqualTo "") exitWith {};
// Per-unit cooldown to avoid destroying multiple items in rapid succession
private _cooldown = 2; // seconds
private _now = CBA_missionTime;
private _lastDestroyTime = _unit getVariable [QGVAR(lastItemDestroyOnHitTime), -1];
if (_lastDestroyTime >= 0 && {_now - _lastDestroyTime < _cooldown}) exitWith {};

// Check if the shot is from the back of the unit  if unit is prone or unit and shooter are facing each other
private _isBackShot = (stance _unit isEqualTo "PRONE") || {
	_shooter isNotEqualTo objNull && {
		_unit isNotEqualTo objNull && {
			private _dir = _unit getRelDir _shooter;
			_dir > 150 && {_dir < 240}
		}
	}
};

// Helper: build a HashMap<string slot, array<classname>> of potentially damageable items
private _fnc_getDamageableItems = {
    params ["_unitLocal", "_bodyPartLocal", "_isBackShotLocal"];

    private _map = [] call CBA_fnc_hashCreate;

    private _add = {
        params ["_hash", "_slot", "_items"];      
        private _existing = [_hash, _slot] call CBA_fnc_hashGet;
        if (isNil "_existing") then {
            _existing = [];
        };
        _existing append _items;
        _existing = _existing arrayIntersect _existing;
        [_hash, _slot, _existing] call CBA_fnc_hashSet;
    };

    switch (toLowerANSI _bodyPartLocal) do {
        case "head": {
            // Head hits: assigned headgear/goggles/HMD
            [_map, SLOT_ASSIGNED, [headgear _unitLocal, goggles _unitLocal, hmd _unitLocal]] call _add;
        };
        case "arms": {
            // Generic arms hit: treat like uniform
            [_map, SLOT_EQUIPPED, [uniform _unitLocal]] call _add;
            [_map, SLOT_UNIFORM_CONTAINER, [_unitLocal, SLOT_UNIFORM_CONTAINER] call FUNC(getItemsInSlot)] call _add;
        };
        case "leftarm": {
            // Left arm: uniform + uniform contents + wrist items (watches)
            [_map, SLOT_EQUIPPED, [uniform _unitLocal]] call _add;
            [_map, SLOT_UNIFORM_CONTAINER, [_unitLocal, SLOT_UNIFORM_CONTAINER] call FUNC(getItemsInSlot)] call _add;
            [_map, SLOT_ASSIGNED, (assignedItems _unitLocal) select { _x isKindOf "ItemWatch" }] call _add;
        };
        case "rightarm": {
            [_map, SLOT_EQUIPPED, [uniform _unitLocal]] call _add;
            [_map, SLOT_UNIFORM_CONTAINER, [_unitLocal, SLOT_UNIFORM_CONTAINER] call FUNC(getItemsInSlot)] call _add;
            // Right arm may also hold the current weapon
            switch (currentWeapon _unitLocal) do {
                case primaryWeapon _unitLocal: {
                    [_map, SLOT_PRIMARY_WEAPON_ITEMS, primaryWeaponItems _unitLocal] call _add;
                };
                case secondaryWeapon _unitLocal: {
                    [_map, SLOT_SECONDARY_WEAPON_ITEMS, secondaryWeaponItems _unitLocal] call _add;
                };
                case handgunWeapon _unitLocal: {
                    [_map, SLOT_HANDGUN_WEAPON_ITEMS, handgunItems _unitLocal] call _add;
                };
                case binocular _unitLocal: {
                    [_map, SLOT_BINOCULAR_ITEMS, binocularItems _unitLocal] call _add;
                };
            };
            [_map, SLOT_WEAPONS, [currentWeapon _unitLocal]] call _add;
        };
        case "body": {
            if (_isBackShotLocal) then {
                // Weapons on backpack (rifle and launcher)
                [_map, SLOT_WEAPONS, [primaryWeapon _unitLocal, secondaryWeapon _unitLocal] select {
                    _x isNotEqualTo "" && {_x isNotEqualTo currentWeapon _unitLocal}
                }] call _add;
            };

            if (_isBackShotLocal && {(backpack _unitLocal) isNotEqualTo ""}) then {
                // Back shot: prefer backpack and its contents
                [_map, SLOT_EQUIPPED, [backpack _unitLocal]] call _add;
                [_map, SLOT_BACKPACK_CONTAINER, [_unitLocal, SLOT_BACKPACK_CONTAINER] call FUNC(getItemsInSlot)] call _add;
            } else {
                if ((vest _unitLocal) isNotEqualTo "") then {
                    // Front/side body with vest: vest and its contents
                    [_map, SLOT_EQUIPPED, [vest _unitLocal]] call _add;
                    [_map, SLOT_VEST_CONTAINER, [_unitLocal, SLOT_VEST_CONTAINER] call FUNC(getItemsInSlot)] call _add;
                } else {
                    // No vest: uniform and its contents
                    [_map, SLOT_EQUIPPED, [uniform _unitLocal]] call _add;
                    [_map, SLOT_UNIFORM_CONTAINER, [_unitLocal, SLOT_UNIFORM_CONTAINER] call FUNC(getItemsInSlot)] call _add;
                };
            };
        };
        case "legs";
        case "leftleg";
        case "rightleg": {
            // Legs: uniform and its contents
            [_map, SLOT_EQUIPPED, [uniform _unitLocal]] call _add;
            [_map, SLOT_UNIFORM_CONTAINER, [_unitLocal, SLOT_UNIFORM_CONTAINER] call FUNC(getItemsInSlot)] call _add;
        };
        default {
            // Non-localised damage: nothing special beyond the container scans
        };
    };

    _map
};

// Build map of candidate items
private _map = [_unit, _bodyPart, _isBackShot] call _fnc_getDamageableItems;

// Nothing to do if no slots/items were collected
if (([_map] call CBA_fnc_hashSize) <= 0) exitWith {};

private _itemDestroyed = false;
// Iterate slots, then items inside each slot
{
    private _slot = _x;
    private _items = [_map, _slot] call CBA_fnc_hashGet;
    {
        private _itemClass = _x;
        if ([_unit, _itemClass, _slot, -1,[_shooter, _bodyPart, _ammoType,_isBackShot]] call FUNC(tryDestroyItem)) exitWith {
            _itemDestroyed = true;
        };
    } forEach _items;
    if (_itemDestroyed) exitWith {};
} forEach ([_map] call CBA_fnc_hashKeys);

if (_itemDestroyed) then {
    _unit setVariable [QGVAR(lastItemDestroyOnHitTime), _now];
};
