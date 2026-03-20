#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns the CBA setting prefix registered for an item class (used for container/destroy/battery settings).
 *
 * Arguments:
 * 0: Item classname <STRING>
 *
 * Return Value:
 * Setting prefix <STRING> (e.g. "ACE_nightvision") or "" if not registered
 *
 * Example:
 * ["ACE_NVG_Gen1"] call ace_items_fnc_getItemSettingPrefix;
 *
 * Public: Yes
 */

params [["_itemClass", "", [""]]];

if (_itemClass isEqualTo "") exitWith { "" };

private _itemSettingPrefixes = missionNamespace getVariable [QGVAR(itemSettingPrefixes), createHashMap];
_itemSettingPrefixes getOrDefault [_itemClass, ""]
