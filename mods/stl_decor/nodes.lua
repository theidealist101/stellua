minetest.register_node("stl_decor:stone_brick", {
    description = "Stone Brick",
    tiles = {"stl_decor_stone_brick.png"},
    paramtype2 = "color",
    palette = "palette.png",
    groups = {cracky=2},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_craft({
    output = "stl_decor:stone_brick 4",
    recipe = {
        {"stl_core:cobble", "stl_core:cobble"},
        {"stl_core:cobble", "stl_core:cobble"}
    }
})

stellua.register_color_craft("stl_decor:stone_brick", "stl_core:cobble")

minetest.register_node("stl_decor:filler_brick", {
    description = "Earth Brick",
    tiles = {"stl_decor_filler_brick.png"},
    paramtype2 = "color",
    palette = "palette.png",
    groups = {cracky=1},
    sounds = stellua.node_sound_stone_defaults()
})

for i = 1, 8 do
    minetest.register_craft({
        output = "stl_decor:filler_brick 4",
        recipe = {
            {"stl_core:filler"..i, "stl_core:filler"..i},
            {"stl_core:filler"..i, "stl_core:filler"..i}
        }
    })
    stellua.register_color_craft("stl_decor:filler_brick", "stl_core:filler"..i)
end

minetest.register_node("stl_decor:glass", {
    description = "Glass",
    drawtype = "glasslike",
    tiles = {"default_glass.png"},
    paramtype = "light",
    sunlight_propagates = true,
    groups = {cracky=1, spaceship=1},
    sounds = stellua.node_sound_glass_defaults()
})

minetest.register_craft({
    output = "stl_decor:glass",
    recipe = {
        {"group:quartz", "group:quartz"},
        {"group:quartz", "group:quartz"}
    }
})