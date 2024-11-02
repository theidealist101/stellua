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

        --specifics of terrain
        local level = stellua.get_planet_level(i)
        planet.level = level
        planet.mapgen_stone = "stl_core:stone"..prand:next(1, 8)
        planet.c_stone = minetest.get_content_id(planet.mapgen_stone)
        planet.param2_stone = prand:next(0, 255)

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
    if y <= noise then return planet.c_stone, planet.param2_stone end
    return c_air, 0
end