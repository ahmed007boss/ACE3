---
layout: wiki
title: Items Framework
description: Explains how to set up the items framework for usable items restrictions, destroyable items, and item state management.
group: framework
order: 5
parent: wiki
mod: ace
version:
  major: 3
  minor: 3
  patch: 0
---

## 1. Overview

The Items Framework provides three independent systems that addons can opt into:

- **Usage restrictions** — per-operation-mode rules about which containers an item may be used from, with optional whitelist/blacklist and runtime conditions.
- **Destroyable items** — items that are replaced (or removed) by a damaged variant when hit, with configurable chance, sounds, effects and callbacks.
- **Item state** — per-item-instance persistent data (a HashMap) that travels with the item as it moves between containers and units across the network.

Both usage restrictions and destroyable items require their respective CBA mission settings to be enabled. State is always active.

---

## 2. Config

### 2.1 Usage restrictions

Add `ACE_UsableItemRestrictionsInfo` to any `CfgWeapons` item. The root class holds restrictions for the default operation mode (`defaultUse`); additional operation modes are nested classes inside it.

{% raw %}
```cpp
class CfgWeapons {
    class ACE_ItemCore;
    class CBA_MiscItem_ItemInfo;

    class MyItem: ACE_ItemCore {
        class ACE_UsableItemRestrictionsInfo {
            // 1 = disallowed from this slot/state, 0 = allowed
            disallowedWhenAssigned  = 0;  // linked items (NVG, watch…)
            disallowedWhenEquipped  = 0;  // worn vest/uniform/backpack as equipment slot
            disallowedInVest        = 1;  // items inside the vest container
            disallowedInUniform     = 0;
            disallowedInBackpack    = 1;
            disallowedUnderwater    = 0;
            disallowedInAir         = 0;
            disallowedInVehicles    = 0;
            // Optional SQF string, compiled at runtime.
            // Receives [unit, container, itemClass, operationMode]; must return BOOL.
            // Has no CBA setting override — evaluated in addition to the flags above.
            useCondition = "";

            // Additional operation mode with independent container rules
            class advancedUse {
                disallowedWhenAssigned  = 0;
                disallowedWhenEquipped  = 0;
                disallowedInVest        = 0;
                disallowedInUniform     = 0;
                disallowedInBackpack    = 0;
                disallowedUnderwater    = 0;
                disallowedInAir         = 0;
                disallowedInVehicles    = 0;
                useCondition = "";
            };
        };
    };
};
```
{% endraw %}

All flags default to `0` (allowed). The full decision is:

```
allowed = (slot not disallowed) AND (environment not disallowed) AND (useCondition passes) AND (whitelist/blacklist passes)
```

- `disallowedInAir` is true when the unit is on foot and not touching the ground, or riding a parachute.
- `disallowedInVehicles` is true whenever `objectParent _unit` is not null.
- Whitelist/blacklist are configured via per-item CBA settings (§3.2); they match against the container's classname.

**Check at runtime:**

```sqf
// Third argument is the operation mode name; "defaultUse" is the implicit root mode
[ACE_player, "vest", "MyItem", "defaultUse"] call ace_items_fnc_canUseItem;
```

### 2.2 Destroyable items

Add `ACE_DestroyableItemInfo` to the item class. All fields are optional, but at minimum one of `DestroyedItem`, `DestroyingSounds`, or `OnDestroyed` should be set.

{% raw %}
```cpp
class CfgWeapons {
    class ACE_ItemCore;
    class CBA_MiscItem_ItemInfo;

    class MyItem: ACE_ItemCore {
        class ACE_DestroyableItemInfo {
            // Classname to replace this item with on destruction.
            // If empty, the item is simply removed with no replacement.
            DestroyedItem = "MyItem_Destroyed";

            // One entry is chosen at random and played at the unit's position.
            DestroyingSounds[] = {"ACE_Destroy_Sound_1"};

            // Ammo classname spawned at the unit position on destruction (for explosion/visual effects).
            DestroyingAmmo = "";

            // Base destroy-on-hit probability (0–100).
            // Scaled at runtime by ace_items_destroyChanceFactor and the per-item
            // destroy-chance CBA setting (if a setting prefix is registered via
            // ace_items_fnc_setItemSettingPrefix — see §3.2).
            DestroyChance = 10;

            // SQF string, compiled once at first use.
            // Receives [unit, className, slot, stateIndex, itemState, damageInfo]
            //   damageInfo = [shooter, bodyPart, ammoType, isBackShot]
            // Return false to veto destruction for this instance.
            CanDestroy = "";

            // SQF string, compiled once at first use.
            // Called after successful destruction with the same arguments as CanDestroy.
            OnDestroyed = "";
        };
    };

    // The destroyed variant — minimal config
    class MyItem_Destroyed: ACE_ItemCore {
        scope = 1;
        displayName = "My Item (Destroyed)";
        class ItemInfo: CBA_MiscItem_ItemInfo {
            mass = 1;
        };
    };
};
```
{% endraw %}

