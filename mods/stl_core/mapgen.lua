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

--Set up planets and attributes on first load
if not next(planets) then
    local rand = PcgRandom(minetest.get_mapgen_setting("seed"))
    for _ = 1, 60 do
        local seed = rand:next()
        local prand = PcgRandom(seed)
        local planet = {}
        table.insert(planets, planet)
        planet.name = stellua.generate_name(prand, "star")
        planet.seed = seed
    end
end

--Quickly convert actual coordinates to planet index and coordinates
function stellua.get_planet_index(pos)
    local index = math.round(pos.y*0.001)
    if index == 0 then return end
    index = index > 0 and index+30 or index+31
    if index < 1 or index > 60 then return end
    return index, vector.new(pos.x, pos.y%1000, pos.z)
end