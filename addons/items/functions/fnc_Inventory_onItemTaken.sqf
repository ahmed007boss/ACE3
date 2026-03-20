#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Fires when a unit picks up an item from a container (directly or via open inventory).
 *
 * - When inventory is OPEN (snapshot exists):
 *     Runs a full snapshot diff across unit + primary + secondary containers and emits
 *     inventoryChanged for any moved items. Arma's Put EH does not fire when taking
 *     from external containers, so the diff must happen here.
 *     Double-fire is naturally deduplicated: first fire detects the move and updates
 *     all snapshots; second fire finds no delta.
 *
 * - When inventory is CLOSED (no snapshot):
 *     Resolves the destination on the unit directly and emits inventoryChanged immediately.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container <OBJECT> (source — ground object, box, vehicle, unit container, etc.)
 * 2: Item classname <STRING>
 *
 * Return Value:
 * None <NIL>
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_slot", objNull, [objNull]],
    ["_item", "", [""]]
];
TRACE_3("onItemTaken",_unit,_slot,_item);

if (isNull _unit || {isNull _slot} || {_item isEqualTo ""}) exitWith {
    WARNING_3("onItemTaken EXIT bad params: unit=%1 container=%2 item=%3",_unit,_slot,_item);
};
if !(local _unit) exitWith {
    WARNING_3("onItemTaken EXIT unit not local: unit=%1 container=%2 item=%3",_unit,_slot,_item);
};

// Resolve source slot from container identity
private _srcObj  = _slot;
private _srcSlot = if      (_slot isEqualTo (vestContainer    _unit)) then { SLOT_VEST_CONTAINER    }
                   else { if (_slot isEqualTo (uniformContainer _unit)) then { SLOT_UNIFORM_CONTAINER }
                   else { if (_slot isEqualTo (backpackContainer _unit)) then { SLOT_BACKPACK_CONTAINER }
                   else { ["object", "weapons"] select (_slot isEqualTo _unit) } } };

// Always broadcast external container removal so other machines can patch their snapshots
private _srcNetId = netId _srcObj;
private _isExternalSrc = _slot != _unit
    && {_slot != (vestContainer    _unit)}
    && {_slot != (uniformContainer _unit)}
    && {_slot != (backpackContainer _unit)};
if (_isExternalSrc && {_srcNetId isNotEqualTo ""}) then {
    [QGVAR(externalContainerChanged), [_srcNetId, _item, "remove"]] call CBA_fnc_globalEvent;
};

// If inventory is open, run a full diff now.
// Arma's Put EH does not fire when taking from external containers, so we cannot rely on
// onItemPut to detect box→unit moves. Double-fire deduplication is handled naturally:
// the first fire updates all snapshots; the second fire finds no delta and emits nothing.
private _session = [_unit] call FUNC(Inventory_getSession);
_session params ["_snapshot", "_containerMap", "_primaryContainerObj", "_secondaryContainerObj", "_primarySnapshotBefore", "_secondarySnapshotBefore"];

if !(isNil "_snapshot") exitWith {
    TRACE_2("onItemTaken: inventory open, diffing all containers",_item,_srcObj);

    private _after = [_unit, _primaryContainerObj, _secondaryContainerObj] call FUNC(Inventory_snapshotAllContainers);
    _after params ["_snapshotAfter", "_primarySnapshotAfter", "_secondarySnapshotAfter"];

    [_snapshot, _snapshotAfter, _primarySnapshotBefore, _primarySnapshotAfter, _secondarySnapshotBefore, _secondarySnapshotAfter, _containerMap] call FUNC(Inventory_diffAndEmitEvents);
    [_unit, _snapshotAfter, _primarySnapshotAfter, _secondarySnapshotAfter] call FUNC(Inventory_updateSession);
};

// Inventory is closed — resolve destination on unit and emit directly.
// Guard against duplicate EH registration firing this twice for the same pickup:
// use a per-frame debounce key [item + srcNetId]. The first call records it and
// schedules removal next frame; the second call (same frame) finds it and skips.
private _dedupeKey = _item + _srcNetId;
private _dedupeSet = _unit getVariable [QGVAR(closedPickupDebounce), []];
if (_dedupeKey in _dedupeSet) exitWith {
    TRACE_2("onItemTaken: closed pickup duplicate, skipping",_item,_srcObj);
};
_dedupeSet pushBack _dedupeKey;
_unit setVariable [QGVAR(closedPickupDebounce), _dedupeSet];
[{
    params ["_unit", "_key"];
    private _set = _unit getVariable [QGVAR(closedPickupDebounce), []];
    private _idx = _set find _key;
    if (_idx >= 0) then { _set deleteAt _idx; _unit setVariable [QGVAR(closedPickupDebounce), _set]; };
}, [_unit, _dedupeKey], 0] call CBA_fnc_waitAndExecute;

private _destSlot = "";
private _destObj  = objNull;
{
    private _slotName = _x;
    if (_item in ([_unit, _slotName] call FUNC(getItemsInSlot))) exitWith {
        _destSlot = _slotName;
        _destObj  = [_unit, _slotName] call FUNC(getStateObject);
    };
} forEach SLOTS_ALL;

if (_destSlot isEqualTo "" || {isNull _destObj}) exitWith {
    TRACE_2("onItemTaken: could not resolve dest slot",_unit,_item);
};

// Transfer locality of destination container if needed
if !(local _destObj) then {
    _destObj setOwner (owner _unit);
};

TRACE_4("onItemTaken: emitting inventoryChanged",_item,_srcObj,_destObj,_destSlot);
[QGVAR(inventoryChanged), [_srcObj, _destObj, _item, _srcSlot, _destSlot]] call CBA_fnc_localEvent;

TRACE_1("onItemTaken DONE",_unit);
