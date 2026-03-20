#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Takes a full snapshot of all container contents for a unit and an optional external container.
 * Snapshot is stored as a HashMap keyed by container netId.
 * Used by the inventory diff system to detect item movements.
 *
 * Arguments:
 * 0: Object to snapshot — either a CAManBase unit (all inventory slots) or an external container <OBJECT>
 *
 * Return Value:
 * Snapshot HashMap <ARRAY> (CBA HashMap)
 * Keys: container netId <STRING>
 * Values: [slotName <STRING>, itemsList <ARRAY>]
 *
 * Example:
 * [player] call ace_items_fnc_Inventory_snapshotContainer;
 *
 * Public: No
 */

params [
    ["_obj", objNull, [objNull]]
];

if (isNull _obj) exitWith {
    WARNING_1("Inventory_snapshotContainer EXIT null unit, returning empty hash: unit=%1",_obj);
    [] call CBA_fnc_hashCreate
};

private _snapshot = [] call CBA_fnc_hashCreate;

// Helper to add a container to the snapshot.
// _keyObj: object whose netId identifies this container in the snapshot
// _itemsObj: object to read items from for the given slot (unit or container)
// In SP netId returns "" for all objects, so use slotName as key when netId is empty to avoid overwriting.
private _fnc_addToSnapshot = {
    params ["_keyObj", "_itemsObj", "_slotName"];
    if (isNull _keyObj || {isNull _itemsObj}) exitWith {};
    private _items = [_itemsObj, _slotName] call FUNC(getItemsInSlot);
    private _netId = netId _keyObj;
    // Use slotName for unit (CAManBase) to prevent SLOT_ASSIGNED/EQUIPPED/WEAPONS all
    // colliding on the same netId in MP. Container objects have unique netIds and use those.
    private _key = [_netId, _slotName] select ((_netId isEqualTo "") || {_keyObj isKindOf "CAManBase"});
    [_snapshot, _key, [_slotName, _items]] call CBA_fnc_hashSet;
    TRACE_3("Inventory_snapshotContainer add",_key,_slotName,count _items);
};

if (_obj isKindOf "CAManBase") then {
    private _unit = _obj;
    // Unit-linked slots keyed by unit itself
    [_unit, _unit, SLOT_ASSIGNED]                call _fnc_addToSnapshot;
    [_unit, _unit, SLOT_EQUIPPED]                call _fnc_addToSnapshot;
    [_unit, _unit, SLOT_WEAPONS]                 call _fnc_addToSnapshot;
    // Items seated in each weapon (magazine, optic, silencer, bipod)
    [_unit, _unit, SLOT_PRIMARY_WEAPON_ITEMS]    call _fnc_addToSnapshot;
    [_unit, _unit, SLOT_SECONDARY_WEAPON_ITEMS]  call _fnc_addToSnapshot;
    [_unit, _unit, SLOT_HANDGUN_WEAPON_ITEMS]    call _fnc_addToSnapshot;
    [_unit, _unit, SLOT_BINOCULAR_ITEMS]         call _fnc_addToSnapshot;
    // Inventory containers keyed by their container objects, items read from unit inventory
    [vestContainer _unit,    _unit, SLOT_VEST_CONTAINER]     call _fnc_addToSnapshot;
    [uniformContainer _unit, _unit, SLOT_UNIFORM_CONTAINER]  call _fnc_addToSnapshot;
    [backpackContainer _unit,_unit, SLOT_BACKPACK_CONTAINER] call _fnc_addToSnapshot;
} else {
    // Generic external container: key and items both on the same object
    [_obj, _obj, SLOT_OBJECT] call _fnc_addToSnapshot;
};


TRACE_1("Inventory_snapshotContainer %1 DONE",_obj);
_snapshot
