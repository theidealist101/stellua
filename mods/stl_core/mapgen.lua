--Partition the world into sixty randomised planets, plus however many ships and space stations fit in the gap
--Generate random attributes for each planet, fulfilling a quota
--Must also keep track of player properties and set them accordingly

--Remember what the planet stuff was so we don't have to calculate it again
local storage = minetest.get_mod_storage()
local planets = minetest.deserialize(storage:get("planets")) or {}
stellua.planets = planets

local function save_planets()
    storage:set_string("planets", minetest.serialize(planets))
end

--Choose a certain number of items from a range randomly
local function choices(rand, n, a, b)
    if not b then a, b = 1, a end
    local range = {}
    for i = a, b do table.insert(range, i) end
    local out = {}
    for _ in 1, n do table.insert(out, table.remove(range, rand:next(1, #range))) end
    return out
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
    local minx = heat <= 300 and 0 or math.round(luamap.remap(heat, 300, 500, 0, 7))
    local maxx = heat >= 300 and 15 or math.round(luamap.remap(heat, 100, 300, 15, 8))
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

local SKY_COL = vector.new(97, 181, 245)

--Set up planets and attributes on first load
minetest.register_on_mods_loaded(function()
    if not next(planets) then
        local rand = PcgRandom(minetest.get_mapgen_setting("seed"))
        for i = 1, 60 do

            --some basics
            local seed = rand:next()
            local prand = PcgRandom(seed)
            local planet = {}
            table.insert(planets, planet)
            planet.name = stellua.generate_name(prand, "star")
            planet.seed = seed
            local level = stellua.get_planet_level(i)
            planet.level = level
            planet.heat_stat = prand:next(100, 300)+prand:next(0, 200) --temperature in Kelvin
            planet.atmo_stat = prand:next(0, 300)*0.01 --atmospheric pressure in atmospheres
            planet.life_stat = planet.heat_stat <= 400 and planet.heat_stat >= 200 and planet.atmo_stat > 0.5 and prand:next(1, 2) or 0

            --sky stuffs
            local alpha = math.min(planet.atmo_stat, 1)
            local fog = (planet.atmo_stat*0.33333)^2
            local fog_dist = 250-fog*180
            local fog_table = {fog_distance=fog_dist, fog_start=math.max(1-50/fog_dist, 0)}
            local r, g = prand:next(0, 400), prand:next(0, 400) --bit more likely to be yellow rather than blue
            local col = SKY_COL*alpha*(1-fog)+vector.new(math.min(r, 255), math.min(g, 255), math.min(512-r-g, 255))*fog
            function planet.sky(timeofday)
                local newcol = col*math.min(math.max(luamap.remap(timeofday < 0.5 and timeofday or 1-timeofday, 0.19, 0.23, 0.2, 1), 0.2), 1)
                return {
                    type = "plain",
                    base_color = {r=newcol.x, g=newcol.y, b=newcol.z},
                    fog = fog_table,
                    clouds = false --clouds are currently bugged
                }
            end
            planet.stars = {day_opacity=1-alpha}

            --noise maps
            local scale = prand:next(100, 200)*0.01
            local spread = math.round(prand:next(100, 200)*scale)
            luamap.register_noise("planet"..i, {
                type = "2d",
                ymin = level-500,
                ymax = level+499,
                np_vals = {
                    offset = level,
                    scale = 10^scale,
                    spread = {x=spread, y=spread, z=spread},
                    seed = seed,
                    octaves = math.round(3+scale),
                    persistence = 0.5,
                    lacunarity = 2
                }
            })

            --specifics of terrain
            planet.mapgen_stone = "stl_core:stone"..prand:next(1, 8)
            planet.c_stone = minetest.get_content_id(planet.mapgen_stone)
            planet.param2_stone = get_heat_param2(prand, planet.heat_stat)

            local a, b, c = prand:next(1, 8)
            planet.mapgen_filler = "stl_core:filler"..a
            planet.c_filler = minetest.get_content_id(planet.mapgen_filler)
            planet.param2_filler = get_nearby_param2(prand, planet.param2_stone)
            planet.depth_filler = planet.life_stat+prand:next(0, 1)

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
                    planet.depth_seabed = math.max(planet.life_stat+prand:next(-1, 0), 0)

                    repeat c = prand:next(1, 8) until a ~= c and b ~= c
                    planet.mapgen_beach = "stl_core:filler"..c
                    planet.c_beach = minetest.get_content_id(planet.mapgen_beach)
                    planet.param2_beach = get_nearby_param2(prand, planet.param2_stone-32, 2)
                    planet.depth_beach = planet.life_stat

                    if planet.heat_stat <= defs.melt_point and defs.frozen_tiles then
                        planet.mapgen_water_top = water.."_frozen"
                        planet.c_water_top = minetest.get_content_id(planet.mapgen_water_top)
                        planet.depth_water_top = math.ceil((defs.melt_point-planet.heat_stat+1)*0.1)
                        planet.water_name = planet.water_name.." Ice"

                        if defs.snow then
                            local snow_defs = minetest.registered_nodes[defs.snow]
                            minetest.register_decoration({
                                deco_type = "simple",
                                place_on = {planet.mapgen_stone, planet.mapgen_filler, planet.mapgen_beach},
                                fill_ratio = math.min(snow_defs.melt_point-planet.heat_stat+1, planet.heat_stat-snow_defs.start_point+1)*0.05,
                                y_min = level-500,
                                y_max = level+499,
                                decoration = defs.snow,
                                param2 = 8,
                                param2_max = 16
                            })
                        end
                    end
                end
            end

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

            if planet.atmo_stat >= 0.5 and #snow_options > 0 then
                local snow, defs = unpack(snow_options[prand:next(1, #snow_options)])
                if snow ~= 0 then
                    minetest.register_decoration({
                        deco_type = "simple",
                        place_on = {planet.mapgen_stone, planet.mapgen_filler, planet.mapgen_beach},
                        fill_ratio = math.min(defs.melt_point-planet.heat_stat+1, planet.heat_stat-defs.start_point+1)*0.05,
                        y_min = level-500,
                        y_max = level+499,
                        decoration = snow,
                        param2 = 8,
                        param2_max = 16
                    })
                end
            end

            --foliage
            if planet.life_stat > 0 then
                local fill_ratio = (planet.life_stat-1)*0.3+prand:next(1, 12)*0.005
                local param2_grass = get_nearby_param2(prand, planet.param2_filler)
                minetest.register_decoration({
                    deco_type = "simple",
                    place_on = {planet.mapgen_filler},
                    fill_ratio = fill_ratio,
                    y_min = level-500,
                    y_max = level+499,
                    decoration = "stl_core:grass"..prand:next(1, 8),
                    param2 = param2_grass
                })
                minetest.register_decoration({
                    deco_type = "simple",
                    place_on = {planet.mapgen_stone, planet.mapgen_filler},
                    fill_ratio = fill_ratio*prand:next(1, 10)*0.1,
                    y_min = level-500,
                    y_max = level+499,
                    decoration = "stl_core:grass"..prand:next(1, 8),
                    param2 = get_nearby_param2(prand, param2_grass, 2)
                })
            end
        end
    end
end)

--Make doubly sure we're in singlenode
luamap.set_singlenode()

--Some useful localisations for mapgen
local get_planet_index = stellua.get_planet_index
local c_air = minetest.CONTENT_AIR

--The actual mapgen
function luamap.logic(noises, x, y, z, seed)
    local index = get_planet_index(y)
    if not index then return c_air, 0 end
    local planet = planets[index]
    local noise = noises["planet"..index]
    local height = y-noise
    if planet.water_level then
        if noise <= planet.water_level-2 then
            if height < -planet.depth_seabed then return planet.c_stone, planet.param2_stone
            elseif height < 0 then return planet.c_seabed, planet.param2_seabed end
        elseif noise <= planet.water_level+4 then
            if height < -planet.depth_beach then return planet.c_stone, planet.param2_stone
            elseif height < 0 then return planet.c_beach, planet.param2_beach end
        end
    end
    if height < -planet.depth_filler then return planet.c_stone, planet.param2_stone
    elseif height < 0 then return planet.c_filler, planet.param2_filler end
    if planet.water_level and y-planet.water_level <= 0 then
        if planet.depth_water_top and y-planet.water_level > -planet.depth_water_top then return planet.c_water_top, 0
        else return planet.c_water, 0 end
    end
    return c_air, 0
end

--Show player planet sky
minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local index = get_planet_index(player:get_pos().y)
        if not index then
            player:set_sky({
                type = "plain",
                base_color = "#000000",
                clouds = false
            })
            player:set_sun({visible=false})
            player:set_stars({day_opacity=1})
        else
            local planet = planets[index]
            player:set_sky(planet.sky(minetest.get_timeofday()))
            player:set_sun({visible=true})
            player:set_stars(planet.stars)
            player:set_clouds({height=(planet.water_level or planet.level)+120})
        end
    end
end)

minetest.register_on_joinplayer(function(player)
    player:set_sun({sunrise_visible=false})
    player:set_moon({visible=false})
end)