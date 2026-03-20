#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Fires when a unit places an item into a container while inventory is open.
 *
 * Takes a fresh snapshot of the unit's containers and diffs it against the
 * stored snapshot, emitting inventoryChanged for any moved items.
 * Duplicate EH fires are naturally suppressed: the second fire sees no delta
 * against the already-updated snapshot.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container object <OBJECT> (destination)
 * 2: Item classname <STRING>
 *
 * Return Value:
 * None <NIL>
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_destContainerObj", objNull, [objNull]],
    ["_item", "", [""]]
];
TRACE_3("onItemPut",_unit,_destContainerObj,_item);

if (isNull _unit || {isNull _destContainerObj}) exitWith {
    WARNING_2("onItemPut EXIT bad params: unit=%1 dest=%2",_unit,_destContainerObj);
};
if !(local _unit) exitWith {
    WARNING_2("onItemPut EXIT unit not local: unit=%1 dest=%2",_unit,_destContainerObj);
};

private _session = [_unit] call FUNC(Inventory_getSession);
_session params ["_snapshot", "_containerMap", "_primaryContainerObj", "_secondaryContainerObj", "_primarySnapshotBefore", "_secondarySnapshotBefore"];

if (isNil "_snapshot") exitWith {
    TRACE_1("onItemPut: no snapshot, inventory not open",_item);
};
if (isNil "_containerMap") exitWith {
    TRACE_1("onItemPut EXIT no containerMap",_unit);
};

// Register dest in containerMap if it's an external container not yet tracked
private _isExternalDest = _destContainerObj != _unit
    && {_destContainerObj != (vestContainer    _unit)}
    && {_destContainerObj != (uniformContainer _unit)}
    && {_destContainerObj != (backpackContainer _unit)};
if (_isExternalDest) then {
    private _destNetId = netId _destContainerObj;
    if (_destNetId isNotEqualTo "") then {
        [_containerMap, _destNetId, _destContainerObj] call CBA_fnc_hashSet;
        _unit setVariable [QGVAR(inventoryContainerMap), _containerMap];
        [QGVAR(externalContainerChanged), [_destNetId, _item, "add"]] call CBA_fnc_globalEvent;
    };
};

// Re-snapshot all containers and diff. Cross-container moves (box→unit, unit→box, etc.) are all detected.
// The second duplicate-EH fire finds no delta (all snapshots already updated) and emits nothing.
TRACE_2("onItemPut: diffing snapshots",_unit,_item);
private _after = [_unit, _primaryContainerObj, _secondaryContainerObj] call FUNC(Inventory_snapshotAllContainers);
_after params ["_snapshotAfter", "_primarySnapshotAfter", "_secondarySnapshotAfter"];

[_snapshot, _snapshotAfter, _primarySnapshotBefore, _primarySnapshotAfter, _secondarySnapshotBefore, _secondarySnapshotAfter, _containerMap] call FUNC(Inventory_diffAndEmitEvents);
[_unit, _snapshotAfter, _primarySnapshotAfter, _secondarySnapshotAfter] call FUNC(Inventory_updateSession);

TRACE_1("onItemPut DONE",_unit);
