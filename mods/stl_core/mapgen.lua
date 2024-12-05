--Partition the world into sixty randomised planets, plus however many ships and space stations fit in the gap
--Generate random attributes for each planet, fulfilling a quota
--Must also keep track of player properties and set them accordingly

--Remember what the planet stuff was so we don't have to calculate it again
local planets = {}
stellua.planets = planets
local stars = {}
stellua.stars = stars

--Choose a certain number of items from a range randomly
local function choices(rand, n, a, b)
    if not b then a, b = 1, a end
    local range = {}
    for i = a, b do table.insert(range, i) end
    local out = {}
    for _ in 1, n do table.insert(out, table.remove(range, rand:next(1, #range))) end
    return out
end

--Since I need pseudo-random
function stellua.random_direction(rand)
	-- Generate a random direction of unit length, via rejection sampling
	local x, y, z, l2
	repeat -- expected less than two attempts on average (volume sphere vs. cube)
		x, y, z = rand:next(0, 99999)*0.00001 * 2 - 1, rand:next(0, 99999)*0.00001 * 2 - 1, rand:next(0, 99999)*0.00001 * 2 - 1
        l2 = x*x + y*y + z*z
	until l2 <= 1 and l2 >= 1e-6
	-- normalize
	local l = math.sqrt(l2)
	return vector.new(x/l, y/l, z/l)
end

--Quickly convert actual position to planet index and coordinates
function stellua.get_planet_index(y)
    local index = math.round(y*0.001)
    if index == 0 then return end
    index = index > 0 and index+30 or index+31
    if index < 1 or index > 60 then return end
    return index
end

function stellua.get_relative_pos(pos)
    return vector.new(pos.x, pos.y%1000, pos.z)
end

--Quickly convert planet index to y level
function stellua.get_planet_level(index)
    index = index > 30 and index-30 or index-31
    return index*1000
end

--Get param2 in range depending on heat stat
local function get_heat_param2(rand, heat)
    local y = rand:next(0, 15)
    local minx = heat <= 300 and 0 or math.round(stellua.remap(heat, 300, 500, 0, 7))
    local maxx = heat >= 300 and 15 or math.round(stellua.remap(heat, 100, 300, 15, 8))
    return y*16+rand:next(minx, maxx)
end

--Get a param2 that's somewhere nearby another one
local function get_nearby_param2(rand, param2, dist)
    dist = dist or 4
    local x, y = param2%16, math.floor(param2/16)
    x = (x+rand:next(-dist, dist))%16
    y = math.min(math.max(y+rand:next(-dist, dist), 0), 15)
    return y*16+x
end

--Register noise functions
stellua.noises2d, stellua.noises3d = {}, {}

local function register_noise2d(name, defs)
    defs.y_min = defs.y_min or -31000
    defs.y_max = defs.y_max or 31000
    defs.data = {}
    stellua.noises2d[name] = defs
end

local function register_noise3d(name, defs)
    defs.y_min = defs.y_min or -31000
    defs.y_max = defs.y_max or 31000
    defs.data = {}
    stellua.noises3d[name] = defs
end

local SKY_COL = vector.new(97, 181, 245)

local ORES_COMMON = {"copper", "titanium"}

--Set up planets and attributes on first load
minetest.register_on_mods_loaded(function()
    local rand = PcgRandom(minetest.get_mapgen_setting("seed"))

    for i = 1, 16 do
        local seed = rand:next()
        local prand = PcgRandom(seed)
        local star = {}
        table.insert(stars, star)
        star.name = stellua.generate_name(prand, "star")
        star.seed = seed
        star.scale = 10^(prand:next(-10, 10)*0.02)
        star.planets = {}
        star.pos = vector.new(prand:next(-100, 100), prand:next(-100, 100), prand:next(-100, 100))*0.02 --parsecs
    end

    for i = 1, 60 do

        --some basics
        local seed = rand:next()
        local prand = PcgRandom(seed)
        local planet = {}
        table.insert(planets, planet)
        planet.star = prand:next(1, #stars)
        local star = stars[planet.star]
        table.insert(star.planets, i)
        planet.name = star.name.." "..stellua.roman_numeral(#star.planets)
        planet.seed = seed
        local level = stellua.get_planet_level(i)
        planet.level = level
        planet.heat_stat = prand:next(100, 300)+prand:next(0, 200) --temperature in Kelvin
        planet.atmo_stat = prand:next(0, 300)*0.01 --atmospheric pressure in atmospheres
        planet.life_stat = planet.heat_stat <= 400 and planet.heat_stat >= 200 and planet.atmo_stat > 0.5 and prand:next(1, 200)*0.01 or 0
        local e = (planet.atmo_stat/3)^0.225
        planet.dist = 127300*(1-e/2)/planet.heat_stat^2 --no idea what this does but it feels realistic enough
        planet.pos = stellua.random_direction(prand)*planet.dist

        --sky stuffs
        local alpha = math.min(planet.atmo_stat, 1)
        local fog = planet.atmo_stat*0.33333
        local fog_dist = math.min(250-fog*180, 200)
        planet.fog_dist = fog_dist
        local b = stellua.remap(planet.heat_stat, 100, 500, 255, 0)
        local total = prand:next(255, 384)-b
        local r = prand:next(0, total)
        local col = SKY_COL*alpha*(1-fog)+vector.new(math.min(r, 255), math.min(total-r, 255), b)*fog
        planet.sun = {visible=true, scale=star.scale/planet.dist}

        function planet.sky(timeofday, height)
            local newcol = col*height*math.min(math.max(stellua.remap(timeofday < 0.5 and timeofday or 1-timeofday, 0.19, 0.23, 0.2, 1), 0.2), 1)
            local fdist = math.min(250-fog*180*height, 200)
            return {
                type = "plain",
                base_color = {r=newcol.x, g=newcol.y, b=newcol.z},
                fog = {fog_distance=fdist, fog_start=math.max(1-50/fdist, 0)},
                clouds = false --clouds are currently bugged
            }
        end

        function planet.stars(height)
            return {day_opacity=1-alpha*height}
        end

        --noise maps
        local scale = prand:next(100, 200)*0.01
        planet.scale = (planet.atmo_stat+1)*scale*0.25
        planet.gravity = planet.scale^1.5
        planet.walk_speed = math.min(1/planet.gravity, 1)
        local spread = math.round(prand:next(100, 200)*scale)

        register_noise2d("planet"..i, {
            y_min = level-500,
            y_max = level+499,
            noise_params = {
                offset = level,
                scale = 10^scale,
                spread = {x=spread, y=spread, z=spread},
                seed = seed,
                octaves = math.round(3+scale),
                persistence = 0.5,
                lacunarity = 2
            }
        })

        for j = 1, 2 do
            register_noise3d("cave"..j.."_"..i, {
                y_min = level-500,
                y_max = level+499,
                noise_params = {
                    offset = 0,
                    scale = 1,
                    spread = {x=spread*0.3, y=spread*0.3, z=spread*0.3},
                    seed = seed+j,
                    octaves = 3,
                    persistence = 0.5,
                    lacunarity = 2
                }
            })
        end

        --specifics of terrain
        planet.mapgen_stone = "stl_core:stone"..prand:next(1, 8)
        planet.c_stone = minetest.get_content_id(planet.mapgen_stone)
        planet.param2_stone = get_heat_param2(prand, planet.heat_stat)

        local a, b, c = prand:next(1, 8)
        planet.mapgen_filler = "stl_core:filler"..a
        planet.c_filler = minetest.get_content_id(planet.mapgen_filler)
        planet.param2_filler = get_nearby_param2(prand, planet.param2_stone)
        planet.depth_filler = math.ceil(planet.life_stat+prand:next(-50, 100)*0.01)

        local water_options = {}
        for _ = 1, 10 do table.insert(water_options, {0, 0}) end
        for _, val in pairs(stellua.registered_waters) do
            local name, defs = unpack(val)
            if planet.heat_stat < defs.boil_point and (defs.frozen_tiles or planet.heat_stat > defs.melt_point) then
                for _ = 1, (defs.weight or 1)*10 do
                    table.insert(water_options, {name, defs})
                end
            end
        end

        if planet.atmo_stat >= 0.5 and #water_options > 0 then
            local water, defs = unpack(water_options[prand:next(1, #water_options)])
            if water ~= 0 then
                planet.water_level = level+prand:next(math.round(-0.5*10^scale), math.round(0.5*10^scale))

                planet.mapgen_water = water.."_source"
                planet.c_water = minetest.get_content_id(planet.mapgen_water)
                planet.water_name = defs.description

                repeat b = prand:next(1, 8) until a ~= b
                planet.mapgen_seabed = "stl_core:filler"..b
                planet.c_seabed = minetest.get_content_id(planet.mapgen_seabed)
                planet.param2_seabed = get_nearby_param2(prand, planet.param2_stone)
                planet.depth_seabed = math.ceil(planet.life_stat+prand:next(-100, 0)*0.01)

                repeat c = prand:next(1, 8) until a ~= c and b ~= c
                planet.mapgen_beach = "stl_core:filler"..c
                planet.c_beach = minetest.get_content_id(planet.mapgen_beach)
                planet.param2_beach = get_nearby_param2(prand, planet.param2_stone-32, 2)
                planet.depth_beach = math.ceil(planet.life_stat+prand:next(-50, 50)*0.01)

                if planet.heat_stat <= defs.melt_point and defs.frozen_tiles then
                    planet.mapgen_water_top = water.."_frozen"
                    planet.c_water_top = minetest.get_content_id(planet.mapgen_water_top)
                    planet.depth_water_top = math.ceil((defs.melt_point-planet.heat_stat+1)*0.1)
                    planet.water_name = planet.water_name.." Ice"

                    if defs.snow then
                        local snow_defs = minetest.registered_nodes[defs.snow]
                        planet.snow_type1 = defs.snow
                        minetest.register_decoration({
                            deco_type = "simple",
                            place_on = {planet.mapgen_stone, planet.mapgen_filler, planet.mapgen_beach},
                            fill_ratio = math.min(snow_defs.melt_point-planet.heat_stat+1, planet.heat_stat-snow_defs.start_point+1)*0.01+0.5,
                            y_min = planet.water_level,
                            y_max = level+499,
                            decoration = defs.snow,
                            param2 = 8,
                            param2_max = 16
                        })
                    end
                end

                if prand:next(0, 2) > 0 then
                    planet.quartz = "stl_core:quartz"..prand:next(1, 5)
                    minetest.register_decoration({
                        deco_type = "simple",
                        place_on = {planet.mapgen_stone, planet.mapgen_seabed, planet.mapgen_beach, planet.mapgen_filler},
                        y_min = level-99,
                        y_max = planet.water_level-8,
                        flags = "force_placement",
                        noise_params = {
                            offset = -0.3,
                            scale = 0.5,
                            spread = {x=100, y=100, z=100},
                            seed = prand:next(),
                            octaves = 3,
                            persistence = 0.5,
                            lacunarity = 2.0,
                        },
                        decoration = planet.quartz,
                        height = 1,
                        height_max = 6
                    })
                end
            end
        end

        local cutoff = planet.water_level or level-99

        --foliage
        if planet.life_stat > 0 then
            local fill_ratio = planet.life_stat*0.2+prand:next(1, 12)*0.005
            local param2_grass = get_nearby_param2(prand, planet.param2_filler)
            planet.param2_trees = {}
            for _ = 1, math.floor(planet.life_stat*8-4) do
                local treedef = stellua.make_treedef(prand)
                local s = spread*prand:next(1, 10)*0.2
                minetest.register_decoration({
                    deco_type = "lsystem",
                    place_on = {planet.mapgen_filler},
                    y_min = cutoff,
                    y_max = level+499,
                    treedef = treedef,
                    noise_params = {
                        offset = 0,
                        scale = prand:next(1, 50)*0.001*fill_ratio,
                        spread = {x=s, y=s, z=s},
                        seed = prand:next(),
                        octaves = 3,
                        persistence = 0.5,
                        lacunarity = 2.0,
                    },
                })
                local p = get_nearby_param2(prand, param2_grass)
                planet.param2_trees[minetest.get_content_id(treedef.trunk)] = p
                planet.param2_trees[minetest.get_content_id(treedef.leaves)] = get_nearby_param2(prand, p, 2)
            end
            minetest.register_decoration({
                deco_type = "simple",
                place_on = {planet.mapgen_filler},
                fill_ratio = fill_ratio,
                y_min = cutoff,
                y_max = level+499,
                decoration = "stl_core:grass"..prand:next(1, 8),
                param2 = param2_grass
            })
            minetest.register_decoration({
                deco_type = "simple",
                place_on = {planet.mapgen_stone, planet.mapgen_filler, planet.mapgen_beach},
                fill_ratio = fill_ratio*prand:next(1, 10)*0.1,
                y_min = cutoff,
                y_max = level+499,
                decoration = "stl_core:grass"..prand:next(1, 8),
                param2 = get_nearby_param2(prand, param2_grass, 2)
            })
            if planet.life_stat > 0.5 then
                minetest.register_decoration({
                    deco_type = "simple",
                    place_on = {planet.mapgen_stone, planet.mapgen_filler, planet.mapgen_beach},
                    fill_ratio = fill_ratio*prand:next(1, 10)*0.1,
                    y_min = cutoff,
                    y_max = level+499,
                    decoration = "stl_core:shrub"..prand:next(1, 4),
                    param2 = get_nearby_param2(prand, param2_grass)
                })
            end
            if planet.life_stat > 1.5 then
                minetest.register_decoration({
                    deco_type = "simple",
                    place_on = {planet.mapgen_filler},
                    fill_ratio = (planet.life_stat-1)*0.4+prand:next(1, 20)*0.1,
                    y_min = cutoff,
                    y_max = level+499,
                    decoration = "stl_core:moss"..prand:next(1, 4),
                    param2 = get_nearby_param2(prand, param2_grass)
                })
            end
        end

        if planet.life_stat < 1 then
            minetest.register_decoration({
                deco_type = "simple",
                place_on = {planet.mapgen_stone, planet.mapgen_filler, planet.mapgen_beach},
                fill_ratio = (1-planet.life_stat)*0.01+prand:next(1, 20)*0.002,
                y_min = level-500,
                y_max = level+499,
                decoration = "stl_core:gravel",
                param2 = get_nearby_param2(prand, planet.param2_stone-32, 2)
            })
        end

        --snow
        local snow_options = {{0, 0}}
        for _ = 1, 20 do table.insert(snow_options, {0, 0}) end
        for _, val in pairs(stellua.registered_snows) do
            local name, defs = unpack(val)
            if planet.heat_stat < defs.melt_point and planet.heat_stat > defs.start_point then
                for _ = 1, (defs.weight or 1)*10 do
                    table.insert(snow_options, {name, defs})
                end
            end
        end

        if #snow_options > 0 then
            local snow, defs = unpack(snow_options[prand:next(1, #snow_options)])
            if snow ~= 0 then
                planet.snow_type2 = snow
                minetest.register_decoration({
                    deco_type = "simple",
                    place_on = {planet.mapgen_stone, planet.mapgen_filler, planet.mapgen_beach},
                    fill_ratio = math.min(defs.melt_point-planet.heat_stat+1, planet.heat_stat-defs.start_point+1)*0.01+0.5,
                    y_min = cutoff,
                    y_max = level+499,
                    decoration = snow,
                    param2 = 8,
                    param2_max = 16
                })
            end
        end

        --ores
        planet.ore_common = ORES_COMMON[prand:next(1, #ORES_COMMON)]
        local count_common = prand:next(16, 32)

        minetest.register_ore({
            ore_type = "blob",
            ore = planet.mapgen_stone.."_with_"..planet.ore_common,
            ore_param2 = planet.param2_stone,
            wherein = {planet.mapgen_stone},
            clust_scarcity = prand:next(8, 16)^3,
            clust_num = count_common,
            clust_size = math.ceil(math.sqrt(count_common))*2,
            y_min = level-500,
            y_max = level+499,
            noise_params = {
                offset = 0,
                scale = 0.5,
                spread = {x=10, y=10, z=10},
                seed = planet.seed,
                octaves = 3
            }
        })

        --the funny icon on maps or in the sky
        local turn_to_dimensions = function(param2) return (param2%16)..","..math.floor(param2/16) end
        planet.icon = table.concat({
            "(palette.png^[sheet:16x16:"..turn_to_dimensions(planet.depth_filler == 0 and planet.param2_stone or planet.param2_filler).."^[hardlight:skybox_planet_land"..prand:next(1, 4)..".png)",
            planet.water_level and "^(skybox_planet_water.png^[multiply:"..minetest.colorspec_to_colorstring(planet.mapgen_water_top and {r=224, g=224, b=255} or minetest.registered_nodes[planet.mapgen_water].post_effect_color).."^[mask:skybox_planet_continent"..prand:next(1, 4)..".png)" or "",
            "^(skybox_planet_atmosphere.png^[colorize:"..minetest.colorspec_to_colorstring({r=col.x, g=col.y, b=col.z})..":alpha^[opacity:"..(alpha*255)..")"
        })
    end

    --pass it all to the mapgen env
    minetest.ipc_set("stellua", stellua)
end)

--Make doubly sure we're in singlenode (this is also from Luamap)
minetest.register_on_mapgen_init(function()
    minetest.set_mapgen_params({mgname="singlenode"})
end)

minetest.register_abm({
    interval = 1,
    chance = 1,
    nodenames = {"group:tree"},
    action = function (pos, node)
        if node.param2 ~= 0 then return end
        local index = stellua.get_planet_index(pos.y)
        if not index then return end
        node.param2 = planets[index].param2_trees[minetest.get_content_id(node.name)]
        minetest.swap_node(pos, node)
    end
})