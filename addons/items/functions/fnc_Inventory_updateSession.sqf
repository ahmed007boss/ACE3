#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Writes updated snapshots back into the unit's session variables so the
 * next EH fire (or inventory close) diffs from the current state.
 * Does NOT touch the container map or container object references.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Unit snapshot <ARRAY> (CBA HashMap)
 * 2: Primary snapshot <ARRAY> (CBA HashMap)
 * 3: Secondary snapshot <ARRAY> (CBA HashMap)
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * [_unit, _unitSnap, _primarySnap, _secondarySnap] call ace_items_fnc_Inventory_updateSession;
 *
 * Public: No
 */

params [
    ["_unit",          objNull, [objNull]],
    ["_unitSnap",      [], [[]]],
    ["_primarySnap",   [], [[]]],
    ["_secondarySnap", [], [[]]]
];

_unit setVariable [QGVAR(inventorySnapshot),          _unitSnap];
_unit setVariable [QGVAR(inventoryPrimarySnapshot),   _primarySnap];
_unit setVariable [QGVAR(inventorySecondarySnapshot), _secondarySnap];
