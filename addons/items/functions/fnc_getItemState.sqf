#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns the item state HashMap at a specific index from the correct state object.
 * For assigned/equipped items reads from the unit. For vest/uniform/backpack items reads from the container object.
 * For items in world containers (boxes, vehicles) pass the container object directly as _object.
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Item classname <STRING>
 * 2: Container slot <STRING> ("assigned", "vest", "uniform", "backpack", "equipped") or "object"
 * 3: Item index <NUMBER> (default: 0)
 *
 * Return Value:
 * Item state HashMap <ARRAY> (CBA HashMap) or nil if not found
 *
 * Example:
 * [player, "ACE_DAGR", "vest", 0] call ace_items_fnc_getItemState;
 * [player, "ACE_NVG_Gen1", "assigned", 0] call ace_items_fnc_getItemState;
 * [player, vest player, "equipped", 0] call ace_items_fnc_getItemState;
 * [someBox, "ACE_DAGR", "object", 0] call ace_items_fnc_getItemState;
 *
 * Public: Yes
 */

params [
    ["_object", objNull, [objNull]],
    ["_className", "", [""]],
    ["_slot", "", [""]],
    ["_index", 0, [0]]
];

// Reject invalid inputs
if (isNull _object || {_className isEqualTo ""} || {_slot isEqualTo ""}) exitWith { nil };

// Resolve where state is stored: unit for assigned/equipped, container object for vest/uniform/backpack/object
private _stateObj = [_object, _slot] call FUNC(getStateObject);
if (isNull _stateObj) exitWith { nil };

// _stateLocal = object that must be local for state to run; only read on that machine
private _stateLocal = [_object, _slot] call FUNC(getStateLocal);
if (isNull _stateLocal || {!(local _stateLocal)}) exitWith { nil };

// State is stored as an array of HashMaps per class: ACE_<slot>_itemStates_<className>
private _varKey = [_slot, _className] call FUNC(getItemStateVarKey);
private _stateArray = _stateObj getVariable [_varKey, []];

// Sync state count to actual item count in slot (purge excess, init missing)
[_object, _slot, _className] call FUNC(syncItemStateToSlotCount);
_stateArray = _stateObj getVariable [_varKey, []];

// Return state at index or nil if out of range
if (_stateArray isEqualTo [] || {_index >= count _stateArray}) exitWith { nil };

_stateArray select _index
