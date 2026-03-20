#include "script_component.hpp"

if (!hasInterface) exitWith {};

// ---------------------------------------------------------------------------
// Slot labels for per-instance submenus (shared)
// ---------------------------------------------------------------------------
 GVAR(slotLabels) = createHashMapFromArray [
    [SLOT_VEST_CONTAINER, "Vest"],
    [SLOT_UNIFORM_CONTAINER, "Uniform"],
    [SLOT_BACKPACK_CONTAINER, QUOTE(Backpack)],
    [SLOT_ASSIGNED, QUOTE(Equipped)],
    [SLOT_EQUIPPED, QUOTE(Equipped)],
    [SLOT_WEAPONS, QUOTE(Equipped)],
    [SLOT_OBJECT, QUOTE(Object)]
];

// Tracks which (_target + _itemClassName) pairs have already been registered.
// Each entry is the combined string: target type + item classname.
GVAR(itemActionsAddedClasses) = [];


// Wait until player controls (man,vehicle or uav) a thing before compiling the menu
GVAR(controllableSelfActionsAdded) = createHashMap;
DFUNC(newControllableObject) = {
    params ["_object"];
    private _type = typeOf _object;
    TRACE_2("newControllableObject",_object,_type);
    if (_type == "") exitWith {};

    if !(_type in GVAR(controllableSelfActionsAdded)) then {
        [_type] call FUNC(interactions_compileItemsActionsMenu);
        GVAR(controllableSelfActionsAdded) set [_type, nil];
        [{
            TRACE_1("sending newControllableObject event",_this);
            // event for other systems to add self actions, running addActionToClass before this will cause compiling
            [QGVAR(newControllableObject), _this] call CBA_fnc_localEvent;
        }, [_type]] call CBA_fnc_execNextFrame; // delay event a frame to ensure postInit has run for all addons
    };
};
["unit", {[_this select 0] call FUNC(newControllableObject)}, true] call CBA_fnc_addPlayerEventHandler;
["vehicle", {[_this select 1] call FUNC(newControllableObject)}, true] call CBA_fnc_addPlayerEventHandler;
["ACE_controlledUAV", {[_this select 0] call FUNC(newControllableObject)}] call CBA_fnc_addEventHandler;

// When an attachment is switched (mode change via ace_common_fnc_switchAttachmentMode),
// migrate the old attachment's item state to the new attachment classname so state
// (e.g. device settings) is preserved across the switch.
// Event args: [unit, fromAttachment, toAttachment, weaponType(0=primary,1=handgun,2=secondary)]
["CBA_attachmentSwitched", {
    params ["_unit", "_fromAttachment", "_toAttachment", "_weaponType"];
    private _sound = getText (configFile >> "CfgWeapons" >> _toAttachment >> "ace_clickSound");
    if (_sound != "") then { playSound _sound; };
    
    private _slot = [SLOT_PRIMARY_WEAPON_ITEMS, SLOT_HANDGUN_WEAPON_ITEMS, SLOT_SECONDARY_WEAPON_ITEMS,SLOT_BINOCULAR_ITEMS] param [_weaponType, ""];
    if (_slot isEqualTo "") exitWith {
        WARNING_2("CBA_attachmentSwitched: unknown weaponType=%1 from=%2",_weaponType,_fromAttachment);
    };

    // Read state directly — bypassing syncItemStateToSlotCount, which would purge the state
    // because _fromAttachment is already removed from the slot when this event fires.
    private _stateObj = [_unit, _slot] call FUNC(getStateObject);
    if (isNull _stateObj || {!(local _stateObj)}) exitWith {};

    private _fromVarKey = [_slot, _fromAttachment] call FUNC(getItemStateVarKey);
    private _fromStates = _stateObj getVariable [_fromVarKey, []];
    if (_fromStates isEqualTo []) exitWith {};

    // Overwrite _toAttachment's freshly-initialized state with the migrated state, then clear the old key
    private _toVarKey = [_slot, _toAttachment] call FUNC(getItemStateVarKey);
    _stateObj setVariable [_toVarKey, _fromStates];
    _stateObj setVariable [_fromVarKey, nil];

    TRACE_4("CBA_attachmentSwitched: migrated state",_fromAttachment,_toAttachment,_slot,_fromStates);
}] call CBA_fnc_addEventHandler;

// Inventory open/close tracking — must run on every unit (not just player) so that
// item state is kept in sync whenever any local unit's inventory is accessed.
["CAManBase", "InventoryOpened", { _this call FUNC(Inventory_onOpened) }] call CBA_fnc_addClassEventHandler;
["CAManBase", "InventoryClosed", { _this call FUNC(Inventory_onClosed) }] call CBA_fnc_addClassEventHandler;

// Local event: inventory diff detected a movement between containers — client-only (inventory opens only on clients)
[QGVAR(inventoryChanged), {
    params ["_srcObj", "_destObj", "_className", "_srcSlot", "_destSlot"];
    [_srcObj, _destObj, _className, _srcSlot, _destSlot] call FUNC(migrateItemState);
}] call CBA_fnc_addEventHandler;

// Global event: external container contents changed (add/remove item) — patch local snapshots to avoid stale state.
// Fired globally but only meaningful on clients (no inventory sessions on server/headless).
[QGVAR(externalContainerChanged), {
    _this call FUNC(onExternalContainerChanged);
}] call CBA_fnc_addEventHandler;
