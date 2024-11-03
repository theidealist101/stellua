--Override hand so it can break stuff
minetest.override_item("", {
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {
            cracky = {times={2}},
            crumbly = {times={2}},
            snappy = {times={0.5}}
        }
    }
})

--Basic stone variations used by all planets
for i = 1, 8 do
    minetest.register_node("stl_core:stone"..i, {
        description = "Stone "..i,
        tiles = {"stl_core_stone"..i..".png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {cracky=2}
    })
end

--Filler nodes
for i = 1, 8 do
    minetest.register_node("stl_core:filler"..i, {
        description = "Filler "..i,
        tiles = {"stl_core_filler"..i..".png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {crumbly=1}
    })
end

--Tall grass decorations
for i = 1, 8 do
    minetest.register_node("stl_core:grass"..i, {
        description = "Grass "..i,
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
        groups = {attached_node=1},
        drop = {}
    })
end

--Surface liquids
local function register_water(name, defs)
    local op = defs.tiles_opacity and "^[opacity:"..defs.tiles_opacity or ""

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
        liquid_viscosity = 0,
        liquid_renewable = defs.liquid_renewable,
        liquid_range = 8,
        drowning = 1,
        damage_per_second = defs.damage_per_second,
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
        liquid_viscosity = 7,
        liquid_renewable = defs.liquid_renewable,
        liquid_range = 8,
        drowning = 1,
        damage_per_second = defs.damage_per_second,
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

register_water("stl_core:water", {
    description = "Water",
    tiles = "default_water",
    frozen_tiles = "default_ice.png^[opacity:225",
    tint = {a=192, r=40, g=70, b=120},
    melt_point = 273,
    boil_point = 373
})

register_water("stl_core:ammonia_water", {
    description = "Ammonia Water",
    tiles = "default_river_water",
    frozen_tiles = "mcl_core_ice_packed.png^[opacity:225",
    tint = {a=192, r=50, g=100, b=130},
    melt_point = 180,
    boil_point = 310
})

register_water("stl_core:methane", {
    description = "Methane",
    tiles = "stl_core_methane",
    tiles_opacity = 224,
    tint = {a=224, r=0, g=5, b=0},
    liquid_renewable = false,
    damage_per_second = 1,
    melt_point = -100, --can't be arsed to deal with solid methane
    boil_point = 110
})

register_water("stl_core:lava", {
    description = "Lava",
    tiles = "default_lava",
    tint = {a=240, r=192, g=64, b=0},
    liquid_renewable = false,
    animation_period = 2,
    damage_per_second = 2,
    melt_point = 400, --lol
    boil_point = 1000
})