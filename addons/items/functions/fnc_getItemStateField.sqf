#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns the value of a specific field from an item state HashMap.
 * Returns a default value if the field or state does not exist.
 *
 * Arguments:
 * 0: Target object <OBJECT>
 * 1: Item classname <STRING>
 * 2: Container <STRING> ("assigned", "vest", "uniform", "backpack")
 * 3: Item index <NUMBER> (default: 0)
 * 4: Field key <STRING>
 * 5: Default value <ANY>
 *
 * Return Value:
 * Field value <ANY>
 *
 * Example:
 * [ACE_player, "ACE_DAGR", "vest", 0, "powerMode", "device off"] call ace_items_fnc_getItemStateField;
 *
 * Public: Yes
 */

params ["_targetObj", "_className", "_slot", ["_index", 0, [0]], "_field", "_default"];
TRACE_6("params",_targetObj,_className,_slot,_index,_field,_default);

private _state = [_targetObj, _className, _slot, _index] call FUNC(getItemState);

if (isNil "_state") exitWith { _default };
if !([_state, _field] call CBA_fnc_hashHasKey) exitWith { _default };

[_state, _field] call CBA_fnc_hashGet
