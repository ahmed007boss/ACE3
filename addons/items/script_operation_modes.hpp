#ifndef ENUM_OPERATIONMODES_USE
    // Enum-style key for the default "Use" operation mode
    #define ENUM_OPERATIONMODES_USE defaultUse
    // String form used when passing the operation mode name around
    #define ENUM_STRING_OPERATIONMODES_USE QUOTE(ENUM_OPERATIONMODES_USE)
#endif

// Example/secondary operation mode used in documentation configs
#ifndef ENUM_OPERATIONMODES_ADVANCED_USE
    #define ENUM_OPERATIONMODES_ADVANCED_USE advancedUse
    #define ENUM_STRING_OPERATIONMODES_ADVANCED_USE QUOTE(ENUM_OPERATIONMODES_ADVANCED_USE)
#endif
