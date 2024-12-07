--Bucket for picking up liquids
minetest.register_craftitem("stl_core:empty_bucket", {
    description = "Empty Bucket",
    inventory_image = "bucket.png",
    stack_max = 1,
    liquids_pointable = true,
    on_place = function (itemstack, user, pointed)
        local defs = minetest.registered_nodes[minetest.get_node(pointed.under).name]
        if defs.liquid_alternative_bucket then
            minetest.remove_node(pointed.under)
            return ItemStack(defs.liquid_alternative_bucket)
        end
        if defs.on_rightclick then return defs.on_rightclick(pointed.under, minetest.get_node(pointed.under), user, itemstack, pointed) end
    end
})

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
        liquid_alternative_frozen = defs.frozen_tiles and name.."_frozen" or defs.frozen_node,
        liquid_alternative_bucket = name.."_bucket",
        liquid_viscosity = defs.liquid_viscosity or 0,
        liquid_renewable = defs.liquid_renewable,
        liquid_range = 8,
        drowning = 1,
        damage_per_second = defs.damage_per_second,
        waving = 3,
        melt_point = defs.melt_point,
        boil_point = defs.boil_point,
        temp = defs.temp,
        groups = {water_source=1, water=1},
        sounds = stellua.node_sound_water_defaults({footstep={name = "default_water_footstep", gain = 0.05}})
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
        boil_point = defs.boil_point,
        temp = defs.temp,
        groups = {water=1},
        sounds = stellua.node_sound_water_defaults({footstep={name = "default_water_footstep", gain = 0.05}})
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
            groups = {cracky=1, slippery=3, ice=1},
            sounds = stellua.node_sound_ice_defaults()
        })
    end

    minetest.register_craftitem(name.."_bucket", {
        description = defs.description.." Bucket",
        inventory_image = defs.bucket_image,
        stack_max = 1,
        on_place = function (itemstack, user, pointed)
            if minetest.registered_nodes[minetest.get_node(pointed.above).name].buildable_to then
                minetest.set_node(pointed.above, {name=name.."_source"})
                return ItemStack("stl_core:empty_bucket")
            end
        end
    })
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
        drop = name.."_ball",
        sounds = stellua.node_sound_snow_defaults()
    })

    minetest.register_craftitem(name.."_ball", {
        description = defs.description,
        inventory_image = defs.tiles.."^[mask:stl_core_ball.png",
        groups = defs.groups
    })
end

register_water("stl_core:water", {
    description = "Water",
    tiles = "default_water",
    frozen_tiles = "default_ice.png^[opacity:225",
    bucket_image = "bucket_water.png",
    snow = "stl_core:water_snow",
    tint = {a=192, r=40, g=70, b=120},
    melt_point = 273,
    boil_point = 373,
    temp = 300,
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
    bucket_image = "bucket_river_water.png",
    snow = "stl_core:ammonia_snow",
    tint = {a=192, r=50, g=100, b=130},
    melt_point = 180,
    boil_point = 310,
    temp = 250
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
    bucket_image = "bucket.png^(stl_core_bucket_overlay.png^[multiply:#000500^[opacity:128)",
    tint = {a=128, r=0, g=5, b=0},
    liquid_viscosity = 0, --remember this wants to be a gas
    liquid_renewable = false,
    damage_per_second = 1,
    melt_point = 0, --can't be arsed to deal with solid methane
    boil_point = 230, --technically propane
    temp = 100,
    weight = 1.5
})

minetest.override_item("stl_core:methane_bucket", {groups={fuel=120}, fuel_replacement="stl_core:empty_bucket"})

register_snow("stl_core:benzene_snow", { --source: I saw it on wikipedia
    description = "Benzene Snow",
    tiles = "stl_core_benzene_snow.png",
    melt_point = 250
})

register_water("stl_core:petroleum", {
    description = "Petroleum",
    tiles = "stl_core_petroleum",
    frozen_node = "stl_core:bitumen",
    bucket_image = "bucket.png^(stl_core_bucket_overlay.png^[multiply:#000500)",
    tint = {a=250, r=0, g=5, b=0},
    liquid_viscosity = 7,
    liquid_renewable = false,
    animation_period = 2,
    damage_per_second = 2,
    melt_point = 360, --an excuse to make it less common
    boil_point = 600,
    weight = 0.5,
    temp = 400,
    generate_as_lava = true
})

minetest.override_item("stl_core:petroleum_bucket", {groups={fuel=200}, fuel_replacement="stl_core:empty_bucket"})

