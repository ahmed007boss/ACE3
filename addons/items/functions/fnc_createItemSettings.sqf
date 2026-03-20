#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Creates CBA settings for a usable and/or destroyable item.
 * Registers the item classname to setting prefix mapping for runtime lookup.
 *
 * Arguments:
 * 0: Setting prefix <STRING>
 * 1: Setting category <ARRAY>
 * 2: Item classname <STRING>
 * 3: Item display name <STRING>
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * ["ACE_microdagr", ["ACE Electronics", "MicroDAGR"], "ACE_microDAGR", "MicroDAGR"] call ace_items_fnc_createItemSettings;
 *
 * Public: Yes
 */

params ["_settingPrefix", "_category", "_itemClass", "_itemName"];

private _hasUsageRestriction = [_itemClass] call FUNC(hasUsageRestriction);
private _isDestroyableItem = [_itemClass] call FUNC(isDestroyableItem);

if (!_hasUsageRestriction && !_isDestroyableItem) exitWith {};

private _cfgItem = _itemClass call CBA_fnc_getItemConfig;
if (isNull _cfgItem) exitWith {};

// Decide if it makes sense to expose "assigned" / "equipped" restrictions for this item.
// Use simple ItemInfo type checks like in ace_common_fnc_getItemType.
//  - "Assigned" = things that live in assigned slots (HMD/NVG, radios, binocular-like devices, UAV terminals, etc.)
//  - "Equipped" = wearable containers and weapons (uniform, vest, backpack, primary/secondary/handgun)
private _supportsAssignedSettings = false;
private _supportsEquippedSettings = false;

if (isNumber (_cfgItem >> "ItemInfo" >> "type")) then {
    private _itemInfoType = getNumber (_cfgItem >> "ItemInfo" >> "type");

    if (_itemInfoType in [
        TYPE_HMD,
        TYPE_GOGGLE,
        TYPE_HEADGEAR,
        TYPE_RADIO,
        TYPE_BINOCULAR,
        TYPE_UAV_TERMINAL
    ]) then {
        _supportsAssignedSettings = true;
    };

    if (_itemInfoType in [
        TYPE_VEST,
        TYPE_UNIFORM,
        TYPE_BACKPACK,
        TYPE_WEAPON_PRIMARY,
        TYPE_WEAPON_HANDGUN,
        TYPE_WEAPON_SECONDARY
    ]) then {
        _supportsEquippedSettings = true;
    };
};

private _config = _cfgItem;
private _operationModeDefs = [];

