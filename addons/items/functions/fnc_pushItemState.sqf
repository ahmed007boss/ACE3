#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Receives a pushed item state from another machine and writes it onto the destination object.
 * Always called via CBA_fnc_targetEvent on the machine where the destination object is local.
 * This is the write-side of cross-machine state migration.
 *
 * Arguments:
 * 0: Destination container object <OBJECT>
 * 1: Item classname <STRING>
 * 2: Destination slot <STRING>
 * 3: State array to write <ARRAY>
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * Called via CBA_fnc_targetEvent only, not directly.
 *
 * Public: No
 */

params [
    ["_destObj", objNull, [objNull]],
    ["_className", "", [""]],
    ["_destSlot", "", [""]],
    ["_stateArray", [], [[]]]
];

TRACE_4("pushItemState ENTRY",_destObj,_className,_destSlot,_stateArray);

if (isNull _destObj || {_className isEqualTo ""} || {_stateArray isEqualTo []}) exitWith {
    WARNING_3("pushItemState EXIT bad params: destObj=%1 class=%2 stateArray=%3",_destObj,_className,_stateArray);
};
if !(local _destObj) exitWith {
    WARNING_2("pushItemState: destObj not local on this machine: %1 %2",_destObj,_className);
};

private _varKey = [_destSlot, _className] call FUNC(getItemStateVarKey);

// Update the inventoryContainer field in each state to reflect new slot
{
    _x = [_x, I_KEY_ITEM_STATE_INVENTORY_SLOT, _destSlot] call CBA_fnc_hashSet;
} forEach _stateArray;

// Overwrite any stale state — migrated state always wins
_destObj setVariable [_varKey, _stateArray];

TRACE_3("pushItemState DONE written",_destObj,_className,_destSlot);
