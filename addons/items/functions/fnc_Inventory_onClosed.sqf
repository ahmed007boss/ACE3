#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Fires when a unit closes their inventory.
 * Takes a new snapshot and diffs against the snapshots taken on open.
 * Migrates state for any items that moved between containers.
 * Clears the stored snapshots after processing.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container <OBJECT>
 *
 * Return Value:
 * None <NIL>
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_slot", objNull, [objNull]]
];
TRACE_2("onInventoryClosed",_unit,_slot);

if (isNull _unit) exitWith {
    WARNING_1("onInventoryClosed EXIT null unit: unit=%1",_unit);
};
if !(local _unit) exitWith {
    WARNING_1("onInventoryClosed EXIT unit not local: unit=%1",_unit);
};

private _session = [_unit] call FUNC(Inventory_getSession);
_session params ["_snapshotBefore", "_containerMap", "_primaryContainerObj", "_secondaryContainerObj", "_primarySnapshotBefore", "_secondarySnapshotBefore"];

if (isNil "_snapshotBefore") exitWith {
    TRACE_1("onInventoryClosed: no snapshot found",_unit);
};

// Clear stored session immediately to avoid double processing
_unit setVariable [QGVAR(inventorySnapshot),              nil];
_unit setVariable [QGVAR(inventoryContainerMap),          nil];
_unit setVariable [QGVAR(inventoryPrimarySnapshot),       nil];
_unit setVariable [QGVAR(inventorySecondarySnapshot),     nil];
_unit setVariable [QGVAR(inventoryPrimaryContainerObj),   nil];
_unit setVariable [QGVAR(inventorySecondaryContainerObj), nil];

TRACE_2("onInventoryClosed: primaryContainer %1 secondaryContainer %2",_primaryContainerObj,_secondaryContainerObj);
private _after = [_unit, _primaryContainerObj, _secondaryContainerObj] call FUNC(Inventory_snapshotAllContainers);
_after params ["_snapshotAfter", "_primarySnapshotAfter", "_secondarySnapshotAfter"];

[_snapshotBefore, _snapshotAfter, _primarySnapshotBefore, _primarySnapshotAfter, _secondarySnapshotBefore, _secondarySnapshotAfter, _containerMap] call FUNC(Inventory_diffAndEmitEvents);

TRACE_1("onInventoryClosed: diff complete",_unit);
