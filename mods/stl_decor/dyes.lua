minetest.register_node("stl_decor:flower", {
    description = "Flower",
    drawtype = "plantlike",
    tiles = {"stl_decor_flower.png"},
    inventory_image = "stl_decor_flower.png",
    selection_box = {type="fixed", fixed={-0.1875, -0.5, -0.1875, 0.1875, 0.1875, 0.1875}},
    walkable = true,
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "color",
    palette = "palette_dye.png",
    groups = {snappy=2, attached_node=1},
    sounds = stellua.node_sound_defaults()
})

minetest.register_craftitem("stl_decor:dye", {
    description = "Dye",
    inventory_image = "dye_white.png",
    palette = "palette_dye.png"
})

minetest.register_craft({
    type = "shapeless",
    output = "stl_decor:dye 4",
    recipe = {"stl_decor:flower"}
})

stellua.register_color_craft("stl_decor:dye", "stl_decor:flower")

function stellua.register_dyed_node(name, node, desc)
    local defs = table.copy(minetest.registered_nodes[node])
    defs.description = desc
    defs.paramtype2 = "color"
    defs.palette = "palette_dye.png"
    minetest.register_node(name, defs)
    minetest.register_craft({
        type = "shapeless",
        output = name,
        recipe = {node, "stl_decor:dye"}
    })
    minetest.register_craft({
        type = "shapeless",
        output = name,
        recipe = {name, "stl_decor:dye"}
    })
    stellua.register_color_craft(name, "stl_decor:dye")
end

stellua.register_dyed_node("stl_decor:stained_glass", "stl_decor:glass", "Stained Glass")
stellua.register_dyed_node("stl_decor:stained_wood", "stl_core:wood", "Stained Wood")

stellua.register_on_planet_generated(function (planet)
    local rand = PcgRandom(planet.seed)
    for _ = 1, math.ceil(planet.life_stat*2) do
        minetest.register_decoration({
            deco_type = "simple",
            place_on = {"group:filler"},
            fill_ratio = rand:next(1, 20)*0.0001,
            y_min = planet.level-500,
            y_max = planet.level+499,
            decoration = "stl_decor:flower",
            param2 = rand:next(0, 255)
        })
    end
end)