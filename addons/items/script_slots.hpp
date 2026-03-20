// Container/slot names for item state. Use these macros instead of string literals.

#ifndef SLOT_ASSIGNED
    #define SLOT_ASSIGNED "assigned"
#endif
#ifndef SLOT_EQUIPPED
    #define SLOT_EQUIPPED "equipped"
#endif
#ifndef SLOT_VEST_CONTAINER
    #define SLOT_VEST_CONTAINER "vestItems"
#endif
#ifndef SLOT_UNIFORM_CONTAINER
    #define SLOT_UNIFORM_CONTAINER "uniformItems"
#endif
#ifndef SLOT_BACKPACK_CONTAINER
    #define SLOT_BACKPACK_CONTAINER "backpackItems"
#endif
#ifndef SLOT_OBJECT
    #define SLOT_OBJECT "object"
#endif
#ifndef SLOT_WEAPONS
    #define SLOT_WEAPONS "weapons"
#endif
// Items seated in weapon slots (magazine, optic, silencer, bipod) per weapon
#ifndef SLOT_PRIMARY_WEAPON_ITEMS
    #define SLOT_PRIMARY_WEAPON_ITEMS "primaryWeaponItems"
#endif
#ifndef SLOT_SECONDARY_WEAPON_ITEMS
    #define SLOT_SECONDARY_WEAPON_ITEMS "secondaryWeaponItems"
#endif
#ifndef SLOT_HANDGUN_WEAPON_ITEMS
    #define SLOT_HANDGUN_WEAPON_ITEMS "handgunItems"
#endif
#ifndef SLOT_BINOCULAR_ITEMS
    #define SLOT_BINOCULAR_ITEMS "binocularItems"
#endif

// All wearable container slots (vest, uniform, backpack) — for iteration / validation
#define SLOTS_CONTAINERS [SLOT_VEST_CONTAINER, SLOT_UNIFORM_CONTAINER, SLOT_BACKPACK_CONTAINER]

#define SLOTS_PERSONAL [SLOT_ASSIGNED, SLOT_EQUIPPED, SLOT_WEAPONS]

#define SLOTS_ALL [SLOT_ASSIGNED, SLOT_EQUIPPED, SLOT_WEAPONS, SLOT_PRIMARY_WEAPON_ITEMS, SLOT_SECONDARY_WEAPON_ITEMS, SLOT_HANDGUN_WEAPON_ITEMS, SLOT_BINOCULAR_ITEMS, SLOT_VEST_CONTAINER, SLOT_UNIFORM_CONTAINER, SLOT_BACKPACK_CONTAINER, SLOT_OBJECT]
