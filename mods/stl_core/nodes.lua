--Void blocks, used for air outside build limits
minetest.register_node("stl_core:void", {
    description = "Void",
    drawtype = "airlike",
    paramtype = "light",
    sunlight_propagates = true,
    walkable = false,
    pointable = false
})

--Bedrock, used for bottom of worlds
minetest.register_node("stl_core:bedrock", {
    description = "Bedrock",
    tiles = {"mcl_core_bedrock.png"},
    sounds = stellua.node_sound_stone_defaults()
})

--Basic resources dropped from environment nodes
minetest.register_craftitem("stl_core:stick", {
    description = "Stick",
    inventory_image = "stl_core_stick.png",
    palette = "palette_foliage.png",
    groups = {fuel=1},
})

minetest.register_craftitem("stl_core:pebble", {
    description = "Pebble",
    inventory_image = "stl_core_pebble.png",
    palette = "palette.png"
})

minetest.register_craftitem("stl_core:moss", {
    description = "Moss",
    inventory_image = "stl_core_moss.png",
    palette = "palette_foliage.png",
    groups = {fuel=10}
})

minetest.register_node("stl_core:wood", {
    description = "Wood Planks",
    tiles = {"stl_core_wood.png"},
    paramtype2 = "color",
    palette = "palette_foliage.png",
    groups = {choppy=1, fuel=4},
    sounds = stellua.node_sound_wood_defaults()
})

--Get function for use in after_dig_node to drop a colored item
local function drop_with_color(item, chance)
    item = ItemStack(item)
    chance = chance or 1
    return function (pos, node, meta, user)
        if math.random() >= chance then return end
        item:get_meta():set_int("palette_index", node.param2)
        local left = user:get_inventory():add_item("main", item)
        if not left:is_empty() then
            minetest.add_item(pos, left)
        end
    end
end

--Basic stone variations used by all planets
for i = 1, 8 do
    minetest.register_node("stl_core:stone"..i, {
        description = "Stone",
        tiles = {"stl_core_stone"..i..".png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {cracky=2, stone=1, ground=1},
        drop = {},
        after_dig_node = drop_with_color("stl_core:cobble"),
        sounds = stellua.node_sound_stone_defaults()
    })
end

minetest.register_node("stl_core:cobble", {
    description = "Cobble",
    tiles = {"stl_core_stone2.png"},
    paramtype2 = "color",
    palette = "palette.png",
    groups = {cracky=2, stone=1},
    sounds = stellua.node_sound_stone_defaults()
})

--Filler nodes
for i = 1, 8 do
    minetest.register_node("stl_core:filler"..i, {
        description = "Earth",
        tiles = {"stl_core_filler"..i..".png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {crumbly=2, filler=1, ground=1},
        sounds = stellua.node_sound_dirt_defaults()
    })
end

--Tall grass decorations
for i = 1, 8 do
    minetest.register_node("stl_core:grass"..i, {
        description = "Grass",
        drawtype = "plantlike",
        tiles = {"stl_core_grass"..i..".png"},
        use_texture_alpha = "clip",
        palette = "palette_foliage.png",
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "color",
        walkable = false,
        --selection_box = {type="fixed", fixed={-0.375, -0.5, -0.375, 0.375, 0.125*((i-1)%4+1)*math.ceil(i*0.25)-0.5, 0.375}},
        pointable = false,
        buildable_to = true,
        floodable = true,
        waving = 1,
        groups = {attached_node=1},
        drop = {}
    })
end

minetest.register_node("stl_core:gravel", {
    description = "Gravel",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}},
    tiles = {"stl_core_gravel.png"},
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "color",
    palette = "palette.png",
    walkable = false,
    buildable_to = true,
    floodable = true,
    groups = {crumbly=2, falling_node=1},
    drop = {},
    after_dig_node = drop_with_color("stl_core:pebble"),
    sounds = stellua.node_sound_gravel_defaults()
})

