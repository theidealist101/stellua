for i = 1, 4 do
    minetest.register_node("stl_moreplants:vines"..i, {
        description = "Vines",
        drawtype = "plantlike",
        tiles = {"stl_moreplants_vines"..i..".png"},
        inventory_image = "stl_moreplants_vines"..i..".png",
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "color",
        palette = "palette_foliage.png",
        walkable = false,
        climbable = true,
        selection_box = {type="fixed", fixed={-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}},
        groups = {snappy=2, vines=1}
    })
end

minetest.register_node("stl_moreplants:glow_vines", {
    description = "Glow Vines",
    drawtype = "plantlike",
    tiles = {"stl_moreplants_glow_vines.png"},
    inventory_image = "stl_moreplants_glow_vines.png",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 8,
    paramtype2 = "color",
    palette = "palette_foliage.png",
    walkable = false,
    climbable = true,
    selection_box = {type="fixed", fixed={-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}},
    groups = {snappy=2, vines=1, cavetorch=1}
})

local i = 1
for heat = -4, 4 do
    for heal = -2, 6 do
        local heat_message = heat ~= 0 and (math.abs(heat) > 2 and "very " or "quite ")..(heat < 0 and "cold" or "warm")
        local heal_message = heat ~= 0 and (heal < 0 and "toxic" or heal > 3 and "very tasty" or "quite tasty")
        local message = heat_message and heal_message and heat_message..", "..heal_message or heat_message or heal_message
        message = message and " ("..message..")" or " (no effect)"
        local text = 1--i%2+1
        minetest.register_node("stl_moreplants:fruit"..i, {
            description = "Fruit"..message,
            drawtype = "plantlike",
            tiles = {"stl_moreplants_fruit"..text..".png"},
            inventory_image = "stl_moreplants_fruit"..text..".png",
            paramtype = "light",
            sunlight_propagates = true,
            light_source = 5,
            paramtype2 = "color",
            palette = "palette_dye.png",
            walkable = false,
            selection_box = {type="fixed", fixed={-0.25, -0.375, -0.25, 0.25, 0.25, 0.25}},
            groups = {snappy=2, fruit=1, cavetorch=1},
            on_use = function (itemstack, player, pointed)
                local meta = player:get_meta()
                meta:set_float("temp", meta:get_float("temp")+heat)
                player:set_hp(player:get_hp()+heal)
                itemstack:take_item()
                return itemstack
            end
        })
        i = i+1
    end
end