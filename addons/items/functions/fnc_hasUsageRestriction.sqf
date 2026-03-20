#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Checks if a given item classname has usage restrictions (ACE_UsableItemRestrictionsInfo).
 *
 * Arguments:
 * 0: Item classname <STRING>
 *
 * Return Value:
 * Has usage restriction <BOOL>
 *
 * Example:
 * ["ACE_microDAGR"] call ace_items_fnc_hasUsageRestriction;
 *
 * Public: false
 */

params [["_className", "", [""]]];

if (_className isEqualTo "") exitWith { false };

private _cfgItem = _className call CBA_fnc_getItemConfig;
if (isNull _cfgItem) exitWith { false };

private _config = _cfgItem;
private _result = false;

while { !_result && { !isNull _config } } do {
    if (isClass (_config >> "ACE_UsableItemRestrictionsInfo")) then {
        _result = true;
    };
    _config = inheritsFrom _config;
};

_result
