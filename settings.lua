data:extend({
    {
        type = "int-setting",
        name = 'infiniteinventory-empty-slots',
        setting_type = 'runtime-per-user',
        default_value = 24,
        order = '0',
        localised_name = 'Empty slots',
    }, {
        type = "bool-setting",
        name = 'infiniteinventory-creative-inventory',
        setting_type = 'runtime-global',
        default_value = false,
        order = '1',
        localised_name = 'Creative Inventory',
    }, {
        type = "string-setting",
        name = 'infiniteinventory-allow-expansion',
        setting_type = 'runtime-per-user',
        default_value = 'Non-character GUI',
        allowed_values = {'Never', 'Non-character GUI', 'Always'},
        order = '2',
        localised_name = 'Allow inventory expansion when a GUI is open',
    },
})