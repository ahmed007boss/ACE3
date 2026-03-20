#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Diffs container snapshots (before/after inventory open) and emits an
 * inventoryChanged event for any items that moved between containers.
 * Handles duplicate items by tracking counts, not just presence.
 * Supports optional primary/secondary external container snapshots.
 *
 * Arguments:
 * 0: Unit snapshot before inventory open <ARRAY> (CBA HashMap from fnc_Inventory_snapshotContainer)
 * 1: Unit snapshot after inventory close  <ARRAY> (CBA HashMap from fnc_Inventory_snapshotContainer)
 * 2: Primary external snapshot before     <ARRAY> (CBA HashMap or empty hash)
 * 3: Primary external snapshot after      <ARRAY> (CBA HashMap or empty hash)
 * 4: Secondary external snapshot before   <ARRAY> (CBA HashMap or empty hash)
 * 5: Secondary external snapshot after    <ARRAY> (CBA HashMap or empty hash)
 * 6: HashMap of netId -> container object (for resolving objects from snapshot keys) <ARRAY>
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * [_unitBefore, _unitAfter, _primaryBefore, _primaryAfter, _secondaryBefore, _secondaryAfter, _containerMap]
 * call ace_items_fnc_Inventory_diffAndEmitEvents;
 *
 * Public: No
 */

params [
    ["_unitBefore",      [], [[]]],
    ["_unitAfter",       [], [[]]],
    ["_primaryBefore",   [], [[]]],
    ["_primaryAfter",    [], [[]]],
    ["_secondaryBefore", [], [[]]],
    ["_secondaryAfter",  [], [[]]],
    ["_containerMap",    [], [[]]]
];

TRACE_1("Inventory_diffAndEmitEvents called",_unitBefore);

// CBA hash to [[key, value], ...] using internal structure ["#CBA_HASH#", keys, values, default]
private _fnc_hashToPairs = {
    params ["_hash"];
    if (_hash isEqualType [] && {count _hash >= 3} && {(_hash select 0) isEqualTo "#CBA_HASH#"}) then {
        private _keys = _hash select 1;
        private _vals = _hash select 2;
        private _out = [];
        for "_i" from 0 to (count _keys - 1) do {
            _out pushBack [_keys select _i, _vals select _i];
        };
        _out
    } else {
        []
    };
};

// Merge a single-container snapshot hash into _base under a fixed key (so primary/secondary
// never overwrite each other when netId is "" and both would use SLOT_OBJECT).
private _fnc_mergeSnapshotUnderKey = {
    params ["_base", "_hash", "_key"];
    if (_hash isEqualType [] && {count _hash >= 3} && {(_hash select 0) isEqualTo "#CBA_HASH#"}) then {
        private _keys = _hash select 1;
        private _vals = _hash select 2;
        if (count _keys > 0) then {
            [_base, _key, _vals select 0] call CBA_fnc_hashSet;
        };
    };
};

private _snapshotBefore = +_unitBefore;
[_snapshotBefore, _primaryBefore, "primary"] call _fnc_mergeSnapshotUnderKey;
[_snapshotBefore, _secondaryBefore, "secondary"] call _fnc_mergeSnapshotUnderKey;

private _snapshotAfter = +_unitAfter;
[_snapshotAfter, _primaryAfter, "primary"] call _fnc_mergeSnapshotUnderKey;
[_snapshotAfter, _secondaryAfter, "secondary"] call _fnc_mergeSnapshotUnderKey;

private _beforeArr = [_snapshotBefore] call _fnc_hashToPairs;
private _afterArr  = [_snapshotAfter] call _fnc_hashToPairs;

TRACE_2("Inventory_diffAndEmitEvents counts",count _beforeArr,count _afterArr);
{
    _x params ["_netId","_slotAndItems"];
    _slotAndItems params ["_slot","_items"];
    TRACE_4("Inventory_diff BEFORE",_netId,_slot,count _items,_items);
} forEach _beforeArr;
{
    _x params ["_netId","_slotAndItems"];
    _slotAndItems params ["_slot","_items"];
    TRACE_4("Inventory_diff AFTER",_netId,_slot,count _items,_items);
} forEach _afterArr;

if (_beforeArr isEqualTo [] || {_afterArr isEqualTo []}) exitWith {
    TRACE_1("Inventory_diffAndEmitEvents EXIT empty snapshot",_snapshotBefore);
};

