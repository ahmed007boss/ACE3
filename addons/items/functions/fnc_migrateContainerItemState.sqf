#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Handles state migration when a wearable container (vest, uniform, backpack) is
 * removed from a unit and becomes a standalone object.
 *
 * Two things must happen:
 * 1. The container's OWN state (stored on unit) is migrated to the dropped container object.
 * 2. The contents' states are already stored on the container object — they travel naturally.
 *
 * Also handles the reverse: when a container is picked up and worn by a unit,
 * the container's own state moves from the container object back onto the unit.
 *
 * Arguments:
 * 0: Unit <OBJECT>
 * 1: Container object <OBJECT> (the dropped vest/uniform/backpack object)
 * 2: Container slot <STRING> ("vest", "uniform", "backpack")
 * 3: Direction <STRING> ("drop" when removing from unit, "wear" when putting on unit)
 *
 * Return Value:
 * None <NIL>
 *
 * Example:
 * [player, droppedVestObj, "vest", "drop"] call ace_items_fnc_migrateContainerItemState;
 *
 * Public: No
 */

params [
    ["_unit", objNull, [objNull]],
    ["_containerObj", objNull, [objNull]],
    ["_slot", "", [""]],
    ["_direction", "drop", [""]]
];

TRACE_4("migrateContainerItemState",_unit,_containerObj,_slot,_direction);

if (isNull _unit || {isNull _containerObj} || {_slot isEqualTo ""}) exitWith {
    WARNING_3("migrateContainerItemState EXIT bad params: unit=%1 container=%2 slot=%3",_unit,_containerObj,_slot);
};

// Key for the container's own state (stored on unit while worn)
private _containerStateKey = format [QGVAR(ACE_worn_%1_state), _slot];

switch (_direction) do {
    case "drop": {
        // Container removed from unit — move its own state from unit to container object
        if !(local _unit) exitWith {
            WARNING_1("migrateContainerItemState DROP EXIT unit not local: unit=%1",_unit);
        };

        private _containerClass = switch (_slot) do { case SLOT_VEST_CONTAINER: { vest _unit }; case SLOT_UNIFORM_CONTAINER: { uniform _unit }; case SLOT_BACKPACK_CONTAINER: { backpack _unit }; default { "" } };
        if (_containerClass isNotEqualTo "") then {
            _containerObj setVariable [QGVAR(equippedContainerClass), _containerClass];
            private _equippedKey = [SLOT_EQUIPPED, _containerClass] call FUNC(getItemStateVarKey);
            private _equippedState = _unit getVariable [_equippedKey, []];
            if (_equippedState isNotEqualTo []) then {
                if (local _containerObj) then {
                    _containerObj setVariable [_equippedKey, _equippedState];
                } else {
                    [QGVAR(pushContainerOwnState), [_containerObj, _equippedKey, _equippedState], _containerObj] call CBA_fnc_targetEvent;
                };
                _unit setVariable [_equippedKey, nil];
            };
        };

        private _ownState = _unit getVariable [_containerStateKey, nil];
        if !(isNil "_ownState") then {
            if (local _containerObj) then {
                _containerObj setVariable [_containerStateKey, _ownState];
            } else {
                [QGVAR(pushContainerOwnState), [_containerObj, _containerStateKey, _ownState], _containerObj] call CBA_fnc_targetEvent;
            };
            _unit setVariable [_containerStateKey, nil];
            TRACE_2("migrateContainerItemState: drop - own state moved to object",_slot,_containerObj);
        };

        // Contents' states are already on _containerObj — nothing to do
    };

    case "wear": {
        // Container picked up and worn — move its own state from container object to unit
        if !(local _containerObj) exitWith {
            [QGVAR(migrateContainerItemState_remote), [_unit, _containerObj, _slot, "wear"], _containerObj] call CBA_fnc_targetEvent;
        };

        private _ownState = _containerObj getVariable [_containerStateKey, nil];
        if !(isNil "_ownState") then {
            if (local _unit) then {
                _unit setVariable [_containerStateKey, _ownState];
            } else {
                [QGVAR(pushContainerOwnState), [_unit, _containerStateKey, _ownState], _unit] call CBA_fnc_targetEvent;
            };
            _containerObj setVariable [_containerStateKey, nil];
            TRACE_2("migrateContainerItemState: wear - own state moved to unit",_slot,_unit);
        };

        // Migrate "equipped" slot state (vest/uniform/backpack as items) from container back to unit
        private _containerClass = _containerObj getVariable [QGVAR(equippedContainerClass), ""];
        if (_containerClass isNotEqualTo "") then {
            private _equippedKey = [SLOT_EQUIPPED, _containerClass] call FUNC(getItemStateVarKey);
            private _equippedState = _containerObj getVariable [_equippedKey, []];
            if (_equippedState isNotEqualTo []) then {
                if (local _unit) then {
                    _unit setVariable [_equippedKey, _equippedState];
                } else {
                    [QGVAR(pushContainerOwnState), [_unit, _equippedKey, _equippedState], _unit] call CBA_fnc_targetEvent;
                };
                _containerObj setVariable [_equippedKey, nil];
            };
            _containerObj setVariable [QGVAR(equippedContainerClass), nil];
        };

        // Contents' states are already on _containerObj which is now worn — nothing to do
    };
};
TRACE_1("migrateContainerItemState DONE",_unit);