Destruction is triggered automatically on body hits when `ace_items_enableDestroyableItems` is enabled.

---

### 2.3 Slot reference

The following slot identifier strings are used throughout the API and in `getItemsInSlot`, `getItemState`, `setItemState`, etc.

| Constant | String value | Contents |
|---|---|---|
| `SLOT_ASSIGNED` | `"assigned"` | Linked items — headgear, goggles, HMD, NVG, radio, watch, GPS |
| `SLOT_EQUIPPED` | `"equipped"` | Worn containers — vest, uniform, backpack (as equipment, not their cargo) |
| `SLOT_WEAPONS` | `"weapons"` | Weapons currently held (primary, secondary, handgun, binocular) |
| `SLOT_VEST_CONTAINER` | `"vestItems"` | Items inside the vest |
| `SLOT_UNIFORM_CONTAINER` | `"uniformItems"` | Items inside the uniform |
| `SLOT_BACKPACK_CONTAINER` | `"backpackItems"` | Items inside the backpack |
| `SLOT_BINOCULAR_ITEMS` | `"binocularItems"` | Attachments and magazines on the binocular |
| `SLOT_PRIMARY_WEAPON_ITEMS` | `"primaryWeaponItems"` | Attachments and magazines on the primary weapon |
| `SLOT_SECONDARY_WEAPON_ITEMS` | `"secondaryWeaponItems"` | Attachments and magazines on the launcher |
| `SLOT_HANDGUN_WEAPON_ITEMS` | `"handgunItems"` | Attachments and magazines on the handgun |
| `SLOT_OBJECT` | `"object"` | Generic containers — ammo boxes, vehicles, ground objects |

---

## 3. Settings

### 3.1 Module settings (mission-level)

| Setting | Type | Default | Description |
|---|---|---|---|
| `ace_items_enableUsableItemRestrictions` | CHECKBOX | `false` | Enable container/environment restrictions for usable items |
| `ace_items_blockBackpackUsage` | CHECKBOX | `false` | Globally block item use from backpack regardless of per-item config |
| `ace_items_enableDestroyableItems` | CHECKBOX | `false` | Enable item destruction on body hits |
| `ace_items_destroyChanceFactor` | SLIDER (0–10) | `1` | Global multiplier on every item's `DestroyChance`; 0 = never destroy |

### 3.2 Per-item settings

Use `ace_items_fnc_createItemSettings` to automatically generate all CBA settings for a usable or destroyable item. Call it from your addon's `postInit` or `initSettings.inc.sqf`:

```sqf
// 0: Item classname <STRING>
// 1: Setting prefix <STRING>  (used to build variable names, e.g. "myAddon_myItem")
// 2: Category path [parent, subcategory] <ARRAY>
// 3: Display name shown in settings UI <STRING>
["MyItem", "myAddon_myItem", ["myAddon", "My Item"], "My Item"] call ace_items_fnc_createItemSettings;
```

This creates per-operation-mode restriction checkboxes (disallowed when assigned, in vest, underwater, etc.), container whitelist/blacklist editboxes, and a destroy-chance slider — only for the restriction/destruction modes the item actually supports. It also registers the prefix mapping so `ace_items_fnc_canUseItem` and `ace_items_fnc_getDestroyableItemInfo` can read the settings at runtime.

If you only need to register the prefix mapping without auto-creating settings, use `ace_items_fnc_setItemSettingPrefix` directly:

```sqf
// Register "MyItem" so the framework reads variables prefixed "myAddon_myItem_*"
["MyItem", "myAddon_myItem"] call ace_items_fnc_setItemSettingPrefix;
```

```sqf
["MyItem"] call ace_items_fnc_getItemSettingPrefix;  // → "myAddon_myItem"
```

