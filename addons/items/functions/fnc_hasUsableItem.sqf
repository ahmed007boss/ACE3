#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns whether a given item is present in allowed containers and usable for a given operation mode.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Item classname to search for (and read restrictions from) <STRING>
 * 2: Operation mode name <STRING> (default: ENUM_STRING_OPERATIONMODES_USE)
 * 3: Optional container slot <STRING> ("vest", "uniform", "backpack"). Empty = check all.
 *
 * Return Value:
 * Item present in at least one allowed container for this operation <BOOL>
 *
 * Example:
 * [ACE_player, "ACE_microDAGR"] call ace_items_fnc_hasUsableItem;
 * [ACE_player, "ACE_microDAGR", ENUM_STRING_OPERATIONMODES_USE, "vest"] call ace_items_fnc_hasUsableItem;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_itemClass", "", [""]],
    ["_operationMode", ENUM_STRING_OPERATIONMODES_USE, [""]],
    ["_slot", "", [""]]
];

if (isNull _unit) exitWith { false };
if (_itemClass isEqualTo "" || {_operationMode isEqualTo ""}) exitWith { false };

private _fnc_checkContainer = {
    params ["_unit", "_itemClass", "_operationMode", "_slot"];

    private _items = [_unit, _slot] call FUNC(getItemsInSlot);
    if !(_itemClass in _items) exitWith { false };

    // Item present in this container and operation allowed there
    [_unit, _slot, _itemClass, _operationMode] call FUNC(canUseItem)
};

// If a specific container is provided, only check that one
if (_slot isNotEqualTo "") exitWith {
    [_unit, _itemClass, _operationMode, _slot] call _fnc_checkContainer
};

// Otherwise, check all relevant personal slots:
// - assigned (e.g. NVGs/headgear with operations)
// - equipped wearable containers (vest/uniform/backpack), honoring blockBackpackUsage

[_unit, _itemClass, _operationMode, SLOT_VEST_CONTAINER] call _fnc_checkContainer ||
{[_unit, _itemClass, _operationMode, SLOT_UNIFORM_CONTAINER] call _fnc_checkContainer} ||
{!GVAR(blockBackpackUsage) && {[_unit, _itemClass, _operationMode, SLOT_BACKPACK_CONTAINER] call _fnc_checkContainer}} ||
{([_unit, _itemClass, _operationMode, SLOT_ASSIGNED] call _fnc_checkContainer)} ||
{([_unit, _itemClass, _operationMode, SLOT_EQUIPPED] call _fnc_checkContainer)}