--Some more life stuff
for i = 1, 4 do
    minetest.register_node("stl_core:moss"..i, {
        description = "Moss",
        drawtype = "nodebox",
        node_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}},
        tiles = {"stl_core_moss"..i..".png"},
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "color",
        palette = "palette_foliage.png",
        walkable = false,
        buildable_to = true,
        floodable = true,
        groups = {snappy=1, falling_node=1},
        drop = {},
        after_dig_node = drop_with_color("stl_core:moss"),
        sounds = stellua.node_sound_snow_defaults()
    })
end

for i = 1, 4 do
    minetest.register_node("stl_core:shrub"..i, {
        description = "Shrub",
        drawtype = "plantlike",
        tiles = {"stl_core_shrub"..i..".png"},
        inventory_image = "stl_core_shrub"..i..".png",
        selection_box = {type="fixed", fixed={-0.25, -0.5, -0.25, 0.25, 0.125, 0.25}},
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "color",
        palette = "palette_foliage.png",
        walkable = false,
        waving = 1,
        groups = {snappy=1, attached_node=1},
        drop = {},
        after_dig_node = drop_with_color("stl_core:stick", 0.4),
        sounds = stellua.node_sound_leaves_defaults()
    })
end

--Ores
for i = 1, 8 do
    minetest.register_node("stl_core:stone"..i.."_with_copper", {
        description = "Stone with Copper",
        tiles = {"stl_core_stone"..i..".png"},
        overlay_tiles = {"default_mineral_copper.png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {cracky=3},
        drop = "stl_core:copper",
        sounds = stellua.node_sound_stone_defaults()
    })

    minetest.register_node("stl_core:stone"..i.."_with_titanium", {
        description = "Stone with Titanium",
        tiles = {"stl_core_stone"..i..".png"},
        overlay_tiles = {"default_mineral_tin.png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {cracky=3},
        drop = "stl_core:titanium",
        sounds = stellua.node_sound_stone_defaults()
    })
end

minetest.register_craftitem("stl_core:copper", {
    description = "Copper",
    inventory_image = "default_copper_lump.png",
    groups = {metal=1}
})

minetest.register_craftitem("stl_core:titanium", {
    description = "Titanium",
    inventory_image = "default_tin_lump.png",
    groups = {metal=1}
})

--Plant pieces
for i = 1, 8 do
    minetest.register_node("stl_core:log"..i, {
        description = "Log",
        tiles = {"stl_core_log"..i.."_top.png", "stl_core_log"..i.."_top.png", "stl_core_log"..i..".png"},
        paramtype2 = "color",
        palette = "palette_foliage.png",
        groups = {choppy=2, tree=1, fuel=16},
        sounds = stellua.node_sound_wood_defaults()
    })
end

for i = 1, 8 do
    minetest.register_node("stl_core:leaves"..i, {
        description = "Leaves",
        drawtype = "allfaces_optional",
        tiles = {"stl_core_leaves"..i..".png"},
        use_texture_alpha = "clip",
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "color",
        palette = "palette_foliage.png",
        waving = 2,
        groups = {snappy=2, tree=1},
        drop = {},
        after_dig_node = drop_with_color("stl_core:stick", 0.2),
        sounds = stellua.node_sound_leaves_defaults()
    })
end

--Quartz crystals found underwater
local quartz_types = {
    {"Amethyst", "#c040ff"},
    {"Citrine", "#ffc040"},
    {"Clear Quartz", "#ffffff"},
    {"Rose Quartz", "#ff80c0"},
    {"Aventurine", "#40ffc0"}
}

for i, val in ipairs(quartz_types) do
    minetest.register_node("stl_core:quartz"..i, {
        description = val[1],
        drawtype = "glasslike",
        tiles = {"stl_core_quartz.png^[opacity:192"},
        use_texture_alpha = "blend",
        paramtype = "light",
        sunlight_propagates = true,
        light_source = 8,
        color = val[2],
        groups = {cracky=1},
        sounds = stellua.node_sound_glass_defaults()
    })
end

minetest.register_node("stl_core:uranium", {
    description = "Uranium",
    drawtype = "glasslike",
    tiles = {"stl_core_quartz.png^[opacity:192^[multiply:#c0ff80"},
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 12,
    groups = {cracky=4, fissile=1},
    sounds = stellua.node_sound_glass_defaults()
})