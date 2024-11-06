minetest.register_node("stl_decor:stone_brick", {
    description = "Stone Brick",
    tiles = {"stl_decor_stone_brick.png"},
    paramtype2 = "color",
    palette = "palette.png"
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
    palette = "palette.png"
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