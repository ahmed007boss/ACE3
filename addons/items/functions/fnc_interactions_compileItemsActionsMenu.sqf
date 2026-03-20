#include "..\script_component.hpp"
/*
 * Author: NouberNou and esteldunedain
 * Builds self-action menu entries for every CfgWeapons class that has ACE_ItemInteractions,
 * and registers them under ACE_SelfActions > ACE_Equipment. When opened, insertChildren
 * either returns the compiled interactions for a single instance or one submenu per
 * inventory instance (e.g. "MicroDAGR (Vest)", "MicroDAGR (Uniform)").
 *
 * Arguments:
 * 0: Target (unit type or class name) <OBJECT | STRING> - e.g. "CAManBase" or a vehicle class
 *
 * Return Value:
 * None
 *
 * Example:
 * ["CAManBase"] call ace_items_fnc_interactions_compileItemsActionsMenu;
 *
 * Public: No
 */

params [["_target", objNull, [objNull, ""]]];

BEGIN_COUNTER(compileItemsActionsMenu);

// ---------------------------------------------------------------------------
// Collect all CfgWeapons classes that have ACE_ItemInteractions (recursive)
// ---------------------------------------------------------------------------
BEGIN_COUNTER(collectItemClasses);
private _itemClasses = [];
private _fnc_collectItemClasses = {
    params ["_weaponConfig"];
    if (!isClass _weaponConfig) exitWith {};
    if (isClass (_weaponConfig >> "ACE_ItemInteractions")) then {
        _itemClasses pushBack configName _weaponConfig;
    };
    {
        [_x] call _fnc_collectItemClasses;
    } forEach ("true" configClasses _weaponConfig);
};
[configFile >> "CfgWeapons"] call _fnc_collectItemClasses;
END_COUNTER(collectItemClasses);


