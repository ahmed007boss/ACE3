#include "script_component.hpp"

ADDON = false;

PREP_RECOMPILE_START;
#include "XEH_PREP.hpp"
PREP_RECOMPILE_END;

#include "initSettings.inc.sqf"

// Caches for static item config lookups (HashMap)
GVAR(destroyableInfoCache) = createHashMap;
GVAR(usableRestrictionsCache) = createHashMap;

// Remote event: setItemState called on a machine where state object is not local
[QGVAR(setItemState_remote), {
    params ["_unit", "_className", "_slot", "_index", "_updates"];
    [_unit, _className, _slot, _index, _updates] call FUNC(setItemState);
}] call CBA_fnc_addEventHandler;

// Remote event: initItemState called on the machine that owns the state (unit for person slots, container otherwise)
[QGVAR(initItemState_remote), {
    params ["_unit", "_className", "_slot", "_index"];
    [_unit, _className, _slot, _index] call FUNC(initItemState);
}] call CBA_fnc_addEventHandler;

// Remote event: removeItemState called on a machine where state object is not local
[QGVAR(removeItemState_remote), {
    params ["_unit", "_className", "_slot"];
    [_unit, _className, _slot] call FUNC(removeItemState);
}] call CBA_fnc_addEventHandler;

// Remote event: push state onto a destination object (write side of cross-machine migration)
[QGVAR(pushItemState), {
    params ["_destObj", "_className", "_destSlot", "_stateArray"];
    [_destObj, _className, _destSlot, _stateArray] call FUNC(pushItemState);
}] call CBA_fnc_addEventHandler;

// Remote event: full migration delegated to source machine
[QGVAR(migrateItemState_remote), {
    params ["_srcObj", "_destObj", "_className", "_srcSlot", "_destSlot"];
    [_srcObj, _destObj, _className, _srcSlot, _destSlot] call FUNC(migrateItemState);
}] call CBA_fnc_addEventHandler;

// Remote event: container own-state push
[QGVAR(pushContainerOwnState), {
    params ["_obj", "_key", "_state"];
    if !(local _obj) exitWith {};
    _obj setVariable [_key, _state];
}] call CBA_fnc_addEventHandler;

// Remote event: migrateContainerItemState delegated to container's local machine
[QGVAR(migrateContainerItemState_remote), {
    params ["_unit", "_containerObj", "_slot", "_direction"];
    [_unit, _containerObj, _slot, _direction] call FUNC(migrateContainerItemState);
}] call CBA_fnc_addEventHandler;

// Build a HashMap<string hitpointName, array<classname>> for all destroyable items
private _allItems = "getNumber (_x >> 'scope') > 0" configClasses (configFile >> "CfgWeapons");
private _itemsHitParts = [] call CBA_fnc_hashCreate;
private _cfgDestroyableItemInfo = configNull;


[QEGVAR(medical,woundReceived), {
    params ["_unit", "_damages", "_shooter", "_ammo"];
    if (!local _unit) exitWith {};
    if (!isClass(configFile >> "CfgAmmo" >> _ammo) ) exitWith {};
        
    private _damageType = getText (configFile >> "CfgAmmo" >> _ammo >> "ACE_damageType");
    if !(_damageType in ["bullet", "grenade", "explosive"]) exitWith {};
    // Delegate damage selection and item handling to onBodyHit
    [_unit, _damages, _shooter, _ammo] call FUNC(onBodyHit);
}] call CBA_fnc_addEventHandler;



ADDON = true;
