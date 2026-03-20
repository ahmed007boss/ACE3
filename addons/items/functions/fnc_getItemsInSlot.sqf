#include "..\script_component.hpp"
/*
 * Author: ACETeam
 * Returns all item classnames in a given slot for a unit or container object.
 * For units: "assigned" (linked items + headgear + goggles), "equipped" (vest/uniform/backpack),
 * "vest", "uniform", "backpack", "primaryWeaponItems", "secondaryWeaponItems", "handgunItems".
 * For container objects: use slot "object" for full cargo list.
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Slot <STRING> ("assigned", "equipped", "vest", "uniform", "backpack", "primaryWeaponItems", "secondaryWeaponItems", "handgunItems", "object")
 *
 * Return Value:
 * Item classnames <ARRAY> (order matches engine; duplicates for multiple of same item)
 *
 * Example:
 * [player, "vest"] call ace_items_fnc_getItemsInSlot;
 * [player, "assigned"] call ace_items_fnc_getItemsInSlot;
 * [myBox, "object"] call ace_items_fnc_getItemsInSlot;
 *
 * Public: Yes
 */

params [
    ["_object", objNull, [objNull]],
    ["_slot", "", [""]]
];

if (isNull _object || {_slot isEqualTo ""}) exitWith { [] };

private _itemsRes = if (_object call CBA_fnc_isPerson) then {
    switch (_slot) do {
        case SLOT_ASSIGNED: {
            (assignedItems [_object,true, false]) // this "true,false]" to include headgear and goggles but not binocular as its considered weapon  , which are technically "assigned" but not returned by assignedItems without these params 
        };
        case SLOT_EQUIPPED: {
            [vest _object, uniform _object, backpack _object]
        };
        case SLOT_VEST_CONTAINER:     { vestItems _object };
        case SLOT_UNIFORM_CONTAINER:  { uniformItems _object };
        case SLOT_BACKPACK_CONTAINER: { backpackItems _object };
        case SLOT_WEAPONS: {
            private _weapons = [] ;
            _weapons pushBack primaryWeapon _object;                                     
            _weapons pushBack secondaryWeapon _object;
            _weapons pushBack handgunWeapon _object;
            _weapons pushBack binocular _object;
            _weapons
        };
        case SLOT_PRIMARY_WEAPON_ITEMS: {
            ((primaryWeaponMagazine _object) + (primaryWeaponItems _object)) 
        };
        case SLOT_SECONDARY_WEAPON_ITEMS: {
            ((secondaryWeaponMagazine _object) + (secondaryWeaponItems _object)) 
        };
        case SLOT_HANDGUN_WEAPON_ITEMS: {
            ((handgunMagazine _object) + (handgunItems _object)) 
        };
         case SLOT_BINOCULAR_ITEMS: {
            ((binocularMagazine _object) + (binocularItems _object)) 
        }; 
        default { [] };
    };
} else {
    if (_slot isEqualTo SLOT_OBJECT) exitWith { [_object, false] call FUNC(getContainerItemClasses) };
    []
};
_itemsRes select {_x isNotEqualTo ""}
