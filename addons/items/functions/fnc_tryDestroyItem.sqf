#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Attempts to replace a hit item with its damaged variant.
 *
 * Arguments:
 * 0: Unit carrying the item <OBJECT>
 * 1: Item classname <STRING>
 * 2: Item location <STRING>
 * 3: Optional state index associated with the item <NUMBER>
 * 4: Optional damage info <ARRAY> ([_shooter, _bodyPart, _ammoType, _isBackShot])
 *
 * Return Value:
 * Item was destroyed and replaced successfully <BOOL>
 *
 * Example:
 * [ACE_player, "ACE_microDAGR", "vest", 0] call ace_items_fnc_tryDestroyItem;
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_className", "", [""]],
    ["_slot", "", [""]],
    ["_itemIndex", -1, [0]],
    ["_damageInfo",[objNull, "None", "Scripted", false]]//[_shooter, _bodyPart, _ammoType, _isBackShot]
];

if (isNull _unit || {_className isEqualTo ""} || {_slot isEqualTo ""}) exitWith { false };
if (!GVAR(enableDestroyableItems)) exitWith { false };
// If the unit does not have this item in the specified container, exit with false
private _slotItems = [_unit, _slot] call FUNC(getItemsInSlot);
if !(_className in _slotItems) exitWith { false };

if !([_className] call FUNC(isDestroyableItem)) exitWith { false };

// Read destroyable item config (all fields) via shared helper, including effective chance
private _info = [_className] call FUNC(getDestroyableItemInfo);
_info params ["_damagedClass", "_destroyingSounds", "_destroyingAmmo", "_canDestroyFn", "_onDestroyedFn", "_effectiveChance"];

if (_effectiveChance <= 0) exitWith { false };

// Track which instance (state index + state) was actually destroyed
private _finalStateIdx = _itemIndex;
private _finalItemState = [];

private _wasReplaced = false;
private _indicesToTry = if (_itemIndex isEqualTo -1) then {
    private _list = [];
    for "_i" from ((count _slotItems) - 1) to 0 step -1 do {
        if ((_slotItems select _i) isEqualTo _className) then {
            _list pushBack _i;
        };
    };
    _list
} else {
    [_itemIndex]
};

{
    private _idx = _x;

    // Per-trial random roll based on the configured effective chance
    if ((_effectiveChance < 100) && {(random 100) >= _effectiveChance}) then {
        // Skip this index, try next
    } else {
        // Map container index to state index when none was provided
        private _stateIdx = _itemIndex;
        if (_stateIdx < 0) then {
            _stateIdx = _idx;
        };

        // Per-instance item state
        private _itemStateLocal = [];
        if (_stateIdx >= 0) then {
            _itemStateLocal = [_unit, _className, _slot, _stateIdx] call FUNC(getItemState);
        };

        // Optional per-instance CanDestroy gate
        private _skip = false;
        if (!isNil "_canDestroyFn") then {
            if !([_unit, _className, _slot, _stateIdx, _itemStateLocal, _damageInfo] call _canDestroyFn) then {
                _skip = true;
            };
        };

        if (!_skip) then {
            private _success = false;

            if (_damagedClass isEqualTo "") then {
                // No damaged variant configured: simply remove one instance of the item
                switch (_slot) do {
                    case SLOT_ASSIGNED: {
                        switch (true) do {
                            case (_className isEqualTo headgear _unit): {
                                removeHeadgear _unit;
                            };
                            case (_className isEqualTo goggles _unit): {
                                removeGoggles _unit;
                            };
                            default {
                                _unit unlinkItem _className;
                            };
                        };
                    };
                    case SLOT_EQUIPPED: {
                        switch (true) do {
                            case (_className isEqualTo (vest _unit)): {
                                removeVest _unit;
                            };
                            case (_className isEqualTo (uniform _unit)): {
                                removeUniform _unit;
                            };
                            case (_className isEqualTo (backpack _unit)): {
                                removeBackpack _unit;
                            };
                        };
                    };
                    case SLOT_WEAPONS: {
                        _unit removeWeapon _className;
                    };
                    case SLOT_VEST_CONTAINER: {
                        if (GVAR(enableDestroyableItems)) then {
                            _unit removeItemFromVest _className;
                        };
                    };
                    case SLOT_UNIFORM_CONTAINER: {
                        if (GVAR(enableDestroyableItems)) then {
                            _unit removeItemFromUniform _className;
                        };
                    };
                    case SLOT_BACKPACK_CONTAINER: {
                        if (GVAR(enableDestroyableItems)) then {
                            _unit removeItemFromBackpack _className;
                        };
                    };
                    default {
                        if (GVAR(enableDestroyableItems)) then {
                            _unit removeItem _className;
                        };
                    };
                };

                if (_stateIdx >= 0) then {
                    [_unit, _className, _slot, _stateIdx] call FUNC(removeItemState);
                } else {
                    [_unit, _className, _slot] call FUNC(removeItemState);
                };

                _success = true;
            } else {
                [_unit, _className, _damagedClass, _slot, (_stateIdx max 0), false, true] call FUNC(replaceItem);
                private _itemsNow = [_unit, _slot] call FUNC(getItemsInSlot);
                _success = _damagedClass in _itemsNow;
            };

            if (_success) then {
                _finalStateIdx = _stateIdx;
                _finalItemState = _itemStateLocal;
                _wasReplaced = true;
            };
        };
    };

    if (_wasReplaced) exitWith {};
} forEach _indicesToTry;

if (!_wasReplaced) exitWith { false };

// Play destruction sound if configured
if (_destroyingSounds isNotEqualTo []) then {
    private _soundClass = selectRandom _destroyingSounds;
    if (_soundClass isNotEqualTo "") then {
       playSound _soundClass;
    };
};

// Trigger destruction ammo (explosion/effect) if configured
if (_destroyingAmmo isNotEqualTo "") then {
    private _ammoObj = _destroyingAmmo createVehicle (_unit modelToWorld [0,0,-0.5]);
    _ammoObj setDamage 1;
};

// Optional onDestroyed callback: invoked after a successful destruction/
// replacement, with the same parameters plus the per-instance item state.
if (!isNil "_onDestroyedFn") then {
    [_unit, _className, _slot, _finalStateIdx, _finalItemState, _damageInfo] call _onDestroyedFn;
};

true

