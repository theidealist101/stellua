local stellua = minetest.ipc_get("stellua")
local planets, noises2d, noises3d = stellua.planets, stellua.noises2d, stellua.noises3d

--Some useful localisations for mapgen
local get_planet_index = stellua.get_planet_index
local c_air = minetest.CONTENT_AIR
local c_void = minetest.get_content_id("stl_core:void")
local c_bedrock = minetest.get_content_id("stl_core:bedrock")

--The actual mapgen
local function logic(noise, cavern, planet, y)
    local height = y-noise

    --if in a cavern, we can skip the terrain
    if not cavern then

        --check if terrain might be underwater
        if planet.water_level then
            if noise <= planet.water_level-2 then --beneath sea level
                if height < -planet.depth_seabed then return planet.c_stone, planet.param2_stone
                elseif height < 0 then return planet.c_seabed, planet.param2_seabed end
            elseif noise <= planet.water_level+4 then --within beach level
                if height < -planet.depth_beach then return planet.c_stone, planet.param2_stone
                elseif height < 0 then return planet.c_beach, planet.param2_beach end
            end
        end

        --otherwise terrain on land
        if height < -planet.depth_filler then return planet.c_stone, planet.param2_stone
        elseif height < 0 then return planet.c_filler, planet.param2_filler end
    end

    --might still be the water in the ocean
    if planet.water_level and y <= planet.water_level and height >= 0 then
        if planet.depth_water_top and y-planet.water_level > -planet.depth_water_top then return planet.c_water_top, 0
        else return planet.c_water, 0 end
    end

    --if we've passed all those checks, it must be air
    return c_air, 0
end

local data, param2_data = {}, {}
local min, abs = math.min, math.abs

minetest.register_on_generated(function(_, minp, maxp)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

	vm:get_data(data)
	vm:get_param2_data(param2_data)

    local sl = maxp.y-minp.y+1
    local size2d = {x=sl, y=sl, z=1}
    local size3d = {x=sl, y=sl, z=sl}
    local minp2d = {x=minp.x, y=minp.z}

    --figure out what planet we're on
    local y_planets = {}
    for y = minp.y, maxp.y do
        local i = get_planet_index(y)
        y_planets[y] = {i, planets[i]}
    end

    --get noise values
    for _, defs in pairs(noises2d) do
        if maxp.y >= defs.y_min and minp.y <= defs.y_max then
            defs.map = defs.map or minetest.get_perlin_map(defs.noise_params, size2d)
            defs.map:get_2d_map_flat(minp2d, defs.data)
        end
    end
    for _, defs in pairs(noises3d) do
        if maxp.y >= defs.y_min and minp.y <= defs.y_max then
            defs.map = defs.map or minetest.get_perlin_map(defs.noise_params, size3d)
            defs.map:get_3d_map_flat(minp, defs.data)
        end
    end

    --first pass: the actual terrain
    for y = minp.y, maxp.y do
        local index, planet = unpack(y_planets[y])
        local rely = (y-500)%1000-500

        --make sure out-of-bounds areas are void and bedrock
        if not index or rely >= 250 then
            for x = minp.x, maxp.x do for z = minp.z, maxp.z do
                data[area:index(x, y, z)] = c_void
            end end
        elseif rely == -500 then
            for x = minp.x, maxp.x do for z = minp.z, maxp.z do
                data[area:index(x, y, z)] = c_bedrock
            end end
        else

            --prepare the noises
            local planet_noise = noises2d["planet"..index]
            local river_noise = noises2d["river"..index]
            local cave_noise1 = noises3d["cave1_"..index]
            local cave_noise2 = noises3d["cave2_"..index]

            for z = minp.z, maxp.z do
                local vi = area:index(minp.x, y, z)
                local ni = sl*(z-minp.z)+1
                local ni3d = sl*sl*(z-minp.z)+sl*(y-minp.y)+1
                for x = minp.x, maxp.x do

                    --take care of stuff overlapping from previously generated chunks
                    local cur = data[vi]
                    if cur and cur ~= c_air then
                        param2_data[vi] = planet.param2_trees and planet.param2_trees[cur] or param2_data[vi]
                    else

                        --calculate it from noises and stuff
                        local planet_val = planet_noise.data[ni]
                        if planet.water_level then
                            planet_val = min(planet_val, river_noise.data[ni]^2+planet.river_level)
                        end
                        local cave_val = cave_noise1 and abs(cave_noise1.data[ni3d])+abs(cave_noise2.data[ni3d]) < 1
                        data[vi], param2_data[vi] = logic(planet_val, cave_val, planet, y)
                    end

                    --increment stuff
                    vi = vi+1
                    ni = ni+1
                    ni3d = ni3d+1
                end
            end
        end
    end

    vm:set_data(data)
    vm:set_param2_data(param2_data)
    minetest.generate_ores(vm)
	minetest.generate_decorations(vm)
    vm:get_param2_data(param2_data)

    --second pass: make sure trees generated by lsystems have the correct colors
    for y = minp.y, maxp.y do
        local index, planet = unpack(y_planets[y])
        if planet and planet.param2_trees then
            for x = minp.x, maxp.x do for z = minp.z, maxp.z do
                local vi = area:index(x, y, z)
                local new_param2 = planet.param2_trees[data[vi]]
                if new_param2 then param2_data[vi] = new_param2 end
            end end
        end
    end

    vm:set_param2_data(param2_data)
    vm:calc_lighting()
    vm:update_liquids()
end)