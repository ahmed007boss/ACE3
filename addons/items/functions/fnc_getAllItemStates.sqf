#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Returns all item states on a unit or container object across all slots.
 * Reads from the correct state objects (unit for assigned and equipped, container objects for vest/uniform/backpack contents).
 * Slot "equipped" covers the vest, uniform, and backpack items themselves (worn containers), not their contents.
 * When the argument is a non-unit object (box, vehicle, etc.), reads item states stored on that object (slot "object").
 *
 * Arguments:
 * 0: Unit or container object <OBJECT>
 *
 * Return Value:
 * Array of item state HashMaps <ARRAY>
 *
 * Example:
 * [player] call ace_items_fnc_getAllItemStates;
 * [myBox] call ace_items_fnc_getAllItemStates;
 *
 * Public: Yes
 */

params [["_unit", objNull, [objNull]]];
TRACE_1("params",_unit);

if (isNull _unit) exitWith {
    WARNING_1("getAllItemStates EXIT null unit: unit=%1",_unit);
    []
};

private _result = [];

// For units (person) check all slots
if (_unit call CBA_fnc_isPerson) then {
    private _slotMap = [
        [SLOT_ASSIGNED, _unit],
        [SLOT_EQUIPPED, _unit],
        [SLOT_VEST_CONTAINER,     vestContainer _unit],
        [SLOT_UNIFORM_CONTAINER,  uniformContainer _unit],
        [SLOT_BACKPACK_CONTAINER, backpackContainer _unit]
    ];

    {
        _x params ["_slot", "_stateObj"];
        if (isNull _stateObj) then { continue };

        // assigned = linked slot items (map, compass, watch, etc.); state for these is stored on the unit
        // equipped = vest, uniform, backpack themselves (worn containers); state on unit, one per class
        private _items = [_unit, _slot] call FUNC(getItemsInSlot);

        private _itemsToIterate = if (_slot isEqualTo SLOT_EQUIPPED) then { _items } else { _items call EFUNC(common,uniqueItemsAndEquipment) };
        {
            [_unit, _slot, _x] call FUNC(syncItemStateToSlotCount);
            private _varKey = [_slot, _x] call FUNC(getItemStateVarKey);
            private _stateArray = _stateObj getVariable [_varKey, []];
            if (_stateArray isNotEqualTo []) then {
                _result append _stateArray;
            };
        } forEach _itemsToIterate;
    } forEach _slotMap;
} else {
    // For non-unit containers: state is stored on the object with key ACE_object_itemStates_<itemClass>
    private _allItems = [_unit, SLOT_OBJECT] call FUNC(getItemsInSlot);
    private _itemClasses = _allItems arrayIntersect _allItems;
    {
        [_unit, SLOT_OBJECT, _x] call FUNC(syncItemStateToSlotCount);
        private _varKey = [SLOT_OBJECT, _x] call FUNC(getItemStateVarKey);
        private _stateArray = _unit getVariable [_varKey, []];
        if (_stateArray isNotEqualTo []) then {
            _result append _stateArray;
        };
    } forEach _itemClasses;
};

TRACE_1("getAllItemStates DONE resultCount",count _result);
_result
