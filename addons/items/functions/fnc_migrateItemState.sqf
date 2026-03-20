#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Migrates one item's state from a source container object to a destination container object.
 * Fully locality-aware:
 *   - If both objects are local: direct migrate
 *   - If source is local, dest is remote: read locally, clear locally, push to dest machine
 *   - If source is remote, dest is local: request source machine to read and push here
 *   - If both are remote: request source machine to handle the full migration
 *
 * Arguments:
 * 0: Source container object <OBJECT>
 * 1: Destination container object <OBJECT>
 * 2: Item classname <STRING>
 * 3: Source slot <STRING> ("assigned", "vest", "uniform", "backpack", "equipped", "object")
 * 4: Destination slot <STRING>
 *
 * Return Value:
 * Migrated item state HashMap <ARRAY> or nil if remote
 *
 * Example:
 * [vestContainerObj, backpackContainerObj, "ACE_DAGR", "vest", "backpack"] call ace_items_fnc_migrateItemState;
 *
 * Public: Yes
 */

params [
    ["_srcObj", objNull, [objNull]],
    ["_destObj", objNull, [objNull]],
    ["_className", "", [""]],
    ["_srcSlot", "", [""]],
    ["_destSlot", "", [""]]
];

TRACE_5("migrateItemState",_srcObj,_destObj,_className,_srcSlot,_destSlot);

if (isNull _srcObj || {isNull _destObj} || {_className isEqualTo ""}) exitWith {
    WARNING_3("migrateItemState EXIT bad params: src=%1 dest=%2 class=%3",_srcObj,_destObj,_className);
    nil
};

// Same object same slot — nothing to do
if (_srcObj isEqualTo _destObj && {_srcSlot isEqualTo _destSlot}) exitWith {
    TRACE_3("migrateItemState EXIT same obj same slot",_srcObj,_destObj,_srcSlot);
    nil
};

// _srcStateObj / _destStateObj = objects that carry the state; _srcStateLocal / _destStateLocal = objects that must be local for state to run (for this API callers pass state objects; for person slots the container is on the unit's machine)
private _srcStateObj  = _srcObj;
private _destStateObj = _destObj;
private _srcStateLocal  = _srcStateObj;
private _destStateLocal = _destStateObj;

private _srcLocal  = local _srcStateLocal;
private _destLocal = local _destStateLocal;

// Both remote — delegate entirely to source machine
if (!_srcLocal && !_destLocal) exitWith {
    TRACE_2("migrateItemState EXIT both remote, delegating",_srcObj,_destObj);
    [QGVAR(migrateItemState_remote), [_srcObj, _destObj, _className, _srcSlot, _destSlot], _srcStateLocal] call CBA_fnc_targetEvent;
    nil
};

// Source remote — ask source machine to read and push to us
if (!_srcLocal && _destLocal) exitWith {
    TRACE_2("migrateItemState EXIT src remote, delegating",_srcObj,_destObj);
    [QGVAR(migrateItemState_remote), [_srcObj, _destObj, _className, _srcSlot, _destSlot], _srcStateLocal] call CBA_fnc_targetEvent;
    nil
};

// Source is local from here — read and clear state from source
private _srcVarKey = [_srcSlot, _className] call FUNC(getItemStateVarKey);
private _srcStates = _srcStateObj getVariable [_srcVarKey, []];

if (_srcStates isEqualTo []) exitWith {
    TRACE_2("migrateItemState: no state found on source",_srcStateObj,_className);
    nil
};

// Take one state entry (last in, first out)
private _state = _srcStates deleteAt ((count _srcStates) - 1);
_srcStateObj setVariable [_srcVarKey, [_srcStates, nil] select (_srcStates isEqualTo [])];

// Update the container field in state
_state = [_state, I_KEY_ITEM_STATE_INVENTORY_SLOT, _destSlot] call CBA_fnc_hashSet;

// Destination local — clear any stale state first, then write migrated state at index 0
if (_destLocal) then {
    private _destVarKey = [_destSlot, _className] call FUNC(getItemStateVarKey);
    _destStateObj setVariable [_destVarKey, [_state]];
    TRACE_3("migrateItemState: local->local done",_className,_srcSlot,_destSlot);
} else {
    // Destination remote — push state to dest machine (pushItemState will overwrite stale state)
    [QGVAR(pushItemState), [_destObj, _className, _destSlot, [_state]], _destStateLocal] call CBA_fnc_targetEvent;
    TRACE_3("migrateItemState: local->remote pushed",_className,_srcSlot,_destSlot);
};

_state
