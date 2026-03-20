#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Fires when a unit opens their inventory.
 * Takes a full snapshot of the unit's container contents, and optional
 * snapshots for primary/secondary external containers.
 * Also builds a netId->object map for later diff resolution.
 * Snapshots are stored on the unit for use by onInventoryClosed.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Primary container <OBJECT>
 * 2: Secondary container <OBJECT>
 *
 * Return Value:
 * None <NIL>
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_primaryContainer", objNull, [objNull]],   // main external container (box, vehicle, other unit, etc.)
    ["_secondaryContainer", objNull, [objNull]]  // secondary/ground container if present
];

TRACE_3("onInventoryOpened",_unit,_primaryContainer,_secondaryContainer);

if (isNull _unit) exitWith {
    WARNING_1("onInventoryOpened EXIT null unit: unit=%1",_unit);
};
if !(local _unit) exitWith {
    WARNING_1("onInventoryOpened EXIT unit not local: unit=%1",_unit);
};

// Take snapshots of unit and both external containers
private _snapshots = [_unit, _primaryContainer, _secondaryContainer] call FUNC(Inventory_snapshotAllContainers);
_snapshots params ["_snapshot", "_primarySnapshot", "_secondarySnapshot"];

// Build netId -> object map so we can resolve objects during diff
private _containerMap = [] call CBA_fnc_hashCreate;

// Key must match Inventory_snapshotContainer: use slot when netId is "" (SP)
private _fnc_addToMap = {
    params ["_obj", "_slotName"];
    if (isNull _obj) exitWith {};
    private _stateObj = [_obj, _slotName] call FUNC(getStateObject);
    if (isNull _stateObj) exitWith {};
    private _netId = netId _stateObj;
    // Must match Inventory_snapshotContainer key logic: slotName for unit (CAManBase), netId for containers
    private _key = [_netId, _slotName] select ((_netId isEqualTo "") || {_stateObj isKindOf "CAManBase"});
    [_containerMap, _key, _stateObj] call CBA_fnc_hashSet;
};

{
    [_unit, _x] call _fnc_addToMap;
} forEach SLOTS_ALL;

// Register external containers under fixed keys so unit/primary/secondary are always distinct
// (in SP netId is "" so both would otherwise use SLOT_OBJECT and overwrite)
if (!isNull _primaryContainer) then {
    [_containerMap, "primary", _primaryContainer] call CBA_fnc_hashSet;
};
if (!isNull _secondaryContainer && {_secondaryContainer isNotEqualTo _primaryContainer}) then {
    [_containerMap, "secondary", _secondaryContainer] call CBA_fnc_hashSet;
};

// Store snapshots, container objects, and container map (CBA hashes survive setVariable)
_unit setVariable [QGVAR(inventorySnapshot), _snapshot];
_unit setVariable [QGVAR(inventoryContainerMap), _containerMap];
_unit setVariable [QGVAR(inventoryPrimarySnapshot), _primarySnapshot];
_unit setVariable [QGVAR(inventorySecondarySnapshot), _secondarySnapshot];
// Store container objects so onItemPut can re-snapshot them for mid-session diffs
_unit setVariable [QGVAR(inventoryPrimaryContainerObj), _primaryContainer];
_unit setVariable [QGVAR(inventorySecondaryContainerObj), _secondaryContainer];

private _snapshotKeys = if (_snapshot isEqualType [] && {count _snapshot >= 2}) then { _snapshot select 1 } else { [] };
TRACE_2("onInventoryOpened: snapshot taken",_unit,count _snapshotKeys);
