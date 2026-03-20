#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Resolves the correct object to store item state on.
 * For assigned items (headgear, goggles, HMD) state is stored on the unit.
 * For items inside vest/uniform/backpack, state is stored on the container object.
 * For items inside any other container (box, vehicle, nested), state is stored on that container object.
 * Always returns the most up-to-date container reference by re-querying vestContainer etc.
 *
 * Arguments:
 * 0: Unit or parent container object <OBJECT>
 * 1: Container slot <STRING> ("assigned", "equipped", "vest", "uniform", "backpack", "primaryWeaponItems", "secondaryWeaponItems", "handgunItems") or "object" for non-unit containers
 *
 * Return Value:
 * Object to call setVariable/getVariable on <OBJECT>
 *
 * Example:
 * [player, "vest"] call ace_items_fnc_getStateObject;
 *
 * Public: No
 */

params [
    ["_object", objNull, [objNull]],
    ["_slot", "", [""]]
];

if (isNull _object) exitWith { objNull };

// Always re-query container reference to get current locality-correct object
// Never cache these — vest/uniform/backpack locality changes when items are transferred between players
private _result = switch (_slot) do {
    case SLOT_ASSIGNED: { _object };
    case SLOT_EQUIPPED: { _object };
    case SLOT_VEST_CONTAINER:     { vestContainer _object };
    case SLOT_UNIFORM_CONTAINER:  { uniformContainer _object };
    case SLOT_BACKPACK_CONTAINER: { backpackContainer _object };
    case SLOT_WEAPONS:                { _object };
    case SLOT_PRIMARY_WEAPON_ITEMS:   { _object };
    case SLOT_SECONDARY_WEAPON_ITEMS: { _object };
    case SLOT_HANDGUN_WEAPON_ITEMS:   { _object };
    case SLOT_BINOCULAR_ITEMS:   { _object };
    case SLOT_OBJECT:                 { _object };
    default          { _object };
};

// If result is null or same as unit for a container slot, return unit as fallback
if (isNull _result) exitWith { objNull };

_result