minetest.register_node("stl_core:bitumen", {
    description = "Bitumen",
    drawtype = "glasslike",
    tiles = {"stl_core_bitumen.png"},
    liquid_alternative_source = "stl_core:petroleum_source",
    walkable = false,
    liquid_move_physics = true,
    liquid_viscosity = 7,
    post_effect_color = {a=255, r=0, g=0, b=0},
    damage_per_second = 1,
    groups = {crumbly=2, disable_jump=1, fuel=100},
    sounds = stellua.node_sound_dirt_defaults()
})

register_water("stl_core:lava", {
    description = "Lava",
    tiles = "default_lava",
    frozen_node = "stl_core:basalt",
    tint = {a=240, r=192, g=64, b=0},
    bucket_image = "bucket_lava.png",
    snow = "stl_core:charred_earth",
    liquid_viscosity = 7,
    liquid_renewable = false,
    animation_period = 2,
    damage_per_second = 2,
    melt_point = 400, --lol
    boil_point = 1000, --also lol
    temp = 500,
    generate_as_lava = true
})

minetest.override_item("stl_core:lava_source", {light_source=12})
minetest.override_item("stl_core:lava_flowing", {light_source=12})

minetest.register_node("stl_core:basalt", {
    description = "Basalt",
    tiles = {"mcl_blackstone_basalt_top.png"},
    liquid_alternative_source = "stl_core:lava_source",
    groups = {cracky=2},
    sounds = stellua.node_sound_stone_defaults()
})

register_snow("stl_core:ash", {
    description = "Ash",
    tiles = "stl_core_ash.png",
    start_point = 350
})

register_snow("stl_core:charred_earth", {
    description = "Charred Earth",
    tiles = "default_coal_block.png",
    start_point = 410,
    groups = {fuel=20}
})

register_water("stl_core:acid", {
    description = "Sulfuric Acid",
    tiles = "stl_core_acid",
    frozen_node = "stl_core:sulfur",
    tint = {a=192, r=128, g=192, b=0},
    bucket_image = "bucket.png^(stl_core_bucket_overlay.png^[multiply:#80c000)",
    liquid_viscosity = 3,
    liquid_renewable = false,
    damage_per_second = 2,
    melt_point = 310,
    boil_point = 600,
    temp = 450,
    weight = 0.3,
    generate_as_lava = true
})

minetest.register_node("stl_core:sulfur", {
    description = "Sulfur",
    tiles = {"stl_core_sulfur.png"},
    liquid_alternative_source = "stl_core:acid_source",
    groups = {crumbly=2, fuel=30},
    sounds = stellua.node_sound_dirt_defaults()
})

--Make liquids freeze or evaporate depending on environment
minetest.register_abm({
    interval = 10,
    chance = 10,
    nodenames = {"group:water_source"},
    neighbours = {"air"},
    action = function (pos)
        local index = stellua.get_planet_index(pos.y)
        if not index then minetest.remove_node(pos) return end
        local defs = minetest.registered_nodes[minetest.get_node(pos).name]
        local planet = stellua.planets[index]
        local temp = planet.heat_stat*((500-pos.y)%1000)*0.002
        if defs and defs.melt_point >= temp then
            minetest.set_node(pos, {name=defs.liquid_alternative_frozen})
        elseif defs and (defs.boil_point <= temp or planet.atmo_stat < 0.5) then
            minetest.remove_node(pos)
        end
    end
})

for _, val1 in ipairs(stellua.registered_waters) do
    for _, val2 in ipairs(stellua.registered_waters) do
        if val1 ~= val2 and val1[2].temp > val2[2].temp then
            local new_node = {name=val1[2].frozen_tiles and val1[1].."_frozen" or val1[2].frozen_node}
            minetest.register_abm({
                interval = 1,
                chance = 1,
                nodenames = {val1[1].."_source", val1[1].."_flowing"},
                neighbors = {val2[1].."_source", val2[1].."_flowing"},
                action = function(pos) minetest.set_node(pos, new_node) end
            })
            if val1[2].frozen_tiles then
                local defs = minetest.registered_nodes[val1[1].."_frozen"]
                minetest.register_abm({
                    interval = 10,
                    chance = 10,
                    nodenames = {val1[1].."_frozen"},
                    without_neighbors = {val2[1].."_source", val2[1].."_flowing"},
                    action = function (pos)
                        local index = stellua.get_planet_index(pos.y)
                        if not index then return end
                        local temp = stellua.planets[index].heat_stat*((500-pos.y)%1000)*0.002
                        if defs and defs.melt_point < temp then
                            minetest.set_node(pos, {name=defs.liquid_alternative_source})
                        end
                    end
                })
            end
        end
    end
end