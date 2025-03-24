stl_moreplants = {}

--Register different locations to spawn decorations
stl_moreplants.registered_places = {}

function stl_moreplants.register_place(func)
    table.insert(stl_moreplants.registered_places, func)
end

--Register different varieties of decoration
stl_moreplants.registered_shapes = {}

function stl_moreplants.register_shape(func)
    table.insert(stl_moreplants.registered_shapes, func)
end

local items_in_group_cache = {}

--Get list of all items in group
function stl_moreplants.get_items_in_group(group)
    if items_in_group_cache[group] then return items_in_group_cache[group] end
    local out = {}
    for name, defs in pairs(minetest.registered_items) do
        if defs.groups and defs.groups[group] and defs.groups[group] > 0 then
            table.insert(out, name)
        end
    end
    items_in_group_cache[group] = out
    return out
end

--Concatenate table of flags into a string
local function concat_flags(flags)
    local out = {}
    for flag, b in pairs(flags) do
        if b then table.insert(out, flag) end
    end
    return table.concat(out, ", ")
end

--Give each planet a couple randomly chosen decorations
stellua.register_on_planet_generated(function (planet)
    local rand = PcgRandom(planet.seed)
    local count = 0
    for _ = 1, 100 do
        if count > planet.life_stat*8 then return end
        local place = stl_moreplants.registered_places[rand:next(1, #stl_moreplants.registered_places)](planet)
        if place then
            local shape = stl_moreplants.registered_shapes[rand:next(1, #stl_moreplants.registered_shapes)](planet, place)
            if shape then
                count = count+1
                while type(shape.decoration) == "table" do
                    shape.decoration = shape.decoration[rand:next(1, #shape.decoration)]
                end
                if shape.param2_rand then
                    shape.param2 = rand:next(0, 255)
                    shape.param2_max = 0
                end
                place.fill_spread = place.fill_spread or 100
                if minetest.get_item_group(shape.decoration, "cavetorch") > 0 then
                    planet.cavetorch = true
                end
                minetest.register_decoration({
                    deco_type = shape.deco_type or "simple",
                    noise_params = {
                        offset = place.fill_offset or 0,
                        scale = rand:next(20, 80)*0.025*(place.fill_ratio or 1)-(place.fill_offset or 0),
                        spread = {x=place.fill_spread, y=place.fill_spread, z=place.fill_spread},
                        octaves = 3,
                        persistence = 0.5,
                        lacunarity = 2,
                        seed = rand:next()
                    },
                    decoration = shape.decoration,
                    height = shape.height,
                    height_max = shape.height_max,
                    param2 = shape.param2,
                    param2_max = shape.param2_max,
                    schematic = shape.schematic,
                    replacements = shape.replacements,
                    rotation = shape.random_rotation and "random" or "0",
                    place_offset_y = (shape.place_offset_y or 0)+(place.place_offset_y or 0),
                    place_on = place.place_on,
                    y_min = place.y_min or planet.level-500,
                    y_max = place.y_max or planet.level+499,
                    spawn_by = place.spawn_by,
                    check_offset = place.check_offset,
                    num_spawn_by = place.num_spawn_by,
                    flags = concat_flags({
                        force_placement = shape.force_placement or place.force_placement,
                        place_center_x = shape.deco_type == "schematic",
                        place_center_z = shape.deco_type == "schematic",
                        liquid_surface = place.liquid_surface,
                        all_floors = place.all_floors,
                        all_ceilings = place.all_ceilings
                    })
                })
            end
        end
    end
end)

local old_is_spawn_suitable = stellua.is_spawn_suitable

function stellua.is_spawn_suitable(planet)
    return old_is_spawn_suitable(planet) and planet.cavetorch
end

--Register some types
local path = minetest.get_modpath("stl_moreplants").."/"
dofile(path.."nodes.lua")
dofile(path.."decors.lua")