--Override hand so it can break stuff
minetest.override_item("", {
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {
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
        groups = {cracky=1}
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
        groups = {snappy=1, attached_node=1},
        drop = {}
    })
end

--Surface liquids
minetest.register_node("stl_core:water_source", {
    description = "Water Source",
    drawtype = "liquid",
    tiles = {{name="default_water_source_animated.png", animation={type="vertical_frames", length=2}}},
    use_texture_alpha = "blend",
    post_effect_color = {a=192, r=40, g=70, b=120},
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "liquid",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "source",
    liquid_alternative_source = "stl_core:water_source",
    liquid_alternative_flowing = "stl_core:water_flowing",
    liquid_viscosity = 0,
    liquid_renewable = true,
    liquid_range = 8,
    drowning = 1
})

minetest.register_node("stl_core:water_flowing", {
    description = "Flowing Water",
    drawtype = "flowingliquid",
    tiles = {{name="default_water_flowing_animated.png", animation={type="vertical_frames", length=0.5}}},
    use_texture_alpha = "blend",
    post_effect_color = {a=192, r=30, g=90, b=120},
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "flowingliquid",
    walkable = false,
    pointable = false,
    buildable_to = true,
    liquidtype = "flowing",
    liquid_alternative_source = "stl_core:water_source",
    liquid_alternative_flowing = "stl_core:water_flowing",
    liquid_viscosity = 7,
    liquid_renewable = true,
    liquid_range = 8,
    drowning = 1
})