// Build count maps from array: {key: {className: count}}
private _fnc_buildCountMapFromArray = {
    params ["_arr"];
    private _countMap = [] call CBA_fnc_hashCreate;
    {
        _x params ["_key", "_slotAndItems"];
        _slotAndItems params ["_slot", "_items"];
        private _itemCounts = [] call CBA_fnc_hashCreate;
        {
            private _count = [_itemCounts, _x] call CBA_fnc_hashGet;
            if (isNil "_count") then { _count = 0 };
            [_itemCounts, _x, _count + 1] call CBA_fnc_hashSet;
        } forEach _items;
        [_countMap, _key, [_slot, _itemCounts]] call CBA_fnc_hashSet;
    } forEach _arr;
    _countMap
};

private _beforeMap = [_beforeArr] call _fnc_buildCountMapFromArray;
private _afterMap  = [_afterArr] call _fnc_buildCountMapFromArray;

// Find all items that decreased in count in any container (items that left)
// Match them against containers where count increased (items that arrived)
private _removedItems = []; // [[className, srcNetId, srcSlot], ...]
private _addedItems   = []; // [[className, destNetId, destSlot], ...]

{
    _x params ["_netId", "_beforeSlotAndCounts"];
    _beforeSlotAndCounts params ["_slot", "_beforeCounts"];

    private _afterSlotAndCounts = [_afterMap, _netId] call CBA_fnc_hashGet;
    private _afterCounts = if (isNil "_afterSlotAndCounts") then {
        [] call CBA_fnc_hashCreate
    } else {
        _afterSlotAndCounts select 1
    };

    {
        _x params ["_className", "_beforeCount"];
        private _afterCount = [_afterCounts, _className] call CBA_fnc_hashGet;
        if (isNil "_afterCount") then { _afterCount = 0 };

        private _diff = _beforeCount - _afterCount;
        for "_i" from 1 to _diff do {
            _removedItems pushBack [_className, _netId, _slot];
        };
    } forEach ([_beforeCounts] call _fnc_hashToPairs);
} forEach ([_beforeMap] call _fnc_hashToPairs);

{
    _x params ["_netId", "_afterSlotAndCounts"];
    _afterSlotAndCounts params ["_slot", "_afterCounts"];

    private _beforeSlotAndCounts = [_beforeMap, _netId] call CBA_fnc_hashGet;
    private _beforeCounts = if (isNil "_beforeSlotAndCounts") then {
        [] call CBA_fnc_hashCreate
    } else {
        _beforeSlotAndCounts select 1
    };

    {
        _x params ["_className", "_afterCount"];
        private _beforeCount = [_beforeCounts, _className] call CBA_fnc_hashGet;
        if (isNil "_beforeCount") then { _beforeCount = 0 };

        private _diff = _afterCount - _beforeCount;
        for "_i" from 1 to _diff do {
            _addedItems pushBack [_className, _netId, _slot];
        };
    } forEach ([_afterCounts] call _fnc_hashToPairs);
} forEach ([_afterMap] call _fnc_hashToPairs);

TRACE_2("Inventory_diffAndEmitEvents: removed/added",_removedItems,_addedItems);
TRACE_4("Inventory_diffAndEmitEvents DIFF",count _removedItems,count _addedItems,_removedItems,_addedItems);

// Match each added item to a removed item of the same classname and emit event.
// Returns the number of events successfully emitted.
private _emitCount = 0;
{
    _x params ["_addedClass", "_destNetId", "_destSlot"];

    private _matchIndex = _removedItems findIf { (_x select 0) isEqualTo _addedClass };
    if (_matchIndex isEqualTo -1) exitWith {
        TRACE_1("Inventory_diffAndEmitEvents: no source found for added item",_addedClass);
    };

    private _match = _removedItems deleteAt _matchIndex;
    _match params ["_removedClass", "_srcNetId", "_srcSlot"];

    // Resolve container objects from netIds
    private _srcObj  = [_containerMap, _srcNetId]  call CBA_fnc_hashGet;
    private _destObj = [_containerMap, _destNetId] call CBA_fnc_hashGet;

    if (isNil "_srcObj"  || {isNull _srcObj}) exitWith {
        TRACE_1("Inventory_diffAndEmitEvents: srcObj not found",_srcNetId);
    };
    if (isNil "_destObj" || {isNull _destObj}) exitWith {
        TRACE_1("Inventory_diffAndEmitEvents: destObj not found",_destNetId);
    };

    TRACE_4("Inventory_diffAndEmitEvents: emitting event",_addedClass,_srcNetId,_destNetId,_destSlot);
    [QGVAR(inventoryChanged), [_srcObj, _destObj, _addedClass, _srcSlot, _destSlot]] call CBA_fnc_localEvent;
    _emitCount = _emitCount + 1;
} forEach _addedItems;

TRACE_2("Inventory_diffAndEmitEvents DONE",_addedItems,_emitCount);
_emitCount

