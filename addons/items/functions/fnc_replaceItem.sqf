#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Replaces one instance of an item with another in a container (e.g. damaged variant, no-battery variant).
 * Handles assigned (linked items, headgear, goggles), vest, uniform, backpack, and default (removeItem/addItem).
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 * 1: Item classname to replace <STRING>
 * 2: Replacement classname <STRING>
 * 3: Container slot <STRING> ("assigned", "vest", "uniform", "backpack") or "object"
 * 4: State index of the item being replaced <NUMBER>
 * 5: Keep state (migrate to replacement) <BOOL> (default: false)
 * 6: For "assigned" only: link replacement in slot (true) or add to inventory (false) <BOOL> (default: true)
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * [player, "ACE_microDAGR", "ACE_microDAGR_NoPower", "vest", 0, false] call ace_items_fnc_replaceItem;
 * [player, "ACE_NVG_Gen1", "ACE_NVG_Gen1_NoBattery", "assigned", 0, false, true] call ace_items_fnc_replaceItem;
 *
 * Public: No
 */

params [
    ["_object", objNull, [objNull]],
    ["_className", "", [""]],
    ["_replacementClass", "", [""]],
    ["_slot", "", [""]],
    ["_index", 0, [0]],
    ["_keepState", false, [false]],
    ["_linkReplacement", true, [true]]
];

if (isNull _object || {_className isEqualTo ""} || {_replacementClass isEqualTo ""} || {_slot isEqualTo ""}) exitWith {
    TRACE_4("replaceItem invalid input",_object,_className,_replacementClass,_slot);
};

private _stateObj = [_object, _slot] call FUNC(getStateObject);
if (isNull _stateObj) exitWith {
    TRACE_2("replaceItem no state object for slot",_object,_slot);
};

// 1. Optionally capture state before remove (for migration)
private _oldState = nil;
if (_keepState) then {
    TRACE_3("replaceItem capturing old state",_object,_className,_slot);
    _oldState = [_object, _className, _slot, _index] call FUNC(getItemState);
};

