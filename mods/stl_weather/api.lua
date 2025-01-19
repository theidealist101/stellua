--Remember each planet's current weather in mod storage
local storage = minetest.get_mod_storage()
local weather = minetest.deserialize(storage:get_string("weather")) or {}

--Register weather type
stellua.registered_weathers = {}

function stellua.register_weather(name, defs)
    defs.cond = defs.cond or function() return false end
    stellua.registered_weathers[name] = defs
    if defs.description then
        stellua.register_planet_info(function (planet)
            if table.indexof(planet.weathers, name) > 0 then return defs.description end
        end)
    end
end

--Set up the types of weather for each planet
stellua.register_on_planet_generated(function (planet)
    planet.weathers = {"", ""}
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
        local planet = stellua.get_planet_index(pos.y)
        if planet then
            --check if we need to start a new weather type
            local w = weather[planet] or {start=0}
            weather[planet] = w
            w.start = w.start+1
            local time = minetest.get_gametime()
            if time-w.start > 420 then
                w.start = time
                local options = stellua.planets[planet].weathers
                w.name = options[math.random(#options)]
            end
            --show effects for current weather type
            if w.name and w.name ~= "" then
                local pdefs = stellua.registered_weathers[w.name].particles(vector.round(pos))
                pdefs.playername = player:get_player_name()
                minetest.add_particlespawner(pdefs)
            end
        end
    end
    storage:set_string("weather", minetest.serialize(weather))
end)

--Get current weather table for planet index
function stellua.get_weather(planet)
    weather[planet] = weather[planet] or {start=0}
    return weather[planet].name, weather[planet].start
end

--Set current weather table for planet index (unrestricted)
function stellua.set_weather(planet, w)
    weather[planet] = {start=minetest.get_gametime(), name=w}
end

--Command to set the weather
minetest.register_chatcommand("setweather", {
    params = "[<weather type>]",
    description = "Sets the weather to anything, as long as it's possible here (use without argument to clear weather)",
    privs = {settime=true},
    func = function (playername, param)
        local player = minetest.get_player_by_name(playername)
        local p = stellua.get_planet_index(player:get_pos().y)
        if not p then return false, "Not on a planet!" end
        if param == "" then
            weather[p] = {start=minetest.get_gametime()}
            return true, "Cleared weather"
        end
        local planet = stellua.planets[p]
        if table.indexof(planet.weathers, param) <= 0 then return false, "Weather type "..param.." does not exist on this planet!" end
        weather[p] = {start=minetest.get_gametime(), name=param}
        return true, "Set weather to "..param
    end
})

local up = vector.new(0, 1, 0)

--Helper function to make particles not go underwater
function stellua.get_particle_exptime(pos)
    local out = 2
    if minetest.registered_nodes[minetest.get_node(pos).name].liquidtype == "source"
    or not minetest.registered_nodes[minetest.get_node(pos).name].walkable
    and minetest.registered_nodes[minetest.get_node(pos-up).name].liquidtype == "source" then
        pos.y = math.max(pos.y, stellua.planets[stellua.get_planet_index(pos.y)].water_level)
        out = 0.95
    end
    return out
end

--Precipitation
for _, val in pairs(stellua.registered_waters) do
    local name, defs = unpack(val)
    stellua.register_weather(name.."_rain", {
        cond = function (planet)
            return planet.mapgen_water == name.."_source"
        end,
        temp = function (temp)
            return (temp*3+defs.temp)*0.25-5
        end,
        particles = function (pos)
            return {
                amount = 100,
                time = 1,
                exptime = stellua.get_particle_exptime(pos),
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

for _, val in pairs(stellua.registered_snows) do
    local name, defs = unpack(val)
    stellua.register_weather(name.."_fall", {
        cond = function (planet)
            return planet.snow_type1 == name or planet.snow_type2 == name
        end,
        temp = function (temp)
            return (temp*3+defs.temp)*0.25-5
        end,
        particles = function (pos)
            return {
                amount = 25,
                time = 1,
                exptime = stellua.get_particle_exptime(pos)*4,
                pos = {min=pos+vector.new(-20, 20, -20), max=pos+vector.new(20, 20, 20)},
                vel = vector.new(0, -5, 0),
                jitter = {min=vector.new(-2, -2, -2), max=vector.new(2, 2, 2)},
                collisiondetection = true,
                collision_removal = true,
                object_collision = true,
                texture = "stl_weather_snowflake.png^[mask:"..defs.tiles,
                size = 2
            }
        end
    })
end

--Spores
stellua.register_weather("stl_weather:spores", {
    description = "Spore clouds",
    cond = function (planet)
        return planet.life_stat >= 1.6
    end,
    temp = function (temp)
        return temp+20
    end,
    particles = function (pos)
        return {
            amount = 300,
            time = 1,
            exptime = 1,
            pos = {min=pos+vector.new(-20, -20, -20), max=pos+vector.new(20, 20, 20)},
            vel = {min=vector.new(-2, -2, -2), max=vector.new(2, 2, 2)},
            jitter = {min=vector.new(-2, -2, -2), max=vector.new(2, 2, 2)},
            texture = "stl_weather_spore.png",
            glow = 15,
            size = 4
        }
    end
})