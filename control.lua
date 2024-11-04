local has_value = require('lib.common').has_value

script.on_init(function()
    global.opened_changes = global.opened_changes or {}
end)

script.on_configuration_changed(function(event)
    -- local FoF = event.mod_changes["First_One_Is_Free"]
    -- if FoF and FoF.old_version == "0.0.2" then
    --  global.opened_changes = global.opened_changes or {}
    -- end
end)

script.on_event(defines.events.on_player_main_inventory_changed, function(event)
    local player = game.players[event.player_index]
    if player and player.character then
        if isSafeToChange(player) then
            changeInventorySlots(player)
        else
            global.opened_changes[player.name] = true
        end
    end
end)

script.on_nth_tick(60, function(event)
    for playerName, flag in pairs(global.opened_changes) do
        if flag then
            local player = game.players[playerName]
            if player and
                 player.valid and
                 player.connected and
                 player.character and
                 isSafeToChange(player) then
                changeInventorySlots(player)
                global.opened_changes[playerName] = false
            end
        end
    end
end)

local stack_size_cache = {}
function stack_size(item)
    stack_size_cache[item] = stack_size_cache[item] or game.item_prototypes[item].stack_size
    return stack_size_cache[item]
end

function inventory_stacks(inventory)
    local contents = inventory.get_contents()
    local stacks = 0
    for item, count in pairs(contents) do
        stacks = stacks + math.ceil(count / stack_size(item))
    end
    return stacks
end

local creative_inventory = false

function changeInventorySlots(player)
    local main_inv = player.get_main_inventory()
    local contents = main_inv.get_contents()
    if creative_inventory then
        -- TODO don't remove non-empty planners
        for item, count in pairs(contents) do
            if not has_value({'blueprint', 'blueprint-book', 'upgrade-planner', 'deconstruction-planner'}, game.item_prototypes[item].type) then
                local diff = count - stack_size(item) * ((game.item_prototypes[item].place_result == nil and stack_size(item) == 1) and 2 or 1)
                if diff > 0 then main_inv.remove({name = item, count = diff})
                elseif diff < 0 then main_inv.insert({name = item, count = -diff}) end
            end
        end
        if player.cursor_stack.valid_for_read then
            player.cursor_stack.count = stack_size(player.cursor_stack.name)
        end
    end

    local stacks = inventory_stacks(main_inv)

    local newTotal = stacks + player.mod_settings['infiniteinventory-empty-slots'].value
    local withoutBonus = #main_inv - player.character_inventory_slots_bonus
    local newBonus = newTotal - withoutBonus

    -- Pi-C: Check if the value of player.character_inventory_slots_bonus will be different after applying newBonus
    local oldBonus = player.character_inventory_slots_bonus 
    player.character_inventory_slots_bonus = math.max(0, newBonus)
    local change = (oldBonus ~= player.character_inventory_slots_bonus)

    -- if change ~= 0 then game.print(game.table_to_json({stacks, newBonus, #main_inv})) end

    -- Pi-C: Allow minime to update its dummy iff player.character_inventory_slots_bonus has changed
    if change and remote.interfaces.minime and remote.interfaces.minime.main_inventory_resized then
        remote.call("minime", "main_inventory_resized", player.index)
    end

end

function isSafeToChange(player)
    -- player.print(defines.gui_type.none..' -- '..player.opened_gui_type)
    local main_inv = player.get_main_inventory()
    local allow_exp = player.mod_settings['infiniteinventory-allow-expansion'].value
    return
        player.opened_gui_type == defines.gui_type.none or
        allow_exp == 'Always' or
            allow_exp == 'Non-character GUI' and
            player.opened_gui_type ~= defines.gui_type.controller and
            main_inv and #main_inv == inventory_stacks(main_inv)
end
