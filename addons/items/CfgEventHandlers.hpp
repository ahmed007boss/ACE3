class Extended_PreStart_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_preStart));
    };
};

class Extended_PreInit_EventHandlers {
    class ADDON {
        init = QUOTE(call COMPILE_SCRIPT(XEH_preInit));
    };
};

class Extended_PostInit_EventHandlers {
    class ADDON {
        clientInit = QUOTE(call COMPILE_SCRIPT(XEH_clientInit));
    };
};

class Extended_Init_EventHandlers {
    class CAManBase {
        class ADDON {
            init = "(_this select 0) addEventHandler ['InventoryOpened', {_this call ace_items_fnc_Inventory_onOpened}];(_this select 0) addEventHandler ['InventoryClosed', {_this call ace_items_fnc_Inventory_onClosed}];";
        };
    };
};



class Extended_Take_EventHandlers {
    class CAManBase {
        class ADDON {
            // Only handles direct pickup from ground/box without opening inventory
            take = "_this call ace_items_fnc_Inventory_onItemTaken";
        };
    };
};

class Extended_Put_EventHandlers {
    class CAManBase {
        class ADDON {
            // Handles immediate migration when inventory is open
            put = "_this call ace_items_fnc_Inventory_onItemPut";
        };
    };
};

class Extended_Killed_EventHandlers {
    class CAManBase {
        class ADDON {
            killed = "_this call ace_items_fnc_migrateItemStateToCorpse";
        };
    };
};
