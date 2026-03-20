#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Updates the item state HashMap on the correct state object at a specific index.
 * Writes to the machine where the state object is local.
 * If the state object is not local, remoteExecs to the correct machine.
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Item classname <STRING>
 * 2: Container slot <STRING> ("assigned", "vest", "uniform", "backpack", "equipped") or "object"
 * 3: Item index <NUMBER> (default: 0)
 * 4: Key-value pairs to update <ARRAY> ([[key, value], ...])
 *
 * Return Value:
 * Updated item state HashMap <ARRAY> (CBA HashMap) or nil if remote
 *
 * Example:
 * [player, "ACE_DAGR", "vest", 0, [["powerMode", "on"]]] call ace_items_fnc_setItemState;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_className", "", [""]],
    ["_slot", "", [""]],
    ["_index", 0, [0]],
    ["_updates", [], [[]]]
];

//TRACE_4("setItemState",_unit,_className,_slot,_index);

if (isNull _unit || {_className isEqualTo ""} || {_slot isEqualTo ""}) exitWith {
    WARNING_3("setItemState EXIT bad params: unit=%1 class=%2 slot=%3",_unit,_className,_slot);
    nil
};

private _stateObj = [_unit, _slot] call FUNC(getStateObject);
if (isNull _stateObj) exitWith {
    WARNING_2("setItemState EXIT null stateObj: unit=%1 slot=%2",_unit,_slot);
    nil
};

// _stateObj = object that carries the state; _stateLocal = object that must be local for state to run (unit for person slots, else container)
private _stateLocal = [_unit, _slot] call FUNC(getStateLocal);
if (isNull _stateLocal || {!(local _stateLocal)}) exitWith {
    TRACE_1("setItemState remoteExec",_stateLocal);
    [QGVAR(setItemState_remote), [_unit, _className, _slot, _index, _updates], _stateLocal] call CBA_fnc_targetEvent;
    nil
};

// Sync state count to slot so we don't write at a stale index (e.g. after items were removed)
[_unit, _slot, _className] call FUNC(syncItemStateToSlotCount);

private _state = [_unit, _className, _slot, _index] call FUNC(initItemState);
if (isNil "_state") exitWith {
    WARNING_1("setItemState EXIT initItemState nil: unit=%1",_unit);
    nil
};

private _varKey = [_slot, _className] call FUNC(getItemStateVarKey);
private _stateArray = _stateObj getVariable [_varKey, []];

{
    _x params ["_key", "_value"];
    _state = [_state, _key, _value] call CBA_fnc_hashSet;
} forEach _updates;

_stateArray set [_index, _state];
_stateObj setVariable [_varKey, _stateArray];

//TRACE_3("setItemState DONE",_unit,_className,_slot);
_state
