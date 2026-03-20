#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns item classnames in a container object: its direct cargo (items, magazines, weapons)
 * plus the classname of every nested container (e.g. backpacks inside a box).
 *
 * Arguments:
 * 0: Container object <OBJECT> (box, vehicle, etc.)
 * 1: Return unique only <BOOL> (default: true) - if false, returns raw list (may contain duplicates)
 *
 * Return Value:
 * Item/container classnames <ARRAY>
 *
 * Example:
 * [myBox] call ace_items_fnc_getContainerItemClasses;
 * [myBox, false] call ace_items_fnc_getContainerItemClasses;
 *
 * Public: No
 */

params [
    ["_object", objNull, [objNull]],
    ["_unique", true, [true]]
];

if (isNull _object) exitWith { [] };

private _itemClasses = (itemCargo _object) + (magazineCargo _object) + (weaponCargo _object) + (everyContainer _object apply { _x select 0 });

if (_unique) then {
    _itemClasses arrayIntersect _itemClasses
} else {
    _itemClasses
}
