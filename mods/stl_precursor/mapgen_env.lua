local modpath = minetest.get_modpath("stl_precursor").."/"

local stellua = minetest.ipc_get("stellua")
local planets, noises2d = stellua.planets, stellua.noises2d
local get_planet_index = stellua.get_planet_index
local get_name_from_content_id, get_item_group = minetest.get_name_from_content_id, minetest.get_item_group

local buildings = {
    {"precursor_assembler_room", -2},
    {"precursor_watchtower", -2},
    {"precursor_stilts_room", -2},
    {"precursor_basement", -10}
}

local decors = {
    {"precursor_small_shelter", -1},
    {"precursor_small_totem", 0},
    {"precursor_small_altar", -1},
    {"precursor_small_lamp", 0},
    {"precursor_small_sign", 0},
    {"precursor_small_plinth", -1},
    {"precursor_small_assembler_room", -1},
    {"precursor_small_fake_basement", -1}
}

local spots = {
    {"precursor_small_turret", 0},
    {"precursor_small_node", 0},
}

local data = {}
local min, round, hypot = math.min, math.round, math.hypot

local function place_schem(schem, vm, area, pos, offset, miny, maxy)
    pos.y = round(pos.y)
    vm:get_data(data)

    --move up and down till we find a valid position
    local vi = area:index(pos.x, pos.y, pos.z)
    while pos.y <= maxy and get_item_group(get_name_from_content_id(data[vi]), "ground") > 0 do
        pos.y = pos.y+1
        vi = area:index(pos.x, pos.y, pos.z)
    end
    if pos.y > maxy then return false end
    while pos.y >= miny and get_item_group(get_name_from_content_id(data[vi]), "ground") == 0 do
        pos.y = pos.y-1
        vi = area:index(pos.x, pos.y, pos.z)
    end
    if pos.y < miny then return false end

    --actually place it
    pos.y = pos.y+offset+1
    return minetest.place_schematic_on_vmanip(
        vm,
        pos,
        modpath.."schems/"..schem..".mts",
        "random",
        {},
        true,
        "place_center_x, place_center_z"
    )
end

local function choose_pos(poses, rand, origin_x, origin_z)
    local pos
    for _ = 1, 8 do
        pos = {rand:next(origin_x-16, origin_x+16), rand:next(origin_z-16, origin_z+16)}
        local valid = true
        for _, p in ipairs(poses) do
            if hypot(pos[1]-p[1], pos[2]-p[2]) < 8 then valid = false end
        end
        if valid then
            table.insert(poses, pos)
            break
        end
    end
    return pos
end

minetest.register_on_generated(function(_, minp, maxp)
    local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}

    local sl = maxp.y-minp.y+1
    local size2d = {x=sl, y=sl, z=1}
    local minp2d = {x=minp.x, y=minp.z}

    --figure out what planet we're on
    local index = get_planet_index(minp.y)
    local planet = planets[index]

    --see if there ought to be a precursor outpost in this column of chunks
    local rand = PcgRandom(planet.seed*maxp.x+maxp.z)
    if rand:next(1, 2) ~= 1 then return end

    --pick the position of the origin
    local origin_x, origin_z = rand:next(minp.x+16, maxp.x-16), rand:next(minp.z+16, maxp.z-16)
    local ni = sl*(origin_z-minp.z)+(origin_x-minp.z)+1

    --get the height of whichever planet we're on and see if we're at the surface
    local planet_noise = noises2d["planet"..index]
    local river_noise = noises2d["river"..index]
    for _, defs in ipairs({planet_noise, river_noise}) do
        defs.map = defs.map or minetest.get_perlin_map(defs.noise_params, size2d)
        defs.map:get_2d_map_flat(minp2d, defs.data)
    end
    local planet_val = planet_noise.data[ni]
    if not planet_val then return end --dunno why this is happening but yeah
    if planet.water_level then
        planet_val = min(planet_val, river_noise.data[ni]^2+planet.river_level)
    end
    if minp.y > planet_val or maxp.y < planet_val or planet.water_level and planet_val < planet.water_level then return end

    --spawn a large building directly on the origin
    local building = buildings[rand:next(1, #buildings)]
    if not place_schem(building[1], vm, area, vector.new(origin_x, planet_val, origin_z), building[2], minp.y, maxp.y) then return end

    --spawn small buildings around it
    local poses = {{origin_x, origin_z}}
    for _ = 1, rand:next(3, 5) do
        local pos = choose_pos(poses, rand, origin_x, origin_z)
        if pos then
            local decor = decors[rand:next(1, #decors)]
            place_schem(decor[1], vm, area, vector.new(pos[1], planet_val, pos[2]), decor[2], minp.y, maxp.y)
        end
    end

    --spawn turrets and light nodes, which are much more common and fill in the gaps
    for _ = 1, rand:next(5, 8) do
        local pos = choose_pos(poses, rand, origin_x, origin_z)
        if pos then
            local decor = spots[rand:next(1, #spots)]
            place_schem(decor[1], vm, area, vector.new(pos[1], planet_val, pos[2]), decor[2], minp.y, maxp.y)
        end
    end

    vm:calc_lighting()
end)