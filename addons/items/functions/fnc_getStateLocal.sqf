#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns the object whose locality determines where item state for this slot runs.
 * For person slots (assigned, equipped, vest, uniform, backpack) state runs on the unit's machine.
 * For other containers (e.g. "object") state runs on the container object's machine.
 * Use with _stateObj: _stateObj is the object that carries the state (getVariable/setVariable);
 * _stateLocal is the object that must be local for state read/write to run on this machine.
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Container slot <STRING> ("assigned", "vest", "uniform", "backpack", "equipped") or "object"
 *
 * Return Value:
 * Object that must be local for state to run <OBJECT> (unit for person slots, else state object)
 *
 * Example:
 * [player, "vest"] call ace_items_fnc_getStateLocal;
 *
 * Public: No
 */

params [
    ["_object", objNull, [objNull]],
    ["_slot", "", [""]]
];

private _stateObj = [_object, _slot] call FUNC(getStateObject);
if (isNull _stateObj) exitWith { objNull };

// Person slots: state runs on the unit's machine; else on the container's machine
// Use select for constant return branches for better performance
[_stateObj, _object] select (_slot in SLOTS_ALL)
