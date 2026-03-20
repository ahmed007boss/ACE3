#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Broadcasts all item state variables from a killed unit globally so other
 * machines can read them when looting the corpse.
 *
 * Item states are normally stored as local-only setVariable entries on the
 * state object (unit for assigned/weapon slots, vestContainer/uniformContainer/
 * backpackContainer for cargo slots). After death, another player on a different
 * machine cannot see those local variables unless they are globally broadcast.
 *
 * This function iterates every personal slot, finds all state variables for the
 * items present, and re-broadcasts them with the global flag so the corpse is
 * fully readable by all clients.
 *
 * Arguments:
 * 0: Killed unit <OBJECT>
 * 1: Killer <OBJECT>
 *
 * Return Value:
 * None <NIL>
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_killer", objNull, [objNull]]
];

TRACE_2("migrateItemStateToCorpse",_unit,_killer);

if (isNull _unit) exitWith {
    WARNING_1("migrateItemStateToCorpse EXIT null unit: unit=%1",_unit);
};
if !(local _unit) exitWith {
    WARNING_1("migrateItemStateToCorpse EXIT unit not local: unit=%1",_unit);
};

// Re-broadcast all state variables for a single slot globally.
// State for assigned/weapon slots lives on the unit object itself.
// State for vest/uniform/backpack cargo lives on the respective container object.
private _fnc_broadcastSlot = {
    params ["_unit", "_slot"];
    private _stateObj = [_unit, _slot] call FUNC(getStateObject);
    if (isNull _stateObj) exitWith {};
    private _items = [_unit, _slot] call FUNC(getItemsInSlot);
    {
        private _varKey = [_slot, _x] call FUNC(getItemStateVarKey);
        private _stateArray = _stateObj getVariable [_varKey, nil];
        if !(isNil "_stateArray") then {
            TRACE_3("migrateItemStateToCorpse broadcast",_slot,_x,_stateArray);
            _stateObj setVariable [_varKey, _stateArray, true];
        };
    } forEach (_items arrayIntersect _items);
};

{
    [_unit, _x] call _fnc_broadcastSlot;
} forEach [
    SLOT_ASSIGNED,
    SLOT_EQUIPPED,
    SLOT_WEAPONS,
    SLOT_PRIMARY_WEAPON_ITEMS,
    SLOT_SECONDARY_WEAPON_ITEMS,
    SLOT_HANDGUN_WEAPON_ITEMS,
    SLOT_BINOCULAR_ITEMS,
    SLOT_VEST_CONTAINER,
    SLOT_UNIFORM_CONTAINER,
    SLOT_BACKPACK_CONTAINER
];

TRACE_1("migrateItemStateToCorpse: complete",_unit);
