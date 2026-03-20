#include "..\script_component.hpp"
/*
 * Author: ACE Team
 * Recursively compiles ACE_ItemInteractions config into native ACE action entries.
 * Used by interactions_compileItemsActionsMenu to build the item self-action subtree.
 * Slot and index are passed into every action's customParams so statements/conditions
 * can identify which inventory instance is being acted upon.
 *
 * Arguments:
 * 0: Actions config <CONFIG> (e.g. ACE_ItemInteractions or a child class)
 * 1: Target object <OBJECT> (used for canInteractWith in conditions)
 * 2: Slot (e.g. "vest", "uniform") <STRING> (default "")
 * 3: Occurrence index within slot (0-based) <NUMBER> (default -1)
 *
 * Return Value:
 * Array of compiled entries [[actionData], children] in native ACE format <ARRAY>
 * Each action's customParams (index 6) is [_slot, _index].
 *
 * Example:
 * [configFile >> "CfgWeapons" >> "ACE_microDAGR" >> "ACE_ItemInteractions", player, "vest",  "ACE_microDAGR", 0] call ace_items_fnc_interactions_compileItemActionsFromConfig;
 *
 * Public: No
 */

params [
    ["_actionsCfg", configNull, [configNull]],
    ["_target", objNull, [objNull]],
    ["_slot", "", [""]],
    ["_index", -1, [0]],
    ["_itemClassName", "", [""]],
    ["_type", 0, [0]]//0 = self, 1 = external
];

BEGIN_COUNTER(compileItemActionsFromConfig);

// Custom params passed to every action: [slot, index] for use in statement/condition
private _customParams = [_slot, _index, _itemClassName,_type];

private _actions = [];

{
    private _entryCfg = _x;
    if (isClass _entryCfg) then {
        private _displayName = getText (_entryCfg >> "displayName");
        // Support both naming conventions: showOnSelf/showOnTarget (microdagr) and EnableOnSelf/EnableOnOthers
        private _isSelf = 1;
        if (isNumber (_entryCfg >> "showOnSelf")) then { _isSelf = getNumber (_entryCfg >> "showOnSelf") } else { if (isNumber (_entryCfg >> "EnableOnSelf")) then { _isSelf = getNumber (_entryCfg >> "EnableOnSelf") } };
        private _isExternal = 0;
        if (isNumber (_entryCfg >> "showOnTarget")) then { _isExternal = getNumber (_entryCfg >> "showOnTarget") } else { if (isNumber (_entryCfg >> "EnableOnOthers")) then { _isExternal = getNumber (_entryCfg >> "EnableOnOthers") } };
        if (_type == 0 && {_isSelf == 0}) exitWith {};
        if (_type == 1 && {_isExternal == 0}) exitWith {};
        private _icon = if (isArray (_entryCfg >> "icon")) then {
            getArray (_entryCfg >> "icon")
        } else {
            [getText (_entryCfg >> "icon"), "#FFFFFF"]
        };
        private _statement = compile (getText (_entryCfg >> "statement"));

        private _condition = getText (_entryCfg >> "condition");

        // Add canInteract (including exceptions) and canInteractWith to condition
        private _canInteractCondition = format [QUOTE([ARR_3(ACE_player,_target,%1)] call EFUNC(common,canInteractWith)), getArray (_entryCfg >> "exceptions")];
        private _conditionFormatPattern = ["%1 && {%2}", "%2"] select (_condition isEqualTo "" || {_condition == "true"});
        _condition = compile format [_conditionFormatPattern, _condition, _canInteractCondition];

        private _insertChildren = compile (getText (_entryCfg >> "insertChildren"));
        private _modifierFunction = compile (getText (_entryCfg >> "modifierFunction"));

        private _showDisabled = (getNumber (_entryCfg >> "showDisabled")) > 0;
        private _enableInside = (getNumber (_entryCfg >> "enableInside")) > 0;
        private _canCollapse = (getNumber (_entryCfg >> "canCollapse")) > 0;



        private _runOnHover = true;
        if (isText (_entryCfg >> "runOnHover")) then {
            _runOnHover = compile getText (_entryCfg >> "runOnHover");
        } else {
            _runOnHover = (getNumber (_entryCfg >> "runOnHover")) > 0;
        };

        private _children = [_entryCfg, _target, _slot, _index,_itemClassName, _type] call FUNC(interactions_compileItemActionsFromConfig);

        private _entry = [
            [
                configName _entryCfg,
                _displayName,
                _icon,
                _statement,
                _condition,
                _insertChildren,
                _customParams,
                [0, 0, 0],
                10,
                [_showDisabled, _enableInside, _canCollapse, _runOnHover, true],
                _modifierFunction
            ],
            _children
        ];
        _actions pushBack _entry;
    };
} forEach (configProperties [_actionsCfg, "isClass _x", true]);

END_COUNTER(compileItemActionsFromConfig);
_actions
