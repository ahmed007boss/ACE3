#define COMPONENT items
#define COMPONENT_BEAUTIFIED Items
#include "\z\ace\addons\main\script_mod.hpp"

#define DEBUG_MODE_FULL
#define DISABLE_COMPILE_CACHE
#define ENABLE_PERFORMANCE_COUNTERS

#ifdef DEBUG_ENABLED_ITEMS
    #define DEBUG_MODE_FULL
#endif

#ifdef DEBUG_SETTINGS_ITEMS
    #define DEBUG_SETTINGS DEBUG_SETTINGS_ITEMS
#endif

#include "\z\ace\addons\main\script_macros.hpp"

#include "\z\ace\addons\items\script_item_state.hpp"
#include "\z\ace\addons\items\script_slots.hpp"

#include "\z\ace\addons\items\script_operation_modes.hpp"
