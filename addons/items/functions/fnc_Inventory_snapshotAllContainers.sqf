#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Takes a fresh snapshot of a unit and both optional external containers.
 * Skips secondary if it is the same object as primary (only one container open).
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Primary container object <OBJECT> (objNull if none)
 * 2: Secondary container object <OBJECT> (objNull if none)
 *
 * Return Value:
 * [unitSnapshot, primarySnapshot, secondarySnapshot] <ARRAY>
 * External snapshots are empty CBA hashes when the container is null/same.
 *
 * Example:
 * private _snaps = [_unit, _primaryObj, _secondaryObj] call ace_items_fnc_Inventory_snapshotAllContainers;
 * _snaps params ["_unitSnap", "_primarySnap", "_secondarySnap"];
 *
 * Public: No
 */

params [
    ["_unit",            objNull, [objNull]],
    ["_primaryObj",      objNull, [objNull]],
    ["_secondaryObj",    objNull, [objNull]]
];

private _unitSnap = [_unit] call FUNC(Inventory_snapshotContainer);

private _primarySnap = if (!isNull _primaryObj) then {
    [_primaryObj] call FUNC(Inventory_snapshotContainer)
} else {
    [] call CBA_fnc_hashCreate
};

private _secondarySnap = if (!isNull _secondaryObj && {_secondaryObj isNotEqualTo _primaryObj}) then {
    [_secondaryObj] call FUNC(Inventory_snapshotContainer)
} else {
    [] call CBA_fnc_hashCreate
};

[_unitSnap, _primarySnap, _secondarySnap]
