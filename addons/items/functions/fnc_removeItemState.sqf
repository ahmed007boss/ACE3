#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Removes all item state for a given item classname from the correct state object.
 * Locality-aware — remoteExecs if state object is not local.
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Item classname <STRING>
 * 2: Container slot <STRING> ("assigned", "vest", "uniform", "backpack", "equipped") or "object"
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * [player, "ACE_DAGR", "vest"] call ace_items_fnc_removeItemState;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_className", "", [""]],
    ["_slot", "", [""]]
];

TRACE_3("removeItemState",_unit,_className,_slot);

if (isNull _unit || {_className isEqualTo ""} || {_slot isEqualTo ""}) exitWith {
    WARNING_3("removeItemState EXIT bad params: unit=%1 class=%2 slot=%3",_unit,_className,_slot);
};

private _stateObj = [_unit, _slot] call FUNC(getStateObject);
if (isNull _stateObj) exitWith {
    WARNING_2("removeItemState EXIT null stateObj: unit=%1 slot=%2",_unit,_slot);
};

// _stateObj = object that carries the state; _stateLocal = object that must be local for state to run (unit for person slots, else container)
private _stateLocal = [_unit, _slot] call FUNC(getStateLocal);
if (isNull _stateLocal || {!(local _stateLocal)}) exitWith {
    TRACE_1("removeItemState remoteExec",_stateLocal);
    [QGVAR(removeItemState_remote), [_unit, _className, _slot], _stateLocal] call CBA_fnc_targetEvent;
};

private _varKey = [_slot, _className] call FUNC(getItemStateVarKey);
_stateObj setVariable [_varKey, nil];
TRACE_3("removeItemState DONE",_unit,_className,_slot);
