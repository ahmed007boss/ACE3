#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Checks if a given item classname defines any ACE_DestroyableItemInfo.
 *
 * Arguments:
 * 0: Item classname <STRING>
 *
 * Return Value:
 * Is destroyable item <BOOL>
 *
 * Example:
 * ["ACE_microDAGR"] call ace_items_fnc_isDestroyableItem;
 *
 * Public: False
 */

params [["_className", "", [""]]];

private _info = [_className] call FUNC(getDestroyableItemInfo);

// Treat an item as destroyable if it has any meaningful destroyable-item info:
// - a destroyed replacement class, OR sounds, OR a CanDestroy/OnDestroyed callback.
_info params [
    "_destroyedClass",
    "_destroyingSounds",
    "_destroyingAmmo",
    "_canDestroyFn",
    "_onDestroyedFn",
    "_effectiveChance"
];

(_destroyedClass isNotEqualTo "")
|| { !isNil "_onDestroyedFn" }
