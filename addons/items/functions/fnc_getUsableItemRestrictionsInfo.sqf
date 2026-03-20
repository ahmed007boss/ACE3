#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns ACE_UsableItemRestrictionsInfo for a given item class and operation mode.
 * Static config is cached, but CBA overrides and per-operation callbacks are applied
 * on each call (settings are not cached).
 *
 * Arguments:
 * 0: Item classname <STRING>
 * 1: Operation mode key or display name <STRING>
 *
 * Return Value:
 * ARRAY [
 *   0: disallowedWhenAssigned <BOOL>
 *   1: disallowedWhenEquipped <BOOL>
 *   2: disallowedInVest <BOOL>
 *   3: disallowedInUniform <BOOL>
 *   4: disallowedInBackpack <BOOL>
 *   5: disallowedUnderwater <BOOL>
 *   6: disallowedInAir <BOOL>
 *   7: disallowedInVehicles <BOOL>
 *   8: useCondition callback <CODE> (compiled) or nil if none
 *   9: whitelist <ARRAY<STRING>> (parsed from CBA setting)
 *  10: blacklist <ARRAY<STRING>> (parsed from CBA setting)
 * ]
 *
 * Example:
 * ["ACE_microDAGR"] call ace_items_fnc_getUsableItemRestrictionsInfo;
 * ["ACE_microDAGR", ENUM_STRING_OPERATIONMODES_USE] call ace_items_fnc_getUsableItemRestrictionsInfo;
 *
 * Public: No
 */

params [
    ["_itemClass", "", [""]],
    ["_operationMode", ENUM_STRING_OPERATIONMODES_USE, [""]]
];

if (_itemClass isEqualTo "" || {_operationMode isEqualTo ""}) exitWith { [] };

private _cfgItem = _itemClass call CBA_fnc_getItemConfig;
if (isNull _cfgItem) exitWith { [] };

// Cache static restriction info per (class, operation) pair (config only).
// CBA overrides and whitelist/blacklist are applied below, outside the cache.
private _base = GVAR(usableRestrictionsCache) getOrDefaultCall [[_itemClass, _operationMode], {
    private _config = _cfgItem;
    private _foundOperation = false;
    private _disallowedWhenAssigned = false;
    private _disallowedWhenEquipped = false;
    private _disallowedInVest = false;
    private _disallowedInUniform = false;
    private _disallowedInBackpack = false;
    private _disallowedUnderwater = false;
    private _disallowedInAir = false;
    private _disallowedInVehicles = false;
    private _useConditionCode = "";

    while { !_foundOperation && { !isNull _config } } do {
        private _usableInfo = _config >> "ACE_UsableItemRestrictionsInfo";

        if (isClass _usableInfo) then {
            // Root-level definition: primary operation (default key = ENUM_STRING_OPERATIONMODES_USE)
            private _rootDisplay = getText (_usableInfo >> "displayName");
            private _rootDisallowedWhenAssigned = (getNumber (_usableInfo >> "disallowedWhenAssigned")) == 1;
            private _rootDisallowedWhenEquipped = (getNumber (_usableInfo >> "disallowedWhenEquipped")) == 1;
            private _rootDisallowedInVest = (getNumber (_usableInfo >> "disallowedInVest")) == 1;
            private _rootDisallowedInUniform = (getNumber (_usableInfo >> "disallowedInUniform")) == 1;
            private _rootDisallowedInBackpack = (getNumber (_usableInfo >> "disallowedInBackpack")) == 1;
            private _rootUseCondition = getText (_usableInfo >> "useCondition");
            private _rootDisallowedUnderwater = (getNumber (_usableInfo >> "disallowedUnderwater")) == 1;
            private _rootDisallowedInAir = (getNumber (_usableInfo >> "disallowedInAir")) == 1;
            private _rootDisallowedInVehicles = (getNumber (_usableInfo >> "disallowedInVehicles")) == 1;

            // Match by operation key (class name) or display name
            if (!_foundOperation && { _operationMode isEqualTo ENUM_STRING_OPERATIONMODES_USE || { _rootDisplay isEqualTo _operationMode } }) then {
                _disallowedWhenAssigned = _rootDisallowedWhenAssigned;
                _disallowedWhenEquipped = _rootDisallowedWhenEquipped;
                _disallowedInVest = _rootDisallowedInVest;
                _disallowedInUniform = _rootDisallowedInUniform;
                _disallowedInBackpack = _rootDisallowedInBackpack;
                _disallowedUnderwater = _rootDisallowedUnderwater;
                _disallowedInAir = _rootDisallowedInAir;
                _disallowedInVehicles = _rootDisallowedInVehicles;
                _useConditionCode = _rootUseCondition;
                _foundOperation = true;
            };

            // Child classes: additional operations; class name is the operation key, displayName is label
            if (!_foundOperation) then {
                {
                    private _opClassName = configName _x;
                    private _opDisplayName = getText (_x >> "displayName");
                    if (_opDisplayName isEqualTo "") then {
                        _opDisplayName = getText (_x >> "operationName"); // legacy support
                    };

                    if (_opClassName isEqualTo _operationMode || {_opDisplayName isEqualTo _operationMode}) exitWith {
                        _disallowedWhenAssigned = (getNumber (_x >> "disallowedWhenAssigned")) == 1;
                        _disallowedWhenEquipped = (getNumber (_x >> "disallowedWhenEquipped")) == 1;
                        _disallowedInVest = (getNumber (_x >> "disallowedInVest")) == 1;
                        _disallowedInUniform = (getNumber (_x >> "disallowedInUniform")) == 1;
                        _disallowedInBackpack = (getNumber (_x >> "disallowedInBackpack")) == 1;
                        _disallowedUnderwater = (getNumber (_x >> "disallowedUnderwater")) == 1;
                        _disallowedInAir = (getNumber (_x >> "disallowedInAir")) == 1;
                        _disallowedInVehicles = (getNumber (_x >> "disallowedInVehicles")) == 1;
                        _useConditionCode = getText (_x >> "useCondition");
                        _foundOperation = true;
                    };
                } forEach ("true" configClasses _usableInfo);
            };
        };

        _config = inheritsFrom _config;
    };

    if (!_foundOperation) exitWith { [] };

    [
        _disallowedWhenAssigned,
        _disallowedWhenEquipped,
        _disallowedInVest,
        _disallowedInUniform,
        _disallowedInBackpack,
        _disallowedUnderwater,
        _disallowedInAir,
        _disallowedInVehicles,
        _useConditionCode
    ]
}, true];