Whitelist/blacklist setting values must be parseable by `ace_items_fnc_parseContainerListSetting`. When both lists are empty the list check always passes. When either list has entries the container classname is checked: blacklist entries are blocked, whitelist entries are required.

---

## 4. Events

### 4.1 Listenable

| Event | Parameters | Locality | Description |
|---|---|---|---|
| `ace_items_itemStateInitialized` | `[unit, className, slot, stateIndex, state]` | Local | Fired when a new item state HashMap is created. Subscribe to add addon-specific fields. |
| `ace_items_inventoryChanged` | `[srcObj, destObj, className, srcSlot, destSlot]` | Local | Fired when an item moves between containers (detected by inventory diff on close or on item pickup). |
| `ace_items_itemDestroyed` | `[unit, className, slot, stateIndex, itemState, damagedClass, damageInfo]` | Local | Fired after an item is successfully destroyed or replaced with a damaged variant. `damagedClass` is `""` when the item was simply removed. `damageInfo` is `[shooter, bodyPart, ammoType, isBackShot]`. |
| `ace_items_itemStateFieldSet` | `[unit, className, slot, index, updates]` | Local | Fired after item state fields are written. `updates` is `[[key, value], ...]`. Fires on the machine local to the state object. |
| `ace_items_itemUsed` | `[unit, className, slot, ammoBefore, ammoConfig]` | Local | Fired after an item is successfully consumed by `ace_items_fnc_tryConsumeItem`. `ammoBefore` and `ammoConfig` are `-1` for non-magazine items. |

---

## 5. Scripting API

### 5.1 Usable items

**`ace_items_fnc_canUseItem`** — Returns whether the operation is allowed for a unit in a given container. Does **not** check whether the unit has the item; only whether using it there is permitted.

Returns `true` immediately when `ace_items_enableUsableItemRestrictions` is `false` or the item has no `ACE_UsableItemRestrictionsInfo`.

```sqf
// 0: Unit <OBJECT>
// 1: Container slot <STRING> ("vest", "uniform", "backpack", "assigned", "equipped")
//    or container object <OBJECT>
// 2: Item classname <STRING>
// 3: Operation mode name <STRING> (default: "defaultUse")
// Return: allowed <BOOL>

[ACE_player, "vest", "MyItem", "defaultUse"] call ace_items_fnc_canUseItem;
```

---

**`ace_items_fnc_hasUsableItem`** — Returns whether the unit has the item in any container that permits the given operation.

```sqf
// 0: Unit <OBJECT>
// 1: Item classname <STRING>
// 2: Operation mode name <STRING> (default: "defaultUse")
// 3: Specific slot to restrict the search <STRING> (optional)
// Return: <BOOL>

// Default search order: vest → backpack → uniform → assigned → equipped
[ACE_player, "MyItem"] call ace_items_fnc_hasUsableItem;
```

---

**`ace_items_fnc_hasUsageRestriction`** — Returns whether the item has `ACE_UsableItemRestrictionsInfo` anywhere in its config inheritance chain.

```sqf
["MyItem"] call ace_items_fnc_hasUsageRestriction;
```

---

**`ace_items_fnc_tryConsumeItem`** — Removes one instance of the item from the first allowed container and returns metadata.

```sqf
// 0: Unit <OBJECT>
// 1: Item classname <STRING>
// 2: Container slot to restrict search to <STRING> (optional)
// 3: Operation mode name <STRING> (default: "defaultUse")
// Return: [success <BOOL>, slot <STRING>, magazineAmmoCount <NUMBER>, ammoConfig <CONFIG>]

// Default search order: vest → backpack → uniform → assigned → equipped
[ACE_player, "MyItem"] call ace_items_fnc_tryConsumeItem;
```

---

**`ace_items_fnc_parseContainerListSetting`** — Parses a whitelist/blacklist setting string into an array of classnames.

Accepted formats: `"[]"`, `["a","b"]`, `[a,b]`, `'a','b'`, or `"a, b"`.

```sqf
// 0: Setting value string <STRING>
// Return: array of classname strings <ARRAY>

["V_PlateCarrier1_rgr, B_AssaultPack_khk"] call ace_items_fnc_parseContainerListSetting;
// → ["V_PlateCarrier1_rgr", "B_AssaultPack_khk"]
```

---

### 5.2 Destroyable items

**`ace_items_fnc_isDestroyableItem`** — Returns whether the item has any destruction configuration.

