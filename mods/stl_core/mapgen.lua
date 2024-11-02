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
        planet.heat_stat = prand:next(100, 300)+prand:next(0, 200) --temperature in Kelvin
        planet.atmo_stat = prand:next(0, 300)*0.01 --atmospheric pressure in atmospheres
        planet.life_stat = planet.heat_stat <= 400 and planet.heat_stat >= 200 and planet.atmo_stat > 0.5 and prand:next(1, 2) or 0

        --sky stuffs
        local alpha = math.min(planet.atmo_stat, 1)
        local fog = planet.atmo_stat*0.33333
        local fog_dist = 200-fog*180
        local r, g = prand:next(0, 255), prand:next(0, 255)
        local col = SKY_COL*alpha*(1-fog)+vector.new(r, g, math.min(512-r-g, 255))*fog
        planet.sky = {
            type = "plain",
            base_color = {r=col.x, g=col.y, b=col.z},
            fog = {fog_distance=fog_dist, fog_start=math.max(1-50/fog_dist, 0)}
        }
        planet.sun = {sunrise = "sunrisebg.png^[opacity:"..(alpha*255)}
        planet.stars = {day_opacity=1-alpha}

        --specifics of terrain
        local level = stellua.get_planet_level(i)
        planet.level = level
        planet.mapgen_stone = "stl_core:stone"..prand:next(1, 8)
        planet.c_stone = minetest.get_content_id(planet.mapgen_stone)
        planet.param2_stone = get_heat_param2(prand, planet.heat_stat)
        planet.mapgen_filler = "stl_core:filler"..prand:next(1, 8)
        planet.c_filler = minetest.get_content_id(planet.mapgen_filler)
        planet.param2_filler = get_nearby_param2(prand, planet.param2_stone)
        planet.depth_filler = planet.life_stat+prand:next(0, 1)

        --foliage
        if planet.life_stat > 0 then
            planet.fill_ratio = (planet.life_stat-1)*0.3+prand:next(1, 12)*0.05
            local param2_grass = get_nearby_param2(prand, planet.param2_filler)
            minetest.register_decoration({
                deco_type = "simple",
                place_on = {planet.mapgen_stone, planet.mapgen_filler},
                fill_ratio = planet.fill_ratio,
                y_min = level-500,
                y_max = level+499,
                decoration = "stl_core:grass"..prand:next(1, 8),
                param2 = param2_grass
            })
            minetest.register_decoration({
                deco_type = "simple",
                place_on = {planet.mapgen_stone, planet.mapgen_filler},
                fill_ratio = planet.fill_ratio*prand:next(1, 10)*0.1,
                y_min = level-500,
                y_max = level+499,
                decoration = "stl_core:grass"..prand:next(1, 8),
                param2 = get_nearby_param2(prand, param2_grass, 2)
            })
        end

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
    end
end

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
    if height < -planet.depth_filler then return planet.c_stone, planet.param2_stone
    elseif height < 0 then return planet.c_filler, planet.param2_filler end
    return c_air, 0
end

--Show player planet sky
minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local index = get_planet_index(player:get_pos().y)
        if not index then
            player:set_sky({
                type = "plain",
                base_color = "#000000"
            })
            player:set_sun({sunrise_visible=false})
            player:set_stars({day_opacity=1})
        else
            local planet = planets[index]
            player:set_sky(planet.sky)
            player:set_sun(planet.sun)
            player:set_stars(planet.stars)
            --minetest.log(planet.sky.fog.fog_start)
        end
    end
end)