_base params [
    "_disallowedWhenAssigned",
    "_disallowedWhenEquipped",
    "_disallowedInVest",
    "_disallowedInUniform",
    "_disallowedInBackpack",
    "_disallowedUnderwater",
    "_disallowedInAir",
    "_disallowedInVehicles",
    "_useConditionCode"
];

// No matching operation: no restriction info.
if (_base isEqualTo []) exitWith { [] };

// Apply CBA overrides per call (settings can change mid-mission)
private _settingPrefix = [_itemClass] call FUNC(getItemSettingPrefix);

if (_settingPrefix isNotEqualTo "") then {
    _disallowedWhenAssigned = missionNamespace getVariable [
        format ["%1_operationModeDisallowedWhenAssigned_%2", _settingPrefix, _operationMode],
        _disallowedWhenAssigned
    ];
    _disallowedWhenEquipped = missionNamespace getVariable [
        format ["%1_operationModeDisallowedWhenEquipped_%2", _settingPrefix, _operationMode],
        _disallowedWhenEquipped
    ];
    _disallowedInVest = missionNamespace getVariable [
        format ["%1_operationModeDisallowedInVest_%2", _settingPrefix, _operationMode],
        _disallowedInVest
    ];
    _disallowedInUniform = missionNamespace getVariable [
        format ["%1_operationModeDisallowedInUniform_%2", _settingPrefix, _operationMode],
        _disallowedInUniform
    ];
    _disallowedInBackpack = missionNamespace getVariable [
        format ["%1_operationModeDisallowedInBackpack_%2", _settingPrefix, _operationMode],
        _disallowedInBackpack
    ];
    _disallowedUnderwater = missionNamespace getVariable [
        format ["%1_operationModeDisallowedUnderwater_%2", _settingPrefix, _operationMode],
        _disallowedUnderwater
    ];
    _disallowedInAir = missionNamespace getVariable [
        format ["%1_operationModeDisallowedInAir_%2", _settingPrefix, _operationMode],
        _disallowedInAir
    ];
    _disallowedInVehicles = missionNamespace getVariable [
        format ["%1_operationModeDisallowedInVehicles_%2", _settingPrefix, _operationMode],
        _disallowedInVehicles
    ];
};

// Parse whitelist/blacklist strings from settings (per call) so caller can do container checks.
private _whitelist = [];
private _blacklist = [];

if (_settingPrefix isNotEqualTo "") then {
    private _whitelistStr = missionNamespace getVariable [
        format ["%1_operationModeContainerWhitelist_%2", _settingPrefix, _operationMode],
        "[]"
    ];
    private _blacklistStr = missionNamespace getVariable [
        format ["%1_operationModeContainerBlacklist_%2", _settingPrefix, _operationMode],
        "[]"
    ];
    _whitelist = [_whitelistStr] call FUNC(parseContainerListSetting);
    _blacklist = [_blacklistStr] call FUNC(parseContainerListSetting);
};

// Compile useCondition once per call (cheap) so caller gets CODE; nil = no extra condition.
private _useConditionFn = if (_useConditionCode isNotEqualTo "") then { compile _useConditionCode } else { nil };

[
    _disallowedWhenAssigned,
    _disallowedWhenEquipped,
    _disallowedInVest,
    _disallowedInUniform,
    _disallowedInBackpack,
    _disallowedUnderwater,
    _disallowedInAir,
    _disallowedInVehicles,
    _useConditionFn,
    _whitelist,
    _blacklist
]
