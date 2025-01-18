--Remember each planet's current weather in mod storage
local storage = minetest.get_mod_storage()
local weather = minetest.deserialize(storage:get_string("weather")) or {}

--Register weather type
stellua.registered_weathers = {}

function stellua.register_weather(name, defs)
    defs.cond = defs.cond or function() return false end
    stellua.registered_weathers[name] = defs
end

--Set up the types of weather for each planet
stellua.register_on_planet_generated(function (planet)
    planet.weathers = {}
    for name, defs in pairs(stellua.registered_weathers) do
        if defs.cond(planet) then
            table.insert(planet.weathers, name)
        end
    end
end)

--Do the particles and stuff each globalstep
minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        local _, w = next(stellua.planets[stellua.get_planet_index(pos.y)].weathers)
        if w then
            local pdefs = stellua.registered_weathers[w].particles(pos)
            pdefs.playername = player:get_player_name()
            minetest.add_particlespawner(pdefs)
        end
    end
end)

--Precipitation
for _, val in pairs(stellua.registered_waters) do
    local name, defs = unpack(val)
    stellua.register_weather(name.."_rain", {
        cond = function (planet)
            return planet.mapgen_water == name.."_source"
        end,
        temp = function (planet)
            return (planet.heat_stat*3+defs.temp)*0.25-5
        end,
        particles = function (pos)
            local exptime = 2
            if minetest.registered_nodes[minetest.get_node(pos).name].liquidtype == "source" then
                pos.y = math.max(pos.y, stellua.planets[stellua.get_planet_index(pos.y)].water_level)
                exptime = 0.95
            end
            return {
                amount = 100,
                time = 1,
                exptime = exptime,
                pos = {min=pos+vector.new(-20, 20, -20), max=pos+vector.new(20, 20, 20)},
                vel = vector.new(0, -20, 0),
                collisiondetection = true,
                collision_removal = true,
                object_collision = true,
                vertical = true,
                texture = "stl_weather_raindrop.png^[multiply:"..minetest.colorspec_to_colorstring(defs.tint),
                size = 2
            }
        end
    })
end