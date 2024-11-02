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

--Get a param2 that's somewhere nearby another one
local function get_nearby_param2(rand, param2, dist)
    dist = dist or 4
    local x, y = (param2-1)%16, math.ceil(param2/16)-1
    x = (x+rand:next(-dist, dist))%16
    y = math.min(math.max(y+rand:next(-dist, dist), 0), 15)
    return y*16+x+1
end

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
        planet.life_stat = prand:next(0, 2)

        --specifics of terrain
        local level = stellua.get_planet_level(i)
        planet.level = level
        planet.mapgen_stone = "stl_core:stone"..prand:next(1, 8)
        planet.c_stone = minetest.get_content_id(planet.mapgen_stone)
        planet.param2_stone = prand:next(0, 255)
        planet.mapgen_filler = "stl_core:filler"..prand:next(1, 8)
        planet.c_filler = minetest.get_content_id(planet.mapgen_filler)
        planet.param2_filler = get_nearby_param2(prand, planet.param2_stone)
        planet.depth_filler = planet.life_stat+prand:next(0, 1)

        --foliage
        if planet.life_stat > 0 then
            planet.fill_ratio = (planet.life_stat-1)*0.3+prand:next(1, 12)*0.02
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