// Walk inheritance chain until we find ACE_UsableItemRestrictionsInfo with operation definitions
while { (_operationModeDefs isEqualTo []) && { !isNull _config } } do {
    private _usableCfgItem = _config >> "ACE_UsableItemRestrictionsInfo";

    if (isClass _usableCfgItem) then {
        // Root-level: primary operation (default key = ENUM_STRING_OPERATIONMODES_USE)
        private _rootDisplay = getText (_usableCfgItem >> "displayName");
        if (_rootDisplay isNotEqualTo "") then {
            private _rootDisallowedWhenAssigned = (getNumber (_usableCfgItem >> "disallowedWhenAssigned")) == 1;
            private _rootDisallowedWhenEquipped = (getNumber (_usableCfgItem >> "disallowedWhenEquipped")) == 1;
            private _rootDisallowedInVest = (getNumber (_usableCfgItem >> "disallowedInVest")) == 1;
            private _rootDisallowedInUniform = (getNumber (_usableCfgItem >> "disallowedInUniform")) == 1;
            private _rootDisallowedInBackpack = (getNumber (_usableCfgItem >> "disallowedInBackpack")) == 1;
            private _rootDisallowedUnderwater = (getNumber (_usableCfgItem >> "disallowedUnderwater")) == 1;
            private _rootDisallowedInAir = (getNumber (_usableCfgItem >> "disallowedInAir")) == 1;
            private _rootDisallowedInVehicles = (getNumber (_usableCfgItem >> "disallowedInVehicles")) == 1;
            _operationModeDefs pushBack [
                ENUM_STRING_OPERATIONMODES_USE,
                _rootDisplay,
                _rootDisallowedWhenAssigned,
                _rootDisallowedWhenEquipped,
                _rootDisallowedInVest,
                _rootDisallowedInUniform,
                _rootDisallowedInBackpack,
                _rootDisallowedUnderwater,
                _rootDisallowedInAir,
                _rootDisallowedInVehicles
            ];
        };

        // Child classes: additional operations
        {
            private _opKey = configName _x;
            private _opDisplay = getText (_x >> "displayName");
            if (_opDisplay isEqualTo "") then {
                _opDisplay = getText (_x >> "operationName"); // legacy support
            };
            if (_opDisplay isNotEqualTo "" || {_opKey isNotEqualTo ""}) then {
                private _defDisallowedWhenAssigned = (getNumber (_x >> "disallowedWhenAssigned")) == 1;
                private _defDisallowedWhenEquipped = (getNumber (_x >> "disallowedWhenEquipped")) == 1;
                private _defDisallowedInVest = (getNumber (_x >> "disallowedInVest")) == 1;
                private _defDisallowedInUniform = (getNumber (_x >> "disallowedInUniform")) == 1;
                private _defDisallowedInBackpack = (getNumber (_x >> "disallowedInBackpack")) == 1;
                private _defDisallowedUnderwater = (getNumber (_x >> "disallowedUnderwater")) == 1;
                private _defDisallowedInAir = (getNumber (_x >> "disallowedInAir")) == 1;
                private _defDisallowedInVehicles = (getNumber (_x >> "disallowedInVehicles")) == 1;
                _operationModeDefs pushBack [
                    _opKey,
                    _opDisplay,
                    _defDisallowedWhenAssigned,
                    _defDisallowedWhenEquipped,
                    _defDisallowedInVest,
                    _defDisallowedInUniform,
                    _defDisallowedInBackpack,
                    _defDisallowedUnderwater,
                    _defDisallowedInAir,
                    _defDisallowedInVehicles
                ];
            };
        } forEach ("true" configClasses _usableCfgItem);
    };

    _config = inheritsFrom _config;
};
[_itemClass, _settingPrefix] call FUNC(setItemSettingPrefix);

