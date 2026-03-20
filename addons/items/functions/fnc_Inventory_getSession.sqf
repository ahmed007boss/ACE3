#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Reads the current inventory session state from a unit's variables.
 * Used by inventory event handlers to retrieve before-snapshots, container
 * objects, and the container map without repeating getVariable calls.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 *
 * Return Value:
 * [unitSnapshot, containerMap, primaryContainerObj, secondaryContainerObj, primarySnapshot, secondarySnapshot]
 * unitSnapshot / containerMap are nil when no active session.
 *
 * Example:
 * private _session = [_unit] call ace_items_fnc_Inventory_getSession;
 * _session params ["_snap", "_map", "_primary", "_secondary", "_primarySnap", "_secondarySnap"];
 *
 * Public: No
 */

params [["_unit", objNull, [objNull]]];

[
    _unit getVariable [QGVAR(inventorySnapshot),            nil],
    _unit getVariable [QGVAR(inventoryContainerMap),        nil],
    _unit getVariable [QGVAR(inventoryPrimaryContainerObj), objNull],
    _unit getVariable [QGVAR(inventorySecondaryContainerObj), objNull],
    _unit getVariable [QGVAR(inventoryPrimarySnapshot),     [] call CBA_fnc_hashCreate],
    _unit getVariable [QGVAR(inventorySecondarySnapshot),   [] call CBA_fnc_hashCreate]
]
