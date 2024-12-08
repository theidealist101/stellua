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

for i = 1, 5 do
    minetest.register_craft({
        output = "stl_decor:glass",
        recipe = {
            {"stl_core:quartz"..i, "stl_core:quartz"..i},
            {"stl_core:quartz"..i, "stl_core:quartz"..i}
        }
    })
end

minetest.register_node("stl_decor:crate", {
    description = "Storage Crate",
    tiles = {"stl_decor_crate_top.png", "stl_decor_crate_bottom.png", "stl_decor_crate_side.png"},
    paramtype2 = "color",
    palette = "palette.png",
    groups = {choppy=2},
    sounds = stellua.node_sound_wood_defaults(),
    on_construct = function (pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("main", 24)
        meta:set_string("formspec", sfinv.make_formspec(nil, {nav_titles={}}, "list[context;main;0,0;8,3]", true))
    end,
    after_dig_node = function (pos, node, meta, user)
        local inv = user:get_inventory()
        for _, itemstack in ipairs(meta.inventory.main) do
            minetest.add_item(pos, inv:add_item("main", itemstack))
        end
    end
})

minetest.register_craft({
    output = "stl_decor:crate",
    recipe = {
        {"stl_core:wood", "stl_core:wood", "stl_core:wood"},
        {"stl_core:wood", "", "stl_core:wood"},
        {"stl_core:wood", "stl_core:wood", "stl_core:wood"}
    }
})

stellua.register_color_craft("stl_decor:crate", "stl_core:wood")