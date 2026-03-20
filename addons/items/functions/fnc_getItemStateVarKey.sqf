#include "..\script_component.hpp"
/*
 * Author: ACETeam
 * Returns the variable key used to store item state array on the state object.
 * Key format: ACE_<slot>_itemStates_<className>
 *
 * Arguments:
 * 0: Slot <STRING> ("assigned", "equipped", "vest", "uniform", "backpack", "object")
 * 1: Item classname <STRING>
 *
 * Return Value:
 * Variable key <STRING>
 *
 * Example:
 * ["vest", "ACE_bandage"] call ace_items_fnc_getItemStateVarKey;
 *
 * Public: No
 */

params [
    ["_slot", "", [""]],
    ["_className", "", [""]]
];

format [QGVAR(ACE_%1_itemStates_%2), _slot, _className]