```sqf
// 0: Item classname <STRING>
// Return: <BOOL>

["MyItem"] call ace_items_fnc_isDestroyableItem;
```

---

**`ace_items_fnc_getDestroyableItemInfo`** — Returns the full destruction config with `DestroyChance` already scaled by `destroyChanceFactor` and any per-item CBA setting.

```sqf
// 0: Item classname <STRING>
// Return: [destroyedClass, sounds[], ammoClass, canDestroyFn, onDestroyedFn, effectiveChance]
//   destroyedClass  <STRING>  — empty = remove only
//   sounds          <ARRAY>   — sound classname strings
//   ammoClass       <STRING>  — explosion ammo classname or ""
//   canDestroyFn    <CODE>    — compiled CanDestroy or nil
//   onDestroyedFn   <CODE>    — compiled OnDestroyed or nil
//   effectiveChance <NUMBER>  — 0–100 after settings/factor

["MyItem"] call ace_items_fnc_getDestroyableItemInfo;
```

---

### 5.3 Item state

State is stored per `(object, slot, classname, index)` where index is the nth occurrence of that classname in the slot. Indices align with the order returned by `ace_items_fnc_getItemsInSlot`.

Every state HashMap always contains two framework-managed keys:

| Key constant | String value | Description |
|---|---|---|
| `I_KEY_ITEM_STATE_CLASSNAME` | `"className"` | Item classname |
| `I_KEY_ITEM_STATE_INVENTORY_SLOT` | `"inventorySlot"` | Slot at time of last write |

Addons add their own keys by subscribing to the `ace_items_itemStateInitialized` event.

---

**`ace_items_fnc_getItemsInSlot`** — Returns classnames in a slot in engine order, with duplicates for multiple instances of the same item.

```sqf
// 0: Unit or container object <OBJECT>
// 1: Slot <STRING> ("assigned", "equipped", "vest", "uniform", "backpack", "object", "weapons")
// Return: classnames <ARRAY>

[player, "vest"] call ace_items_fnc_getItemsInSlot;
[myBox, "object"] call ace_items_fnc_getItemsInSlot;
```

---

**`ace_items_fnc_initItemState`** — Creates a new state HashMap for an item instance. RemoteExecs automatically if the state object is not local.

```sqf
// 0: Unit or container object <OBJECT>
// 1: Item classname <STRING>
// 2: Slot <STRING>
// 3: Index <NUMBER> (default: 0)
// Return: new state HashMap or nil

[player, "MyItem", "vest", 0] call ace_items_fnc_initItemState;
```

---

**`ace_items_fnc_getItemState`** — Returns the state HashMap for an item instance, or `nil`.

```sqf
// 0: Unit or container object <OBJECT>
// 1: Item classname <STRING>
// 2: Slot <STRING>
// 3: Index <NUMBER> (default: 0)
// Return: state HashMap or nil

[player, "MyItem", "vest", 0] call ace_items_fnc_getItemState;
```

---

**`ace_items_fnc_getItemStateField`** — Returns a single field from state with a fallback default.

```sqf
// 0: Unit or container object <OBJECT>
// 1: Item classname <STRING>
// 2: Slot <STRING>
// 3: Index <NUMBER> (default: 0)
// 4: Field key <STRING>
// 5: Default value <ANY>
// Return: field value or default

[player, "MyItem", "vest", 0, "batteryLevel", 1.0] call ace_items_fnc_getItemStateField;
```

---

**`ace_items_fnc_setItemState`** — Applies key-value pairs to an item's state, initialising it if missing. RemoteExecs if not local.

```sqf
// 0: Unit or container object <OBJECT>
// 1: Item classname <STRING>
// 2: Slot <STRING>
// 3: Index <NUMBER> (default: 0)
// 4: Key-value pairs <ARRAY> ([[key, value], ...])
// Return: updated state HashMap or nil

[player, "MyItem", "vest", 0, [["batteryLevel", 0.5], ["powered", false]]] call ace_items_fnc_setItemState;
```

---

**`ace_items_fnc_setItemStateField`** — Sets a single field. Convenience wrapper around `setItemState`.

```sqf
// 0–3: same as setItemState
// 4: Field key <STRING>
// 5: Value <ANY>
// Return: updated state HashMap or nil

[player, "MyItem", "vest", 0, "batteryLevel", 0.5] call ace_items_fnc_setItemStateField;
```

---

**`ace_items_fnc_removeItemState`** — Removes all state for a classname in a slot (all indices).