// 2. Remove state at index for the old class
private _varKeyOld = [_slot, _className] call FUNC(getItemStateVarKey);
private _stateArray = _stateObj getVariable [_varKeyOld, []];
if (_index < count _stateArray) then {
    _stateArray deleteAt _index;
    _stateObj setVariable [_varKeyOld, [_stateArray, nil] select (_stateArray isEqualTo [])];
};
// 3. Physical replace
switch (_slot) do {
    case SLOT_ASSIGNED: {
        TRACE_3("replaceItem SLOT_ASSIGNED",_object,_className,_replacementClass);
        switch (true) do {
            case (_className isEqualTo headgear _object): {
                removeHeadgear _object;
                _object addHeadgear _replacementClass;
            };
            case (_className isEqualTo goggles _object): {
                removeGoggles _object;
                _object addGoggles _replacementClass;
            };
            default {
                _object unlinkItem _className;
                if (_linkReplacement) then {
                    _object linkItem _replacementClass;
                } else {
                    [_object, _replacementClass, false] call CBA_fnc_addItem;
                };
            };
        };
    };
    case SLOT_EQUIPPED: {
        // Equipped slot (vest/uniform/backpack) – inline migrate logic per sub-case
        TRACE_2("replaceItem SLOT_EQUIPPED %1 with %2",_className,_replacementClass);
        switch (true) do {
            case (_className isEqualTo (vest _object)): {
                TRACE_2("replaceItem vest %1 with %2",_className,_replacementClass);
                private _oldVestItems = vestItems _object;
                private _oldVestContainer = vestContainer _object;
                private _oldVestVars = allVariables _oldVestContainer;
                removeVest _object;
                _object addVest _replacementClass;
                { _object addItemToVest _x } forEach _oldVestItems;
                { _object setVariable [_x, _oldVestContainer getVariable _x] } forEach _oldVestVars;
            };
            case (_className isEqualTo (uniform _object)): {
                TRACE_2("replaceItem uniform %1 with %2",_className,_replacementClass);
                private _oldUniformItems = uniformItems _object;
                private _oldUniformContainer = uniformContainer _object;
                private _oldUniformVars = allVariables _oldUniformContainer;
                removeUniform _object;
                _object forceAddUniform _replacementClass;
                { _object addItemToUniform _x } forEach _oldUniformItems;
                { _object setVariable [_x, _oldUniformContainer getVariable _x] } forEach _oldUniformVars;
            };
            case (_className isEqualTo (backpack _object)): {
                TRACE_2("replaceItem backpack %1 with %2",_className,_replacementClass);
                private _oldBackpackItems = backpackItems _object;
                private _oldBackpackContainer = backpackContainer _object;
                private _oldBackpackVars = allVariables _oldBackpackContainer;
                removeBackpack _object;
                _object addBackpack _replacementClass;
                //{ _object addItemToBackpack _x } forEach _oldBackpackItems;
                { _object setVariable [_x, _oldBackpackContainer getVariable _x] } forEach _oldBackpackVars;
            };
        };
    };
    case SLOT_WEAPONS: {
        TRACE_2("replaceItem SLOT_WEAPONS %1 with %2",_className,_replacementClass);

        // Capture all items (attachments, loaded mags, etc.) tied to this weapon
        private _weaponItemsAll = weaponsItems _object;
        private _oldWeaponItems = [];
        {
            if ((_x select 0) isEqualTo _className) exitWith {
                _oldWeaponItems = _x; // [weaponClass, item1, item2, ...]
            };
        } forEach _weaponItemsAll;

        // Remove old weapon
        _object removeWeapon _className;

        // Add replacement weapon
        _object addWeapon _replacementClass;

        // Re-attach previous attachments/magazines to the new weapon
        if (_oldWeaponItems isNotEqualTo [] && {count _oldWeaponItems > 1}) then {
            for "_i" from 1 to (count _oldWeaponItems - 1) do {
                private _itm = _oldWeaponItems select _i;
                if (_itm isNotEqualTo "") then {
                    // addWeaponItem handles both attachments and compatible magazines
                    _object addWeaponItem [_replacementClass, _itm];
                };
            };
        };
    };
    case SLOT_VEST_CONTAINER: {
        TRACE_2("replaceItem SLOT_VEST_CONTAINER %1 with %2",_className,_replacementClass);
        _object removeItemFromVest _className;
        [vestContainer _object, _replacementClass, 1, false] call CBA_fnc_addItemCargo;
    };
    case SLOT_UNIFORM_CONTAINER: {
        TRACE_2("replaceItem SLOT_UNIFORM_CONTAINER %1 with %2",_className,_replacementClass);
        _object removeItemFromUniform _className;
        [uniformContainer _object, _replacementClass, 1, false] call CBA_fnc_addItemCargo;
    };
    case SLOT_BACKPACK_CONTAINER: {
        TRACE_2("replaceItem SLOT_BACKPACK_CONTAINER %1 with %2",_className,_replacementClass);
        _object removeItemFromBackpack _className;
        [backpackContainer _object, _replacementClass, 1, false] call CBA_fnc_addItemCargo;
    };
    case SLOT_OBJECT: {
        TRACE_2("replaceItem SLOT_OBJECT %1 with %2",_className,_replacementClass);
        _object removeItem _className;
        [itemCargo _object, _replacementClass, 1, false] call CBA_fnc_addItemCargo;
    };
    case SLOT_PRIMARY_WEAPON_ITEMS: {
        TRACE_2("replaceItem SLOT_PRIMARY_WEAPON_ITEMS %1 with %2",_className,_replacementClass);
        _object removePrimaryWeaponItem _className;
        _object addPrimaryWeaponItem _replacementClass;
    };
    case SLOT_SECONDARY_WEAPON_ITEMS: {
        TRACE_2("replaceItem SLOT_SECONDARY_WEAPON_ITEMS %1 with %2",_className,_replacementClass);
        _object removeSecondaryWeaponItem _className;
        _object addSecondaryWeaponItem _replacementClass;
    };
    case SLOT_HANDGUN_WEAPON_ITEMS: {
        TRACE_2("replaceItem SLOT_HANDGUN_WEAPON_ITEMS %1 with %2",_className,_replacementClass);
        _object removeHandgunItem _className;
        _object addHandgunItem _replacementClass;
    };
    case SLOT_BINOCULAR_ITEMS: {
        TRACE_2("replaceItem SLOT_BINOCULAR_ITEMS %1 with %2",_className,_replacementClass);
        _object removeBinocularItem _className;
        _object addBinocularItem _replacementClass;
    };
    default {
        TRACE_2("replaceItem Without Slot %1 with %2",_className,_replacementClass);
        _object removeItem _className;
        if (_object call CBA_fnc_isPerson) then {
            [_object, _replacementClass, false] call CBA_fnc_addItem;
        } else {
            [_object, _replacementClass, 1, false] call CBA_fnc_addItemCargo;
        };
    };
};

// 4. Optionally migrate state to replacement (new item is first of its class → index 0)
if (_keepState && {!isNil "_oldState"} && {_oldState isNotEqualTo []}) then {
    private _updates = [];
    [_oldState, {
        _updates pushBack [_key, [_value, _replacementClass] select (_key isEqualTo I_KEY_ITEM_STATE_CLASSNAME)];
    }] call CBA_fnc_hashEachPair;
    [_object, _replacementClass, _slot, 0, _updates] call FUNC(setItemState);
};
