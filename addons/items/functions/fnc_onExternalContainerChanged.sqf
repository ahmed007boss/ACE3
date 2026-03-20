#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * CBA global event handler: when another machine adds/removes an item to/from an
 * external container, patch our local snapshots so they stay in sync.
 * Prevents stale snapshot issues when two players have the same box open.
 *
 * Arguments (event payload):
 * 0: Container netId <STRING>
 * 1: Item classname <STRING>
 * 2: Operation <STRING> ("add" or "remove")
 *
 * Return Value:
 * None <NIL>
 *
 * Public: No
 */

params [
    ["_containerNetId", "", [""]],
    ["_className", "", [""]],
    ["_operation", "", [""]]
];

if (_containerNetId isEqualTo "" || {_className isEqualTo ""} || {_operation isEqualTo ""}) exitWith {};
if (_operation != "add" && {_operation != "remove"}) exitWith {};

// Find all units on this machine that have an active inventory snapshot
private _unitsWithSnapshot = [];
{
    private _snap = _x getVariable [QGVAR(inventorySnapshot), nil];
    if (!isNil "_snap") then {
        _unitsWithSnapshot pushBack _x;
    };
} forEach allPlayers;

// Patch each snapshot that contains this container
{
    private _unit = _x;
    private _snapshot = _unit getVariable [QGVAR(inventorySnapshot), nil];
    if (isNil "_snapshot") then {
        // Skip this unit
    } else {
        private _slotAndItems = [_snapshot, _containerNetId] call CBA_fnc_hashGet;
        if (!isNil "_slotAndItems") then {
            _slotAndItems params ["_slotName", "_items"];
            private _changed = false;

            if (_operation isEqualTo "add") then {
                if (!(_className in _items)) then {
                    _items pushBack _className;
                    _changed = true;
                };
            } else {
                private _idx = _items find _className;
                if (_idx >= 0) then {
                    _items deleteAt _idx;
                    _changed = true;
                };
            };

            if (_changed) then {
                [_snapshot, _containerNetId, [_slotName, _items]] call CBA_fnc_hashSet;
                _unit setVariable [QGVAR(inventorySnapshot), _snapshot];
            };
        };
    };
} forEach _unitsWithSnapshot;