if (_hasUsageRestriction) then {
    {
        _x params [
            "_operationModeKey",
            "_operationModeDisplay",
            ["_defDisallowedWhenAssigned", false],
            ["_defDisallowedWhenEquipped", false],
            ["_defDisallowedInVest", false],
            ["_defDisallowedInUniform", false],
            ["_defDisallowedInBackpack", false],
            ["_defDisallowedUnderwater", false],
            ["_defDisallowedInAir", false],
            ["_defDisallowedInVehicles", false]
        ];
        
        private _operationCategory = [
            _category select 0,
            format [
                "%1 - %2 %3",
                _category select 1,
                _operationModeDisplay,
                localize LSTRING(ItemOperationModeRestrictions_Label)
            ]
        ];
        // Per-slot container restriction settings (checkbox for each personal slot / state)
        if (_supportsAssignedSettings) then {
            [
                format ["%1_operationModeDisallowedWhenAssigned_%2", _settingPrefix, _operationModeKey], "CHECKBOX",
                [format [localize LSTRING(ItemOperationModeDisallowedWhenAssigned_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeDisallowedWhenAssigned_Description), _itemName, _operationModeDisplay]],
                _operationCategory,
                _defDisallowedWhenAssigned,
                true
            ] call CBA_fnc_addSetting;
        };

        if (_supportsEquippedSettings) then {
            [
                format ["%1_operationModeDisallowedWhenEquipped_%2", _settingPrefix, _operationModeKey], "CHECKBOX",
                [format [localize LSTRING(ItemOperationModeDisallowedWhenEquipped_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeDisallowedWhenEquipped_Description), _itemName, _operationModeDisplay]],
                _operationCategory,
                _defDisallowedWhenEquipped,
                true
            ] call CBA_fnc_addSetting;
        };

        [
            format ["%1_operationModeDisallowedInVest_%2", _settingPrefix, _operationModeKey], "CHECKBOX",
            [format [localize LSTRING(ItemOperationModeDisallowedInVest_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeDisallowedInVest_Description), _itemName, _operationModeDisplay]],
            _operationCategory,
            _defDisallowedInVest,
            true
        ] call CBA_fnc_addSetting;

        [
            format ["%1_operationModeDisallowedInUniform_%2", _settingPrefix, _operationModeKey], "CHECKBOX",
            [format [localize LSTRING(ItemOperationModeDisallowedInUniform_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeDisallowedInUniform_Description), _itemName, _operationModeDisplay]],
            _operationCategory,
            _defDisallowedInUniform,
            true
        ] call CBA_fnc_addSetting;

        [
            format ["%1_operationModeDisallowedInBackpack_%2", _settingPrefix, _operationModeKey], "CHECKBOX",
            [format [localize LSTRING(ItemOperationModeDisallowedInBackpack_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeDisallowedInBackpack_Description), _itemName, _operationModeDisplay]],
            _operationCategory,
            _defDisallowedInBackpack,
            true
        ] call CBA_fnc_addSetting;

        // Optional whitelist/blacklist on container classes for this operation mode (unchanged)
        [
            format ["%1_operationModeContainerWhitelist_%2", _settingPrefix, _operationModeKey], "EDITBOX",
            [format [localize LSTRING(ItemOperationModeContainerWhitelist_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeContainerWhitelist_Description), _operationModeDisplay]],
            _operationCategory,
            "[]",
            true
        ] call CBA_fnc_addSetting;

        [
            format ["%1_operationModeContainerBlacklist_%2", _settingPrefix, _operationModeKey], "EDITBOX",
            [format [localize LSTRING(ItemOperationModeContainerBlacklist_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeContainerBlacklist_Description), _operationModeDisplay]],
            _operationCategory,
            "[]",
            true
        ] call CBA_fnc_addSetting;

        // Environment restriction settings
        [
            format ["%1_operationModeDisallowedUnderwater_%2", _settingPrefix, _operationModeKey], "CHECKBOX",
            [format [localize LSTRING(ItemOperationModeDisallowedUnderwater_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeDisallowedUnderwater_Description), _itemName, _operationModeDisplay]],
            _operationCategory,
            _defDisallowedUnderwater,
            true
        ] call CBA_fnc_addSetting;

        [
            format ["%1_operationModeDisallowedInAir_%2", _settingPrefix, _operationModeKey], "CHECKBOX",
            [format [localize LSTRING(ItemOperationModeDisallowedInAir_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeDisallowedInAir_Description), _itemName, _operationModeDisplay]],
            _operationCategory,
            _defDisallowedInAir,
            true
        ] call CBA_fnc_addSetting;

        [
            format ["%1_operationModeDisallowedInVehicles_%2", _settingPrefix, _operationModeKey], "CHECKBOX",
            [format [localize LSTRING(ItemOperationModeDisallowedInVehicles_DisplayName), _operationModeDisplay], format [localize LSTRING(ItemOperationModeDisallowedInVehicles_Description), _itemName, _operationModeDisplay]],
            _operationCategory,
            _defDisallowedInVehicles,
            true
        ] call CBA_fnc_addSetting;
    } forEach _operationModeDefs;
};

if (_isDestroyableItem) then {
    [
        format ["%1_destroyChanceOnHit", _settingPrefix], "SLIDER",
        [format [localize LSTRING(ItemDestroyChanceOnHit_DisplayName), _itemName], format [localize LSTRING(ItemDestroyChanceOnHit_Description), _itemName]],
        _category,
        [0, 100, 0, 0],
        true
    ] call CBA_fnc_addSetting;
};
