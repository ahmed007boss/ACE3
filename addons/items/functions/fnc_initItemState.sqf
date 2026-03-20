#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Initializes a fresh item state HashMap on the correct state object.
 * For assigned items state is stored on the unit.
 * For vest/uniform/backpack items state is stored on the container object.
 * For items in world containers (boxes, vehicles, nested) pass the container object directly as _unit.
 * Returns existing state unchanged if it already exists at the given index.
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Item classname <STRING>
 * 2: Container slot <STRING> ("assigned", "vest", "uniform", "backpack", "equipped") or "object" for non-unit containers
 * 3: Item index <NUMBER> (default: 0)
 *
 * Return Value:
 * Initialized item state HashMap <ARRAY> (CBA HashMap)
 *
 * Example:
 * [player, "ACE_DAGR", "vest", 0] call ace_items_fnc_initItemState;
 * [someBox, "ACE_DAGR", "object", 0] call ace_items_fnc_initItemState;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_className", "", [""]],
    ["_slot", "", [""]],
    ["_index", 0, [0]]
];

//TRACE_4("initItemState",_unit,_className,_slot,_index);

if (isNull _unit || {_className isEqualTo ""} || {_slot isEqualTo ""}) exitWith {
    WARNING_3("initItemState EXIT bad params: unit=%1 class=%2 slot=%3",_unit,_className,_slot);
    nil
};

private _stateObj = [_unit, _slot] call FUNC(getStateObject);
if (isNull _stateObj) exitWith {
    WARNING_2("initItemState EXIT null stateObj: unit=%1 slot=%2",_unit,_slot);
    nil
};

// _stateObj = object that carries the state; _stateLocal = object that must be local for state to run (unit for person slots, else container)
private _stateLocal = [_unit, _slot] call FUNC(getStateLocal);
if (isNull _stateLocal || {!(local _stateLocal)}) exitWith {
    //TRACE_1("initItemState remoteExec",_stateLocal);
    [QGVAR(initItemState_remote), [_unit, _className, _slot, _index], _stateLocal] call CBA_fnc_targetEvent;
    nil
};

private _varKey = [_slot, _className] call FUNC(getItemStateVarKey);
private _stateArray = _stateObj getVariable [_varKey, []];

while {count _stateArray <= _index} do {
    private _stateIndex = count _stateArray;
    private _state = [[
        [I_KEY_ITEM_STATE_CLASSNAME, _className],
        [I_KEY_ITEM_STATE_INVENTORY_SLOT, _slot]
    ]] call CBA_fnc_hashCreate;

    _stateArray pushBack _state;
    _stateObj setVariable [_varKey, _stateArray];

    [QGVAR(itemStateInitialized), [_unit, _className, _slot, _stateIndex, _state]] call CBA_fnc_localEvent;
};

//TRACE_2("initItemState DONE",_slot,_index);
_stateArray select _index
