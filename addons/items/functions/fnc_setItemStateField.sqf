#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Sets the value of a specific field in an item state HashMap.
 * Auto-initializes state if it does not exist.
 * Locality-aware — remoteExecs if state object is not local.
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Item classname <STRING>
 * 2: Container slot <STRING> ("assigned", "vest", "uniform", "backpack", "equipped") or "object"
 * 3: Item index <NUMBER> (default: 0)
 * 4: Field key <STRING>
 * 5: Value <ANY>
 *
 * Return Value:
 * Updated item state HashMap <ARRAY> (CBA HashMap) or nil if remote
 *
 * Example:
 * [player, "ACE_DAGR", "vest", 0, "powerMode", "on"] call ace_items_fnc_setItemStateField;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_className", "", [""]],
    ["_slot", "", [""]],
    ["_index", 0, [0]],
    ["_field", "", [""]],
    ["_value", nil]
];

//TRACE_4("setItemStateField",_unit,_className,_slot,_field);
[_unit, _className, _slot, _index, [[_field, _value]]] call FUNC(setItemState);
// Return value comes from setItemState (updated state or nil if remote)
