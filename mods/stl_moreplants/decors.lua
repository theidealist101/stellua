--Spawning on land
stl_moreplants.register_place(function (planet)
    return {
        place_on = {planet.mapgen_filler, planet.mapgen_stone},
        fill_ratio = 0.03,
        fill_offset = -0.1
    }
end)

--Spawning on beaches
--[[stl_moreplants.register_place(function (planet)
    if not planet.water_level then return end
    return {
        place_on = {planet.mapgen_beach, planet.mapgen_stone},
        y_min = planet.water_level,
        y_max = planet.water_level+5,
        fill_ratio = 0.1
    }
end)]]

--Spawning by the waterside
stl_moreplants.register_place(function (planet)
    if not planet.water_level then return end
    return {
        place_on = {planet.mapgen_filler, planet.mapgen_stone},
        y_min = planet.water_level,
        y_max = planet.water_level+1,
        spawn_by = {planet.mapgen_water, planet.mapgen_water_top},
        fill_ratio = 0.2,
        fill_spread = 30
    }
end)

--Spawning in shallow water
stl_moreplants.register_place(function (planet)
    if not planet.water_level or planet.mapgen_water_top then return end
    return {
        place_on = {planet.mapgen_beach, planet.mapgen_stone},
        y_min = planet.water_level-5,
        y_max = planet.water_level-1,
        spawn_by = planet.mapgen_water,
        check_offset = 0,
        force_placement = true,
        fill_ratio = 0.1
    }
end)

--Spawning in deep water
stl_moreplants.register_place(function (planet)
    if not planet.water_level then return end
    return {
        place_on = {planet.mapgen_seabed, planet.mapgen_stone},
        y_max = planet.water_level,
        force_placement = true,
        fill_ratio = 0.1,
        fill_offset = -0.2
    }
end)

--Spawning on water
stl_moreplants.register_place(function (planet)
    if not planet.water_level then return end
    return {
        place_on = planet.mapgen_water,
        y_max = planet.water_level,
        y_min = planet.water_level-1,
        liquid_surface = true,
        place_offset_y = -1,
        force_placement = true,
        fill_ratio = 0.1,
        fill_offset = -0.2
    }
end)

--Spawning on cave floors
stl_moreplants.register_place(function (planet)
    return {
        place_on = planet.mapgen_stone,
        all_floors = true,
        fill_ratio = 0.1,
        fill_spread = 30
    }
end)

--Spawning on cave ceilings
stl_moreplants.register_place(function (planet)
    return {
        place_on = planet.mapgen_stone,
        all_ceilings = true,
        fill_ratio = 0.3,
        fill_spread = 30
    }
end)

--Spawning by the lavaside
--[[stl_moreplants.register_place(function (planet)
    if not planet.lava_level then return end
    return {
        place_on = planet.mapgen_stone,
        y_min = planet.lava_level,
        y_max = planet.lava_level+1,
        spawn_by = planet.mapgen_lava,
        fill_ratio = 0.3,
        fill_spread = 30
    }
end)]]

--Spawning in lava
--[[stl_moreplants.register_place(function (planet)
    if not planet.lava_level then return end
    return {
        place_on = planet.mapgen_stone,
        y_max = planet.lava_level,
        force_placement = true,
        fill_ratio = 0.03,
        fill_spread = 30
    }
end)]]

--Spawning on trees
--[[stl_moreplants.register_place(function ()
    return {
        place_on = "group:tree",
        all_floors = true,
        fill_ratio = 0.1
    }
end)]]

--Spawning under trees
stl_moreplants.register_place(function ()
    return {
        place_on = "group:tree",
        all_ceilings = true,
        fill_ratio = 0.2
    }
end)

--Basic single node
stl_moreplants.register_shape(function (planet, place)
    return {
        decoration = place.y_max == planet.water_level and stl_moreplants.get_items_in_group("leaves")
        or {stl_moreplants.get_items_in_group("leaves"), stl_moreplants.get_items_in_group("fruit")},
        param2_rand = true
    }
end)

--Short stack of nodes
stl_moreplants.register_shape(function (planet, place)
    if place.place_on == planet.mapgen_water then return end
    return {
        decoration = place.y_max == planet.water_level and stl_moreplants.get_items_in_group("leaves")
            or {stl_moreplants.get_items_in_group("leaves"), stl_moreplants.get_items_in_group("vines"), "stl_moreplants:glow_vines"},
        height = 2,
        height_max = 3,
        param2_rand = true
    }
end)

--Tall stack of nodes
stl_moreplants.register_shape(function (planet, place)
    if place.place_on == planet.mapgen_water then return end
    return {
        decoration = place.y_max == planet.water_level and stl_moreplants.get_items_in_group("leaves")
            or {stl_moreplants.get_items_in_group("vines"), "stl_moreplants:glow_vines"},
        height = 4,
        height_max = 10,
        param2_rand = true
    }
end)