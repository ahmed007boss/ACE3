private _category = format ["ACE %1", LLSTRING(DisplayName)];
private _categoryUsableRestrictions = [_category, LLSTRING(Subcategory_UsableItemRestrictions)];
private _categoryDestroyable = [_category, LLSTRING(Subcategory_DestroyableItems)];

[
    QGVAR(enableUsableItemRestrictions),
    "CHECKBOX",
    [LSTRING(EnableUsableItemRestrictions_DisplayName), LSTRING(EnableUsableItemRestrictions_Description)],
    _categoryUsableRestrictions,
    false,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(blockBackpackUsage),
    "CHECKBOX",
    [LSTRING(BlockBackpackUsage_DisplayName), LSTRING(BlockBackpackUsage_Description)],
    _categoryUsableRestrictions,
    false,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(enableDestroyableItems),
    "CHECKBOX",
    [LSTRING(EnableDestroyableItems_DisplayName), LSTRING(EnableDestroyableItems_Description)],
    _categoryDestroyable,
    false,
    1
] call CBA_fnc_addSetting;

[
    QGVAR(destroyChanceFactor),
    "SLIDER",
    [LSTRING(DestroyChanceFactor_DisplayName), LSTRING(DestroyChanceFactor_Description)],
    _categoryDestroyable,
    [0, 10, 1, 1],
    1
] call CBA_fnc_addSetting;