```sqf
// 0: Unit or container object <OBJECT>
// 1: Item classname <STRING>
// 2: Slot <STRING>

[player, "MyItem", "vest"] call ace_items_fnc_removeItemState;
```

---

**`ace_items_fnc_getAllItemStates`** — Returns every state HashMap across all slots on a target.

```sqf
// 0: Unit or container object <OBJECT>
// Return: array of state HashMaps <ARRAY>

[player] call ace_items_fnc_getAllItemStates;
```

---

**`ace_items_fnc_replaceItem`** — Replaces one instance of an item with another in any slot type, including assigned (linked) items. Optionally migrates state.

```sqf
// 0: Unit or container object <OBJECT>
// 1: Current classname <STRING>
// 2: Replacement classname <STRING>
// 3: Slot <STRING>
// 4: State index of the instance to replace <NUMBER>
// 5: Migrate state to replacement <BOOL> (default: false)
// 6: For "assigned" only: link replacement in slot; false = add to inventory <BOOL> (default: true)

[player, "MyItem", "MyItem_NoPower", "vest", 0, true] call ace_items_fnc_replaceItem;
```

---

### 5.4 State migration

State migrates automatically when the player opens/closes inventory and when items are taken directly from the ground or a container.

---

**`ace_items_fnc_migrateItemState`** — Moves state from one object/slot to another. Fully locality-aware; uses CBA remote events when source or destination is not local.

```sqf
// 0: Source object <OBJECT>
// 1: Destination object <OBJECT>
// 2: Item classname <STRING>
// 3: Source slot <STRING>
// 4: Destination slot <STRING>
// Return: migrated state HashMap or nil

[srcObj, destObj, "MyItem", "vest", "uniform"] call ace_items_fnc_migrateItemState;
```

---

### 5.5 Item settings

**`ace_items_fnc_createItemSettings`** — Creates all CBA settings for an item that has usage restrictions and/or destroyable-item config. Also registers the setting prefix so the framework can look up overrides at runtime.

```sqf
// 0: Item classname <STRING>
// 1: Setting prefix <STRING>
// 2: Category [parent, subcategory] <ARRAY>
// 3: Display name <STRING>

["MyItem", "myAddon_myItem", ["myAddon", "My Item"], "My Item"] call ace_items_fnc_createItemSettings;
```

Settings created per operation mode (for items with `ACE_UsableItemRestrictionsInfo`):

| Variable | Type | Description |
|---|---|---|
| `<prefix>_operationModeDisallowedWhenAssigned_<mode>` | CHECKBOX | Block when item is in an assigned slot |
| `<prefix>_operationModeDisallowedWhenEquipped_<mode>` | CHECKBOX | Block when item is in an equipped container slot |
| `<prefix>_operationModeDisallowedInVest_<mode>` | CHECKBOX | Block when item is inside the vest |
| `<prefix>_operationModeDisallowedInUniform_<mode>` | CHECKBOX | Block when item is inside the uniform |
| `<prefix>_operationModeDisallowedInBackpack_<mode>` | CHECKBOX | Block when item is inside the backpack |
| `<prefix>_operationModeDisallowedUnderwater_<mode>` | CHECKBOX | Block when unit is underwater |
| `<prefix>_operationModeDisallowedInAir_<mode>` | CHECKBOX | Block when unit is airborne |
| `<prefix>_operationModeDisallowedInVehicles_<mode>` | CHECKBOX | Block when unit is in a vehicle |
| `<prefix>_operationModeContainerWhitelist_<mode>` | EDITBOX | Comma-separated or array-literal container classnames that are allowed |
| `<prefix>_operationModeContainerBlacklist_<mode>` | EDITBOX | Comma-separated or array-literal container classnames that are blocked |

For items with `ACE_DestroyableItemInfo`:

| Variable | Type | Description |
|---|---|---|
| `<prefix>_destroyChanceOnHit` | SLIDER (0–100) | Per-item destroy chance; multiplied by `ace_items_destroyChanceFactor` |

---

**`ace_items_fnc_setItemSettingPrefix`** / **`ace_items_fnc_getItemSettingPrefix`** — Register or retrieve the CBA setting prefix for an item class without creating settings.

```sqf
["MyItem", "myAddon_myItem"] call ace_items_fnc_setItemSettingPrefix;
["MyItem"] call ace_items_fnc_getItemSettingPrefix;  // → "myAddon_myItem"
```

