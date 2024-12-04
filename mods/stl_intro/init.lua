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
        text = "Launch into orbit by holding both sneak and jump simultaneously.",
        cond = function(player) return stellua.get_slot_index(player:get_pos()) end
    },
    {
        text = "Entering orbit, open planet menu in inventory to travel to another planet.",
        cond = function(player) return stellua.get_planet_index(player:get_pos().y) end
    },
    {
        text = "Stellonaut™ spacecraft are fully customisable. Expand your rocket using metals mined from the earth and glass from undersea quartz crystals. Add more fuel tanks for larger capacity, or more rocket engines to launch faster. (Specialist crafting equipment may be required.)",
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