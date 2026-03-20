class CfgWeapons {
    /* CONFIG EXAMPLE:
   
    // Base ACE item config class that all ACE items inherit from
    class ACE_ItemCore;
        // Base CBA misc item info class used for inventory items
        class CBA_MiscItem_ItemInfo;

        // Example of an ACE item that can be actively used (e.g. via self-interaction)
        class ACE_UsableItemExample: ACE_ItemCore {
            // Hidden from normal arsenal/editor; only for documentation/example
            scope = 1;
            // Defines where and how the item can be used (container + operation mode restrictions)
            // Per-slot container rules use boolean flags; 1 = disallowed from that slot/state, 0 = allowed.
            class ACE_UsableItemRestrictionsInfo {
                displayName = CSTRING(OperationModeUse); 
                // Default operation: only allowed from uniform, blocked from vest/backpack
                disallowedWhenAssigned = 0;
                disallowedWhenEquipped = 0;
                disallowedInVest = 1;
                disallowedInUniform = 0;
                disallowedInBackpack = 1;
                disallowedUnderwater = 0;
                disallowedInAir = 0;
                disallowedInVehicles = 0;
                // Optional: extra condition evaluated at runtime (no CBA setting); receives [unit, container, itemClass, operationMode]
                useCondition = "";
                // Additional operation mode with different container rules
                class ENUM_OPERATIONMODES_ADVANCED_USE {
                    displayName = CSTRING(OperationModeUse);      // e.g. \"Use\"
                    // Allowed from any personal slot/state by default; mission makers can override via settings
                    disallowedWhenAssigned = 0;
                    disallowedWhenEquipped = 0;
                    disallowedInVest = 0;
                    disallowedInUniform = 0;
                    disallowedInBackpack = 0;
                    disallowedUnderwater = 0;
                    disallowedInAir = 0;
                    disallowedInVehicles = 0;
                    // Optional: extra condition evaluated at runtime (no CBA setting); receives [unit, container, itemClass, operationMode]
                    useCondition = "";
                };
            };
        };

        // Example of an item that can be destroyed and replaced by another item
        class ACE_DestroyableItemExample: ACE_ItemCore {
            // Hidden from normal arsenal/editor; only for documentation/example
            scope = 1;
            // Configuration block describing what item this turns into when destroyed
            class ACE_DestroyableItemInfo {
                // Classname of the item that will replace this one after destruction
                DestroyedItem = "ACE_DestroyedItemExample";
                // Optional: array of sound classnames, one will be picked at random and played when the item is destroyed
                DestroyingSounds[] = {"ACE_Destroy_Sound_1", "ACE_Destroy_Sound_2"};
                // Optional: ammo classname used to create an explosion/effect on the unit when the item is destroyed
                DestroyingAmmo = "ACE_Destroy_Ammo_Example";
                // Base destroy chance in percent (0–100); can be overridden by CBA setting if setting created for it
                DestroyChance = 10;
                // Code executed when the item is destroyed
                OnDestroyed = "";
                // Code to check if the item can be destroyed
                CanDestroy = "true";
            };
        };
3
        // Example of the destroyed version of the item shown above
        class ACE_DestroyedItemExample: ACE_ItemCore {
            // Hidden from normal arsenal/editor; only for documentation/example
            scope = 1;
            // Name of the ACE team shown in the arsenal tooltip
            author = ECSTRING(common,ACETeam);
            // Display name shown for the destroyed item in UI
            displayName = CSTRING(GenericDestroyedItem_DisplayName);
            // Short description shown in the item tooltip
            descriptionShort = CSTRING(GenericDestroyedItem_Description);
            // Configuration of how the destroyed item behaves as an inventory item
            class ItemInfo: CBA_MiscItem_ItemInfo {
                // Inventory mass (weight) of the destroyed item
                mass = 1;
            };
        }; 
        
    */
};
