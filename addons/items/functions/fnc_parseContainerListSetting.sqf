#include "..\script_component.hpp"
/*
 * Author: Ahmed Salah
 * Parses the container whitelist/blacklist setting string. Returns an array of trimmed classnames.
 * Empty string or "[]" returns [].
 * Accepted formats:
 *   - Array literal: ["xxx","yyyy"], [xxx,yyyy], ['xxx','yyyy']
 *   - Comma-separated: "V_PlateCarrier1_rgr, B_AssaultPack_khk"
 *
 * Arguments:
 * 0: Setting value string <STRING>
 *
 * Return Value:
 * Array of classname strings <ARRAY>
 *
 * Example:
 * ["[]"] call ace_items_fnc_parseContainerListSetting;  // []
 * ["[\"V_PlateCarrier1_rgr\",\"B_AssaultPack_khk\"]"] call ace_items_fnc_parseContainerListSetting;  // array literal
 * ["V_PlateCarrier1_rgr, B_AssaultPack_khk"] call ace_items_fnc_parseContainerListSetting;  // comma-separated
 *
 * Public: Yes
 */

params [["_str", "", [""]]];

private _trimmed = trim _str;
if (_trimmed isEqualTo "" || {_trimmed isEqualTo "[]"}) exitWith { [] };

private _result = [];

// Array literal: ["x","y"], [x,y], ['x','y']
if ((_trimmed select [0, 1]) isEqualTo "[" && {(_trimmed select [count _trimmed - 1, 1]) isEqualTo "]"}) then {
    private _parsed = parseSimpleArray _trimmed;
    if (_parsed isEqualType []) then {
        {
            private _s = if (_x isEqualType "") then { _x } else { str _x };
            _s = trim _s;
            if (_s isNotEqualTo "") then { _result pushBack _s };
        } forEach _parsed;
    };
};

// Fallback: comma-separated
if (_result isEqualTo []) then {
    private _arr = _trimmed splitString ",";
    {
        private _s = trim _x;
        if (_s isNotEqualTo "") then { _result pushBack _s };
    } forEach _arr;
};

_result
