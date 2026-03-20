#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Attempts to consume (remove) a single usable item of the given class from a unit.
 *
 * Behaviour:
 * - Only removes an item instance that is currently usable for the given operation mode
 *   (delegates all restriction checks to ace_items_fnc_hasUsableItem).
 * - If no specific container slot is provided, it searches the unit's inventory in a
 *   fixed priority order and removes the first matching instance it finds.
 * - If a specific container slot is provided, it will only attempt to consume from
 *   that slot and will not fall back to others.
 *
 * Default search / consumption order:
 *   1. Vest cargo
 *   2. Backpack cargo
 *   3. Uniform cargo
 *   4. Assigned items (e.g. NVGs, radios, GPS)
 *   5. Equipped containers (vest/uniform/backpack themselves)
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Item classname <STRING>
 * 2: Operation mode name <STRING> (default: ENUM_STRING_OPERATIONMODES_USE)
 * 3: Optional container slot <STRING>
 *    - Expected values: SLOT_VEST_CONTAINER, SLOT_BACKPACK_CONTAINER,
 *      SLOT_UNIFORM_CONTAINER, SLOT_ASSIGNED, SLOT_EQUIPPED
 *    - Empty string "" = search all slots in the default order above.
 *
 * Return Value:
 * 0: Was an item instance successfully removed <BOOL>
 * 1: Slot that the item was removed from (one of the SLOT_* constants, or "" if none) <STRING>
 * 2: If the item is a magazine class, Ammo count of the item before consumption; otherwise -1 <NUMBER>
 * 3: If the item is a magazine class, its configured round count; otherwise -1 <NUMBER>
 *
 * Examples:
 * - Consume a bandage (if usable with default "Use" mode) from any allowed slot:
 *   [ACE_player, "ACE_elasticBandage"] call ace_items_fnc_tryConsumeItem;
 *
 * - Consume a morphine auto-injector specifically from the vest (if usable there):
 *   [ACE_player, "ACE_morphine", ENUM_STRING_OPERATIONMODES_USE, SLOT_VEST_CONTAINER]
 *     call ace_items_fnc_tryConsumeItem;
 *
 * - Consume a MicroDAGR only if it can be used in "Display on Wrist" mode:
 *   [ACE_player, "ACE_microDAGR", ENUM_STRING_OPERATIONMODES_WRIST_DISPLAY]
 *     call ace_items_fnc_tryConsumeItem;
 *
 * Public: Yes
 */

params [
    ["_object", objNull, [objNull]],
    ["_itemClass", "", [""]],
    ["_containerSlot", "", [""]],
    ["_operationMode", ENUM_STRING_OPERATIONMODES_USE, [""]]
];
// Basic argument validation
if (isNull _object) exitWith { [false, "", -1, -1] };
if (_itemClass isEqualTo "" || {_operationMode isEqualTo ""}) exitWith { [false, "", -1, -1] };

// Fast-fail if there is no usable item according to restrictions
if !([_object, _itemClass, _operationMode, _containerSlot] call FUNC(hasUsableItem)) exitWith { [false, "", -1, -1] };

