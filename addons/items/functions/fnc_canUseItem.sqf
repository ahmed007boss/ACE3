#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns whether an item operation is allowed for a unit in a given container.
 * Does not mean the unit has the item in the container; it means the operation is allowed there.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container <STRING> ("vest", "uniform", "backpack") or container object <OBJECT>
 * 2: Item classname <STRING>
 * 3: Operation mode name <STRING>
 * 4: Occurrence index (0-based) in container <NUMBER> (default: -1 = current implementation, no index)
 *
 * Return Value:
 * Can use item in container <BOOL>
 *
 * Example:
 * [ACE_player, "vest", "ACE_microDAGR", "Use"] call ace_items_fnc_canUseItem;
 * [ACE_player, "vest", "ACE_microDAGR", "Use", 1] call ace_items_fnc_canUseItem;
 *
 * Public: Yes
 */

params [
    ["_unit", objNull, [objNull]],
    ["_containerSlot", "", ["", objNull]],
    ["_itemClass", "", [""]],
    ["_operationMode", ENUM_STRING_OPERATIONMODES_USE, [""]],
    ["_index", -1, [0]]
];

BEGIN_COUNTER(canUseItem);

// Fast-path exits: no restriction data or feature disabled ⇒ always allow usage

if (!GVAR(enableUsableItemRestrictions)) exitWith { END_COUNTER(canUseItem); true };
if (GVAR(blockBackpackUsage) && {_containerSlot isEqualTo SLOT_BACKPACK_CONTAINER}) exitWith { END_COUNTER(canUseItem); false };

if !([_itemClass] call FUNC(hasUsageRestriction)) exitWith { END_COUNTER(canUseItem); true };

// Base restriction info from helper (config + CBA overrides, lists, compiled condition)
private _rawInfo = [_itemClass, _operationMode] call FUNC(getUsableItemRestrictionsInfo);
if (_rawInfo isEqualTo []) exitWith { END_COUNTER(canUseItem); false };

_rawInfo params [
    "_disallowedWhenAssigned",
    "_disallowedWhenEquipped",
    "_disallowedInVest",
    "_disallowedInUniform",
    "_disallowedInBackpack",
    "_disallowedUnderwater",
    "_disallowedInAir",
    "_disallowedInVehicles",
    "_useConditionFn",
    "_whitelist",
    "_blacklist"
];

// Optional whitelist/blacklist on container classes for this operation mode (from helper)
private _listPass = true;
private _containerSlotClass = "";

if (_whitelist isNotEqualTo [] || {_blacklist isNotEqualTo []}) then {
    if (_containerSlot isEqualType objNull) then {
        _containerSlotClass = typeOf _containerSlot;
    } else {
        switch (_containerSlot) do {
            case SLOT_VEST_CONTAINER: { _containerSlotClass = vest _unit };
            case SLOT_UNIFORM_CONTAINER: { _containerSlotClass = uniform _unit };
            case SLOT_BACKPACK_CONTAINER: { _containerSlotClass = backpack _unit };
            default { _containerSlotClass = "" };
        };
    };
    _listPass = _containerSlotClass isNotEqualTo "" && {
        (_blacklist isEqualTo [] || { !(_containerSlotClass in _blacklist) }) &&
        { (_whitelist isEqualTo [] || { _containerSlotClass in _whitelist }) }
    };
};

// Environment-based restrictions (underwater, in air, in vehicles)
// Underwater: use common helper to detect swimming/diving
if (_disallowedUnderwater && {[_unit] call EFUNC(common,isSwimming)}) exitWith { END_COUNTER(canUseItem); false };

// In vehicle: disallow when inside any vehicle
if (_disallowedInVehicles && {!isNull objectParent _unit}) exitWith { END_COUNTER(canUseItem); false };

// In air: rough check for being in the air on foot (not touching ground and not in vehicle)
if (_disallowedInAir) then {
    private _vehicle = objectParent _unit;
    private _onFoot = isNull _vehicle;
    // In air if on foot and not touching ground, or riding in a parachute
    private _inAir = (_onFoot && {!isTouchingGround _unit}) || {!_onFoot && {_vehicle isKindOf "ParachuteBase"}};
    if (_inAir) exitWith { END_COUNTER(canUseItem); false };
};

// Optional per-operation extra condition from config (no CBA setting).
// If defined (non-empty), it is compiled and executed with: [unit, container, itemClass, operationMode, index].
if (!isNil "_useConditionFn") then {
    if !([_unit, _containerSlot, _itemClass, _operationMode, _index] call _useConditionFn) exitWith { END_COUNTER(canUseItem); false };
};

// Final decision: container slot must be allowed for this mode and pass whitelist/blacklist checks
private _disallowedHere = false;
switch (_containerSlot) do {
    case SLOT_ASSIGNED: { _disallowedHere = _disallowedWhenAssigned };
    case SLOT_EQUIPPED: { _disallowedHere = _disallowedWhenEquipped };
    case SLOT_WEAPONS: { _disallowedHere = _disallowedWhenEquipped };
    case SLOT_VEST_CONTAINER: { _disallowedHere = _disallowedInVest };
    case SLOT_UNIFORM_CONTAINER: { _disallowedHere = _disallowedInUniform };
    case SLOT_BACKPACK_CONTAINER: { _disallowedHere = _disallowedInBackpack };
    default { _disallowedHere = false };
};

private _result = (!_disallowedHere) && _listPass;
END_COUNTER(canUseItem);
_result