// ---------------------------------------------------------------------------
// For each item class: create root action and add under ACE_SelfActions > ACE_Equipment
// ---------------------------------------------------------------------------
{
    private _itemClassName = _x;

    // Skip if this (_target, _itemClassName) pair has already been registered.
    private _key = _target + _itemClassName;
    if (_key in GVAR(itemActionsAddedClasses)) exitWith {};
    GVAR(itemActionsAddedClasses) pushBack _key;

    private _actionsCfg = configFile >> "CfgWeapons" >> _itemClassName >> "ACE_ItemInteractions";
    if (isClass _actionsCfg) then {
     
        // Prefer per-interaction overrides on ACE_ItemInteractions config if present,
        // then fall back to the weapon's own displayName/picture, and finally to
        // classname / default icon.
        // Root Action Data
        private _rootDisplayName = getText (_actionsCfg >> "displayName");
        if (_rootDisplayName isEqualTo "") then {
            _rootDisplayName = getText (configFile >> "CfgWeapons" >> _itemClassName >> "displayName");
        };
        if (_rootDisplayName isEqualTo "") then { _rootDisplayName = _itemClassName; };

        private _rootIcon = getText (_actionsCfg >> "icon");
        if (_rootIcon isEqualTo "") then {
            _rootIcon = getText (configFile >> "CfgWeapons" >> _itemClassName >> "picture");
        };
        if (_rootIcon isEqualTo "") then { _rootIcon = "\a3\ui_f\data\IGUI\Cfg\Actions\eject_ca.paa"; };
        private _rootConditionText = getText (_actionsCfg >> "condition");
        private _rootCondition = if (_rootConditionText isEqualTo "") then {
            {true};
        } else {
             compile _rootConditionText;
        };

        private _insertChildren = {
            params ["_target", "_player", "_params"];

            BEGIN_COUNTER(insertChildren);

            _params params ["_actionsCfg", "_itemClassName", "_itemDisplayName", "_itemIcon", "_itemCondition", "_type"];
            private _unit = [_target, _player] select (_type == 0);

            private _instances = [];
            {
                private _slot = _x;
                private _slotItems = [_unit, _slot] call FUNC(getItemsInSlot);
                private _occurrenceIndex = 0;
                {
                    if (_x isEqualTo _itemClassName) then {
                        _instances pushBack [_slot, _occurrenceIndex];
                        _occurrenceIndex = _occurrenceIndex + 1;
                    };
                    
                } forEach _slotItems;
            } forEach SLOTS_ALL;

            if (_instances isEqualTo []) exitWith { END_COUNTER(insertChildren); [] };

            if (count _instances == 1) exitWith {
                (_instances select 0) params ["_slot", "_occurrenceIndex"];
                private _compiled = [_actionsCfg, _unit, _slot, _occurrenceIndex, _itemClassName, _type] call FUNC(interactions_compileItemActionsFromConfig);
                private _result = _compiled apply { [_x select 0, _x select 1, _unit] };
                END_COUNTER(insertChildren);
                _result
            };

            private _actions = [];
            {
                _x params ["_slot", "_occurrenceIndex"];
                private _slotLabel =  GVAR(slotLabels) getOrDefault [_slot, _slot];
                private _countInSlot = { (_x select 0) isEqualTo _slot } count _instances;
                private _displayName = if (_countInSlot <= 1) then {
                    format ["%1 (%2)", _itemDisplayName, _slotLabel]
                } else {
                    format ["%1 (%2) #%3", _itemDisplayName, _slotLabel, _occurrenceIndex + 1]
                };
                private _actionKey = format ["%1_%2_%3", _itemClassName, _slot, _occurrenceIndex];
                private _childInsertChildren = {
                    params ["_target", "_player", "_params"];
                    _params params ["_actionsCfg", "_slot", "_index","_itemClassName"];
                    private _compiled = [_actionsCfg, _target, _slot, _index, _itemClassName, 0] call FUNC(interactions_compileItemActionsFromConfig);
                    _compiled apply { [_x select 0, _x select 1, _target] }
                };
                if (_type == 1) then {
                    _childInsertChildren = {
                        params ["_target", "_player", "_params"];
                        _params params ["_actionsCfg", "_slot", "_index", "_itemClassName"];
                        private _compiled = [_actionsCfg, _target, _slot, _index, _itemClassName, 1] call FUNC(interactions_compileItemActionsFromConfig);
                        _compiled apply { [_x select 0, _x select 1, _target] }
                    };
                };


                private _subActionData = [
                    _actionKey,
                    _displayName,
                    _itemIcon,
                    {},
                    _itemCondition,
                    _childInsertChildren,
                    [_actionsCfg, _slot, _occurrenceIndex, _itemClassName],
                    [0, 0, 0],
                    10,
                    [false, true, false, false, false],
                    {}
                ] call ace_interact_menu_fnc_createAction;

                _actions pushBack [_subActionData, [], _unit];
            } forEach _instances;

            END_COUNTER(insertChildren);
            _actions
        };

        // Item Action Data
        private _itemDisplayName = getText (_actionsCfg >> "itemDisplayName");
        if (_itemDisplayName isEqualTo "") then {
            _itemDisplayName = getText (configFile >> "CfgWeapons" >> _itemClassName >> "displayName");
        };
        if (_itemDisplayName isEqualTo "") then { _itemDisplayName = _itemClassName; };

        private _itemIcon = getText (_actionsCfg >> "itemIcon");
        if (_itemIcon isEqualTo "") then {
            _itemIcon = getText (configFile >> "CfgWeapons" >> _itemClassName >> "picture");
        };
        if (_itemIcon isEqualTo "") then { _itemIcon = _rootIcon; };

        private _itemConditionText = getText (_actionsCfg >> "itemCondition");
       private _itemCondition =  if (_itemConditionText isEqualTo "") then {
            {true};
        } else {
             compile _itemConditionText;
        };


        // Self Action
        private _actionParamsSelf = [_actionsCfg, _itemClassName, _itemDisplayName, _itemIcon,_itemCondition, 0];
        private _actionParamsExternal = [_actionsCfg, _itemClassName, _itemDisplayName, _itemIcon,_itemCondition, 1];

        private _actionSelf = [
            _itemClassName,
            _rootDisplayName,
            _rootIcon,
            {},
            _rootCondition,
            _insertChildren,
            _actionParamsSelf,
            [0, 0, 0],
            10,
            [false, true, false, false, false],
            {}
        ] call ace_interact_menu_fnc_createAction;

        private _actionExternal = [
            _itemClassName,
            _rootDisplayName,
            _rootIcon,
            {},
            _rootCondition,
            _insertChildren,
            _actionParamsExternal,
            [0, 0, 0],
            10,
            [false, true, false, false, false],
            {}
        ] call ace_interact_menu_fnc_createAction;

        [_target, 1, ["ACE_SelfActions", "ACE_Equipment"], _actionSelf, true] call ace_interact_menu_fnc_addActionToClass;
        [_target, 0, ["ACE_MainActions"], _actionExternal, true] call ace_interact_menu_fnc_addActionToClass;
    };
} forEach _itemClasses;

END_COUNTER(compileItemsActionsMenu);
