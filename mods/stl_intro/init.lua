--The questline which serves to introduce the player to the game
local questline = {
    {
        text = "Entering the atmosphere of an unknown planet. Jump while in seat to steer the rocket.",
        cond = function(player) return player:get_attach() end
    },
    {
        text = "No fuel, unable to escape planet's gravity. Hold sneak to descend and seek fuel.",
        cond = function(player) return player:get_player_control().sneak end
    },
    {
        text = "Press Aux1 upon reaching the ground to park the rocket and exit.",
        cond = function(player) return not (player:get_attach() or stellua.assemble_vehicle(player:get_pos())) end
    },
    {
        text = "Search for fuel. Any sort of biomass will work, but some types are better than others.",
        cond = function (player)
            local inv = player:get_inventory()
            for _, itemstack in ipairs(inv:get_list("main")) do
                if not itemstack:is_empty() and minetest.get_item_group(itemstack:get_name(), "fuel") > 0 then return true end
            end
        end
    },
    {
        text = "Resources can be harvested faster using tools. If there is no wood in the vicinity, use pebbles from gravel patches on the ground.",
        cond = function (player)
            local inv = player:get_inventory()
            for _, itemstack in ipairs(inv:get_list("main")) do
                if not itemstack:is_empty() and minetest.registered_tools[itemstack:get_name()] then return true end
            end
        end
    },
    {
        text = "Once you have gathered plenty of fuel, enter the rocket again by right-clicking on any part of it.",
        cond = function(player) return stellua.assemble_vehicle(vector.round(player:get_pos())) end
    },
    {
        text = "Refuel the rocket by inserting biomass into the fuel tank, which is located directly above the seat. Launching into orbit should require at least 10 logs or equivalent.",
        cond = function (player)
            local _, _, _, _, tanks = stellua.assemble_vehicle(vector.round(player:get_pos()))
            if not tanks then return end
            for _, pos in ipairs(tanks) do
                local inv = minetest.get_meta(pos):get_inventory()
                for _, itemstack in ipairs(inv:get_list("main")) do
                    if not itemstack:is_empty() and minetest.get_item_group(itemstack:get_name(), "fuel") > 0 then return true end
                end
            end
        end
    },
    {
        text = "No impulse engine detected, launching without an impulse engine is not recommended as you will not be able to travel to other planets. Recalibrating.\nImpulse power requires a nuclear power source. Find a cave and search for fissile elements underground.",
        cond = function (player)
            local inv = player:get_inventory()
            for _, itemstack in ipairs(inv:get_list("main")) do
                if not itemstack:is_empty() and minetest.get_item_group(itemstack:get_name(), "fissile") > 0 then return true end
            end
        end
    },
    {
        text = "Crafting spaceship parts requires advanced crafting equipment. Once you have collected a suitable amount of fissile material, seek out a technology assembler. These may be found in precursor buildings.",
        cond = function(player) return minetest.get_node(vector.round(player:get_pos())).name == "stl_precursor:gate" end
    },
    {
        text = "Impulse engines are crafted with four pieces of fissile material in the centre and eight pieces of metal on top and bottom.",
        cond = function (player)
            local inv = player:get_inventory()
            for _, itemstack in ipairs(inv:get_list("main")) do
                if not itemstack:is_empty() and minetest.get_item_group(itemstack:get_name(), "impulse") > 0 then return true end
            end
        end
    },
    {
        text = "Stellonaut™ spacecraft are fully customisable. Expand your rocket using metal blocks and glass from undersea quartz crystals; craft more rocket parts to augment its capabilities.\nPlace the impulse engine anywhere on the ship and insert plenty of fissile material into it.",
        cond = function (player)
            local _, _, _, _, tanks = stellua.assemble_vehicle(vector.round(player:get_pos()))
            if not tanks then return end
            for _, pos in ipairs(tanks) do
                local inv = minetest.get_meta(pos):get_inventory()
                for _, itemstack in ipairs(inv:get_list("main")) do
                    if not itemstack:is_empty() and minetest.get_item_group(itemstack:get_name(), "fissile") > 0 then return true end
                end
            end
        end
    },
    {
        text = "Launch into orbit in the rocket by holding both sneak and jump simultaneously.",
        cond = function(player) return stellua.get_slot_index(player:get_pos()) end
    },
    {
        text = "Entering orbit, open planet menu in inventory to travel to another planet.",
        cond = function(player) return stellua.get_planet_index(player:get_pos().y) end
    },
    {
        text = "Dozens of planets have been detected around you in multiple star systems. Go explore them all, see what wonders you can find. The universe is yours to command.",
        cond = function() return true end
    }
}

--Advance the questline if the condition is met
minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local meta = player:get_meta()
        local stage = meta:get_int("stage")
        if stage == 0 or stage > 0 and questline[stage].cond(player) then
            stage = stage+1
            if questline[stage] then minetest.chat_send_player(player:get_player_name(), questline[stage].text)
            else stage = -1 end
        end
        meta:set_int("stage", stage)
    end
end)