// Internal helper to try removing one instance from a specific slot
private _fnc_removeFromSlot = {
    params ["_object", "_itemClass", "_slot", "_operationMode"];

    // Ensure the item is present and usable from this specific slot before removing
    if !([_object, _itemClass, _operationMode, _slot] call FUNC(hasUsableItem)) exitWith { [false, "", -1, -1] };

    // Resolve the concrete container object for this slot (unit, vest, uniform, backpack, etc.)
    private _container = [_object, _slot] call EFUNC(items,getStateObject);
    if (isNull _container) exitWith { [false, "", -1, -1] };

    // If this item is a magazine, look up its configured round count and treat
    // that as the per-magazine ammo count before consumption; otherwise -1/-1.
    private _ammoBefore = -1;
    private _ammoConfig = -1;
    if (isClass (configFile >> "CfgMagazines" >> _itemClass)) then {
        _ammoConfig = getNumber (configFile >> "CfgMagazines" >> _itemClass >> "count");
        _ammoBefore = _ammoConfig;
    };

    private _result = false;
    switch (_slot) do {
        case SLOT_ASSIGNED: {
            switch (true) do {
                case (_itemClass isEqualTo headgear _object): {
                    removeHeadgear _object;
                    _result = (headgear _object) isEqualTo "";
                };
                case (_itemClass isEqualTo goggles _object): {
                    removeGoggles _object;
                    _result = (goggles _object) isEqualTo "";
                };
                default {
                    _object unlinkItem _itemClass;
                    _result = !(_itemClass in (assignedItems _object));
                };
            };
        };
        case SLOT_EQUIPPED: {
          switch (true) do {
            case (_itemClass isEqualTo (uniform _object)): {
              removeUniform _object;
              _result = (uniform _object) isEqualTo "";
            };
            case (_itemClass isEqualTo (vest _object)): {
              removeVest _object;
              _result = (vest _object) isEqualTo "";
            };
            case (_itemClass isEqualTo (backpack _object)): {
              removeBackpack _object;
              _result = (backpack _object) isEqualTo "";
            };
            default { };                     
          };
        };
        case SLOT_VEST_CONTAINER: {           
            private _beforeCount =0;
            if (_ammoConfig>0) then {               
              private _magazines = (magazinesAmmoCargo vestContainer _object) select {(_x select 0) isEqualTo _itemClass};
              _beforeCount = count _magazines;
              //last magazine in _magazines
              private _lastMagazine = _magazines select -1 ;
              _ammoBefore = _lastMagazine select 1;
            }else{
              _beforeCount = count ((vestItems _object) select {_x isEqualTo _itemClass});
            };
            _object removeItemFromVest _itemClass;//the last one 
            private _afterCount = count ((vestItems _object) select {_x isEqualTo _itemClass});
            _result = _afterCount < _beforeCount;
        };
        case SLOT_UNIFORM_CONTAINER: {
            private _beforeCount =0;
            if (_ammoConfig>0) then {               
             private _magazines = (magazinesAmmoCargo uniformContainer _object) select {(_x select 0) isEqualTo _itemClass};
              _beforeCount = count _magazines;
              //last magazine in _magazines
              private _lastMagazine = _magazines  select -1;
              _ammoBefore = _lastMagazine select 1;
            }else{
              _beforeCount = count ((uniformItems _object) select {_x isEqualTo _itemClass});
            };
            _object removeItemFromUniform _itemClass;//the last one
            private _afterCount = count ((uniformItems _object) select {_x isEqualTo _itemClass});
            _result = _afterCount < _beforeCount;
        };
        case SLOT_BACKPACK_CONTAINER: {    
            private _beforeCount =0;
            if (_ammoConfig>0) then {               
              private _magazines = (magazinesAmmoCargo backpackContainer _object) select {(_x select 0) isEqualTo _itemClass};
              _beforeCount = count _magazines;
              //last magazine in _magazines
              private _lastMagazine = _magazines  select -1;
              _ammoBefore = _lastMagazine select 1;
            }else{
              _beforeCount = count ((backpackItems _object) select {_x isEqualTo _itemClass});
            };
            _object removeItemFromBackpack _itemClass;//the last one 
            private _afterCount = count ((backpackItems _object) select {_x isEqualTo _itemClass});
            _result = _afterCount < _beforeCount;
        };
        case SLOT_OBJECT: {
           
            private _beforeCount =0;
            if (_ammoConfig>0) then {               
              private _magazines = (magazinesAmmoCargo _object) select {(_x select 0) isEqualTo _itemClass};
              _beforeCount = count _magazines;
              //last magazine in _magazines
              private _lastMagazine = _magazines  select -1;
              _ammoBefore = _lastMagazine select 1;
            }else{
              _beforeCount = count ((items _object) select {_x isEqualTo _itemClass});
            };
            _object removeItem _itemClass;//the last one
            private _afterCount = count ((items _object) select {_x isEqualTo _itemClass});
            _result = _afterCount < _beforeCount;
        };
        case SLOT_WEAPONS: {
            _object removeWeapon _itemClass;
            _result = !(_itemClass in (weapons _object));
        };
        default {
            private _beforeCount =0;
            if (_ammoConfig>0) then {               
              private _magazines = (magazinesAmmoCargo _object) select {(_x select 0) isEqualTo _itemClass};
              _beforeCount = count _magazines;
              //last magazine in _magazines
              private _lastMagazine = _magazines  select -1;
              _ammoBefore = _lastMagazine select 1;
            }else{
              _beforeCount = count ((items _object) select {_x isEqualTo _itemClass});
            };
            _object removeItem _itemClass;//the last one
            private _afterCount = count ((items _object) select {_x isEqualTo _itemClass});
            _result = _afterCount < _beforeCount;
        };
    };
    if (!_result) exitWith { [false, "", -1, -1] };

    [true, _slot, _ammoBefore, _ammoConfig]
};

// If a specific container slot is requested, only try that one.
if (_containerSlot isNotEqualTo "") exitWith {
    [_object, _itemClass, _containerSlot] call _fnc_removeFromSlot
};

// Consumption order: vest, backpack, uniform, then person slots
private _result = [false, "", -1, -1];

{
    _result = [_object, _itemClass, _x, _operationMode] call _fnc_removeFromSlot;
    if (_result select 0) exitWith {};
} forEach [
    SLOT_VEST_CONTAINER,
    SLOT_BACKPACK_CONTAINER,
    SLOT_UNIFORM_CONTAINER,
    SLOT_ASSIGNED,
    SLOT_EQUIPPED
];

_result

