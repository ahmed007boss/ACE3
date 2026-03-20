#include "..\script_component.hpp"
/*
 * Author: ACETeam
 * Syncs the stored item state count for a class in a slot to match the actual number
 * of that item in the slot: purges excess state entries when items were removed, and
 * inits missing state entries when items were added.
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Container slot <STRING> ("assigned", "vest", "uniform", "backpack", "equipped", "object")
 * 2: Item classname <STRING>
 *
 * Return Value:
 * None
 *
 * Example:
 * [player, "vest", "ACE_bandage"] call ace_items_fnc_syncItemStateToSlotCount;
 *
 * Public: No
 */

params [
    ["_object", objNull, [objNull]],
    ["_slot", "", [""]],
    ["_className", "", [""]]
];

if (isNull _object || {_slot isEqualTo ""} || {_className isEqualTo ""}) exitWith {};

private _stateObj = [_object, _slot] call FUNC(getStateObject);
if (isNull _stateObj) exitWith {};

// _stateObj = object that carries the state; _stateLocal = object that must be local for state to run
private _stateLocal = [_object, _slot] call FUNC(getStateLocal);
if (isNull _stateLocal || {!local _stateLocal}) exitWith {};

private _allItems = [_object, _slot] call FUNC(getItemsInSlot);
private _countOfClass = count (_allItems select {_x isEqualTo _className});

private _varKey = [_slot, _className] call FUNC(getItemStateVarKey);
private _stateArray = _stateObj getVariable [_varKey, []];

// Purge excess: more state entries than items (e.g. items were removed)
if (count _stateArray > _countOfClass) then {
    _stateArray = _stateArray select [0, _countOfClass];
    _stateObj setVariable [_varKey, _stateArray];
};

// Init missing: fewer state entries than items (e.g. items were added)
if (count _stateArray < _countOfClass && {_countOfClass > 0}) then {
    [_object, _className, _slot, _countOfClass - 1] call FUNC(initItemState);
};
