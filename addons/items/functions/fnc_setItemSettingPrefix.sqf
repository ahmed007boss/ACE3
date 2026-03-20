#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Registers an item class to a CBA setting prefix (used for container/destroy/battery settings lookup).
 *
 * Arguments:
 * 0: Item classname <STRING>
 * 1: Setting prefix <STRING>
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * ["ACE_NVG_Gen1_NoBattery", "ACE_nightvision"] call ace_items_fnc_setItemSettingPrefix;
 *
 * Public: Yes
 */

params [["_itemClass", "", [""]], ["_settingPrefix", "", [""]]];

if (_itemClass isEqualTo "" || {_settingPrefix isEqualTo ""}) exitWith {};

private _itemSettingPrefixes = missionNamespace getVariable QGVAR(itemSettingPrefixes);
if (isNil "_itemSettingPrefixes") then {
    _itemSettingPrefixes = createHashMap;
    missionNamespace setVariable [QGVAR(itemSettingPrefixes), _itemSettingPrefixes];
};
_itemSettingPrefixes set [_itemClass, _settingPrefix];
