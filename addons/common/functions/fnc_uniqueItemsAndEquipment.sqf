#include "..\script_component.hpp"
/*
 * Author: ACETeam
 * Returns list of unique items in the target's inventory, including assigned items and
 * the uniform, vest, and backpack themselves (for units). Like uniqueItems but also
 * includes equipment that uniqueItems omits (assigned items and container classnames).
 *
 * Arguments:
 * 0: Target <OBJECT>
 * 1: Include magazines <NUMBER> (default: 0)
 *    0: No
 *    1: Yes
 *    2: Only magazines
 *
 * Return Value:
 * Items <ARRAY>
 *
 * Example:
 * [player, 0] call ace_common_fnc_uniqueItemsAndEquipment
 *
 * Public: No
 */

params ["_target", ["_includeMagazines", 0]];

private _allItems = [_target, _includeMagazines] call FUNC(uniqueItems);

if (_target isKindOf "CAManBase") then {
    _allItems = _allItems + (assignedItems [_target, true, true]);
    if ((uniform _target) isNotEqualTo "") then { _allItems pushBack (uniform _target); };
    if ((vest _target) isNotEqualTo "") then { _allItems pushBack (vest _target); };
    if ((backpack _target) isNotEqualTo "") then { _allItems pushBack (backpack _target); };
    // Weapon attachments (flashlights, lasers, optics, etc.) may be battery-powered devices
    _allItems = _allItems + (primaryWeaponItems _target) + (handgunItems _target) + (secondaryWeaponItems _target);
    _allItems = _allItems arrayIntersect _allItems;
};

_allItems
