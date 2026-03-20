#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns all configured destroyable-item info for a given item class.
 *
 * Arguments:
 * 0: Item classname <STRING>
 *
 * Return Value:
 * ARRAY [
 *   0: Destroyed item classname <STRING> (may be empty, meaning "remove only")
 *   1: Destroying sounds <ARRAY<STRING>>
 *   2: Destroying ammo classname <STRING>
 *   3: CanDestroy callback <CODE> (compiled, called before destruction)
 *   4: OnDestroyed callback <CODE> (compiled, called after destruction)
 *   5: Effective destroy chance (0–100) after settings/factor <NUMBER>
 * ]
 *
 * Example:
 * ["ACE_microDAGR"] call ace_items_fnc_getDestroyableItemInfo;
 * // e.g. ["ACE_microDAGR_Destroyed", ["ACE_electronicDeviceDestroyed"], "", "", "", 25]
 *
 * If no ACE_DestroyableItemInfo is found in the config inheritance chain, returns:
 *   ["", [], "", "", "", 0]
 *
 * Public: No
 */

params [["_className", "", [""]]];

if (_className isEqualTo "") exitWith { ["", [], "", "", "", 0] };

// Cache static config info (DestroyedItem, sounds, ammo, raw code, base chance) per class.
// Only settings and destroyChanceFactor should vary mid-mission.
private _base = GVAR(destroyableInfoCache) getOrDefaultCall [_className, {
    private _cfgItemLocal = _className call CBA_fnc_getItemConfig;
    if (isNull _cfgItemLocal) exitWith { [] };

    private _config = _cfgItemLocal;
    private _destroyedClass    = "";
    private _destroyingSounds  = [];
    private _destroyingAmmo    = "";
    private _canDestroyCode    = "";
    private _onDestroyedCode   = "";
    private _destroyChanceBase = 0;

    private _itemInfo = _config >> "ACE_DestroyableItemInfo";

    if (isClass _itemInfo) then {
        if (_destroyedClass isEqualTo "" && {isText (_itemInfo >> "DestroyedItem")}) then {
            _destroyedClass = getText (_itemInfo >> "DestroyedItem");
        };

        if (_destroyingSounds isEqualTo [] && {isArray (_itemInfo >> "DestroyingSounds")}) then {
            _destroyingSounds = getArray (_itemInfo >> "DestroyingSounds");
        };

        if (_destroyingAmmo isEqualTo "" && {isText (_itemInfo >> "DestroyingAmmo")}) then {
            _destroyingAmmo = getText (_itemInfo >> "DestroyingAmmo");
        };

        if (_canDestroyCode isEqualTo "" && {isText (_itemInfo >> "CanDestroy")}) then {
            _canDestroyCode = getText (_itemInfo >> "CanDestroy");
        };

        if (_onDestroyedCode isEqualTo "" && {isText (_itemInfo >> "OnDestroyed")}) then {
            _onDestroyedCode = getText (_itemInfo >> "OnDestroyed");
        };

        if (_destroyChanceBase <= 0 && {isNumber (_itemInfo >> "DestroyChance")}) then {
            _destroyChanceBase = getNumber (_itemInfo >> "DestroyChance");
        };
    };

    // Compile callbacks once here so callers receive ready-to-call CODE values.
    // If there is no code, return nil so callers can detect absence explicitly.
    private _canDestroyFn = if (_canDestroyCode isNotEqualTo "") then { compile _canDestroyCode } else { nil };
    private _onDestroyedFn = if (_onDestroyedCode isNotEqualTo "") then { compile _onDestroyedCode } else { nil };

    // Return base (config-derived) info; settings will be applied outside the cache.
    [_destroyedClass, _destroyingSounds, _destroyingAmmo, _canDestroyFn, _onDestroyedFn, _destroyChanceBase]
}, true];

// If config is missing or no info, return empty defaults.
if (_base isEqualTo []) exitWith { ["", [], "", "", "", 0] };

_base params ["_destroyedClass", "_destroyingSounds", "_destroyingAmmo", "_canDestroyFn", "_onDestroyedFn", "_destroyChanceBase"];

// Incorporate CBA setting (if present) and global destroyChanceFactor
private _settingPrefix = [_className] call FUNC(getItemSettingPrefix);
private _effectiveChance = _destroyChanceBase;

if (_settingPrefix isNotEqualTo "") then {
    _effectiveChance = missionNamespace getVariable [
        format ["%1_destroyChanceOnHit", _settingPrefix],
        _destroyChanceBase
    ];
};

_effectiveChance = (_effectiveChance * GVAR(destroyChanceFactor)) min 100;



[_destroyedClass, _destroyingSounds, _destroyingAmmo, _canDestroyFn, _onDestroyedFn, _effectiveChance]

