--Basic resources dropped from environment nodes
minetest.register_craftitem("stl_core:stick", {
    description = "Stick",
    inventory_image = "stl_core_stick.png",
    palette = "palette_foliage.png"
})

minetest.register_craftitem("stl_core:pebble", {
    description = "Pebble",
    inventory_image = "stl_core_pebble.png",
    palette = "palette.png"
})

minetest.register_craftitem("stl_core:moss", {
    description = "Moss",
    inventory_image = "stl_core_moss.png",
    palette = "palette_foliage.png"
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
        groups = {cracky=2, stone=1},
        drop = {},
        after_dig_node = drop_with_color("stl_core:cobble")
    })
end

minetest.register_node("stl_core:cobble", {
    description = "Cobble",
    tiles = {"stl_core_stone2.png"},
    paramtype2 = "color",
    palette = "palette.png",
    groups = {cracky=2, stone=1}
})

--Filler nodes
for i = 1, 8 do
    minetest.register_node("stl_core:filler"..i, {
        description = "Earth",
        tiles = {"stl_core_filler"..i..".png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {crumbly=2, filler=1}
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

--Surface liquids
stellua.registered_waters = {}
stellua.registered_snows = {}

local function register_water(name, defs)
    local op = defs.tiles_opacity and "^[opacity:"..defs.tiles_opacity or ""
    table.insert(stellua.registered_waters, {name, defs})

    minetest.register_node(name.."_source", {
        description = defs.description.." Source",
        drawtype = "liquid",
        tiles = {
            {name=defs.tiles.."_source_animated.png"..op, animation={type="vertical_frames", length=2*(defs.animation_period or 1)}, backface_culling=false},
            {name=defs.tiles.."_source_animated.png"..op, animation={type="vertical_frames", length=2*(defs.animation_period or 1)}}
        },
        use_texture_alpha = "blend",
        post_effect_color = defs.tint,
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "liquid",
        walkable = false,
        pointable = false,
        buildable_to = true,
        liquidtype = "source",
        liquid_alternative_source = name.."_source",
        liquid_alternative_flowing = name.."_flowing",
        liquid_alternative_frozen = defs.frozen_tiles and name.."_frozen",
        liquid_viscosity = defs.liquid_viscosity or 0,
        liquid_renewable = defs.liquid_renewable,
        liquid_range = 8,
        drowning = 1,
        damage_per_second = defs.damage_per_second,
        waving = 3,
        melt_point = defs.melt_point,
        boil_point = defs.boil_point
    })

    minetest.register_node(name.."_flowing", {
        description = "Flowing "..defs.description,
        drawtype = "flowingliquid",
        special_tiles = {
            {name=defs.tiles.."_flowing_animated.png"..op, animation={type="vertical_frames", length=0.5*(defs.animation_period or 1)}, backface_culling=false},
            {name=defs.tiles.."_flowing_animated.png"..op, animation={type="vertical_frames", length=0.5*(defs.animation_period or 1)}}
        },
        use_texture_alpha = "blend",
        post_effect_color = defs.tint,
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "flowingliquid",
        walkable = false,
        pointable = false,
        buildable_to = true,
        liquidtype = "flowing",
        liquid_alternative_source = name.."_source",
        liquid_alternative_flowing = name.."_flowing",
        liquid_viscosity = defs.liquid_viscosity or 0,
        liquid_renewable = defs.liquid_renewable,
        liquid_range = 8,
        drowning = 1,
        damage_per_second = defs.damage_per_second,
        waving = 3,
        melt_point = defs.melt_point,
        boil_point = defs.boil_point
    })

    if defs.frozen_tiles then
        minetest.register_node(name.."_frozen", {
            description = defs.description.." Ice",
            drawtype = "glasslike",
            tiles = {defs.frozen_tiles},
            use_texture_alpha = "blend",
            paramtype = "light",
            sunlight_propagates = true,
            liquid_alternative_source = name.."_source",
            melt_point = defs.melt_point,
            boil_point = defs.boil_point,
            groups = {cracky=1, slippery=3}
        })
    end
end

local function register_snow(name, defs)
    defs.start_point = defs.start_point or 0
    defs.melt_point = defs.melt_point or 1000
    table.insert(stellua.registered_snows, {name, defs})

    minetest.register_node(name, {
        description = defs.description,
        drawtype = "nodebox",
        node_box = {type="leveled", fixed={-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}},
        tiles = {defs.tiles},
        paramtype = "light",
        sunlight_propagates = true,
        paramtype2 = "leveled",
        groups = {crumbly=1, falling_node=1},
        melt_point = defs.melt_point,
        start_point = defs.start_point,
        walkable = false,
        buildable_to = true,
        floodable = true,
        drop = name.."_ball"
    })

    minetest.register_craftitem(name.."_ball", {
        description = defs.description,
        inventory_image = defs.tiles.."^[mask:stl_core_ball.png"
    })
end

register_water("stl_core:water", {
    description = "Water",
    tiles = "default_water",
    frozen_tiles = "default_ice.png^[opacity:225",
    snow = "stl_core:water_snow",
    tint = {a=192, r=40, g=70, b=120},
    melt_point = 273,
    boil_point = 373,
    weight = 2
})

register_snow("stl_core:water_snow", {
    description = "Water Snow",
    tiles = "default_snow.png",
    melt_point = 273
})

register_water("stl_core:ammonia_water", {
    description = "Ammonia Water",
    tiles = "default_river_water",
    frozen_tiles = "mcl_core_ice_packed.png^[opacity:225",
    snow = "stl_core:ammonia_snow",
    tint = {a=192, r=50, g=100, b=130},
    melt_point = 180,
    boil_point = 310
})

register_snow("stl_core:ammonia_snow", {
    description = "Ammonia Snow",
    tiles = "stl_core_ammonia_snow.png",
    melt_point = 215,
    weight = 2
})

register_water("stl_core:methane", {
    description = "Methane",
    tiles = "stl_core_methane",
    --tiles_opacity = 128, --not supported by lvae
    tint = {a=128, r=0, g=5, b=0},
    liquid_viscosity = 0, --remember this wants to be a gas
    liquid_renewable = false,
    damage_per_second = 1,
    melt_point = 0, --can't be arsed to deal with solid methane
    boil_point = 230, --technically propane
    weight = 1.5
})

register_snow("stl_core:benzene_snow", { --source: I saw it on wikipedia
    description = "Benzene Snow",
    tiles = "stl_core_benzene_snow.png",
    melt_point = 250
})

register_water("stl_core:petroleum", {
    description = "Petroleum",
    tiles = "stl_core_petroleum",
    tint = {a=250, r=0, g=5, b=0},
    liquid_viscosity = 7,
    liquid_renewable = false,
    animation_period = 2,
    damage_per_second = 2,
    melt_point = 360, --an excuse to make it less common
    boil_point = 600,
    weight = 0.5
})

register_water("stl_core:lava", {
    description = "Lava",
    tiles = "default_lava",
    tint = {a=240, r=192, g=64, b=0},
    snow = "stl_core:charred_earth",
    liquid_viscosity = 7,
    liquid_renewable = false,
    animation_period = 2,
    damage_per_second = 2,
    melt_point = 400, --lol
    boil_point = 1000 --also lol
})

register_snow("stl_core:ash", {
    description = "Ash",
    tiles = "stl_core_ash.png",
    start_point = 350
})

register_snow("stl_core:charred_earth", {
    description = "Charred Earth",
    tiles = "default_coal_block.png",
    start_point = 410
})

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
    after_dig_node = drop_with_color("stl_core:pebble")
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
        after_dig_node = drop_with_color("stl_core:moss")
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
        after_dig_node = drop_with_color("stl_core:stick", 0.4)
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
        drop = "stl_core:copper"
    })

    minetest.register_node("stl_core:stone"..i.."_with_titanium", {
        description = "Stone with Titanium",
        tiles = {"stl_core_stone"..i..".png"},
        overlay_tiles = {"default_mineral_tin.png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {cracky=3},
        drop = "stl_core:titanium"
    })
end

minetest.register_craftitem("stl_core:copper", {
    description = "Copper",
    inventory_image = "default_copper_lump.png"
})

minetest.register_craftitem("stl_core:titanium", {
    description = "Titanium",
    inventory_image = "default_tin_lump.png"
})