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
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        local planet = stellua.get_planet_index(pos.y)
        if planet then
            --check if we need to start a new weather type
            local w = weather[planet] or {start=0}
            weather[planet] = w
            local time = minetest.get_gametime()
            if time-w.start > 420 then
                w.start = time
                local options = stellua.planets[planet].weathers
                w.name = options[math.random(#options)]
                if w.name ~= "" then
                    local wdefs = stellua.registered_weathers[w.name]
                    if wdefs.on_start then wdefs.on_start(w) end
                end
            end
            --show effects for current weather type
            if w.name and w.name ~= "" then
                local wdefs = stellua.registered_weathers[w.name]
                if wdefs.particles then
                    local pdefs = wdefs.particles(vector.round(pos), w)
                    pdefs.playername = player:get_player_name()
                    minetest.add_particlespawner(pdefs)
                end
                --apply weather effects to player, such as damaging them if exposed
                if wdefs.on_step then wdefs.on_step(player, dtime, w) end
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
    local wdefs = stellua.registered_weathers[w.name]
    if wdefs.on_start then wdefs.on_start(w) end
end

--Command to set the weather
minetest.register_chatcommand("setweather", {
    params = "[<weather type>]",
    description = "Sets the weather to anything, as long as it's possible here; use without argument to clear weather, prefix with # to bypass checks and spawn impossible weather types",
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
        if string.sub(param, 1, 1) == "#" then param = string.sub(param, 2)
        elseif table.indexof(planet.weathers, param) <= 0 then return false, "Weather type "..param.." does not exist on this planet!" end
        weather[p] = {start=minetest.get_gametime(), name=param}
        local wdefs = stellua.registered_weathers[param]
        if wdefs.on_start then wdefs.on_start(weather[p]) end
        return true, "Set weather to "..param
    end
})

local up = vector.new(0, 1, 0)

--Helper functions to make particles not go underwater
function stellua.get_particle_exptime(pos)
    local out = 2
    if minetest.registered_nodes[minetest.get_node(pos).name].liquidtype == "source"
    or not minetest.registered_nodes[minetest.get_node(pos).name].walkable
    and minetest.registered_nodes[minetest.get_node(pos-up).name].liquidtype == "source" then
        pos.y = math.max(pos.y, stellua.planets[stellua.get_planet_index(pos.y)].water_level or -31000)
        out = 0.95
    end
    return out
end

--Get whether position is exposed to sky in a certain direction, and if not, how far it is from the obstacle
function stellua.exposed_to_sky(pos, dir)
    for pointed in minetest.raycast(pos, pos+(dir or up)*200, false, true) do
        if pointed.type == "node" then
            local nodename = minetest.get_node(pointed.under).name
            local nodedefs = minetest.registered_nodes[nodename]
            if nodename == "ignore" then return true
            elseif nodedefs.walkable or nodedefs.liquidtype == "source" then return false, vector.distance(pos, pointed.under) end
        end
    end
    return true
end

local elapsed = {}

--Precipitation
for _, val in pairs(stellua.registered_waters) do
    local name, defs = unpack(val)
    stellua.register_weather(name.."_rain", {
        cond = function (planet)
            return planet.mapgen_water == name.."_source" and not planet.mapgen_water_top
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
        end,
        on_step = function (player, dtime)
            local playername = player:get_player_name()
            if defs.damage_per_second and stellua.exposed_to_sky(player:get_pos()+up*1.625) then
                elapsed[playername] = (elapsed[playername] or 0)+dtime
                while elapsed[playername] > 2 do
                    elapsed[playername] = elapsed[playername]-2
                    player:set_hp(player:get_hp()-defs.damage_per_second)
                end
            end
        end
    })
    if defs.frozen_tiles then
        stellua.register_weather(name.."_hail", {
            cond = function (planet)
                return planet.mapgen_water_top == name.."_frozen" and PcgRandom(planet.seed*3):next(1, 3) > 1
            end,
            temp = function (temp)
                return (temp*3+defs.temp)*0.25-10
            end,
            particles = function (pos)
                return {
                    amount = 60,
                    time = 1,
                    exptime = 4,
                    pos = {min=pos+vector.new(-20, 20, -20), max=pos+vector.new(20, 20, 20)},
                    vel = vector.new(0, -20, 0),
                    collisiondetection = true,
                    --collision_removal = true, --ought to be off but Luanti has palpitations
                    bounce = 0,
                    texture = "stl_weather_hailstone.png^[mask:"..defs.frozen_tiles,
                    size = 8
                }
            end,
            on_step = function (player, dtime)
                local playername = player:get_player_name()
                if stellua.exposed_to_sky(player:get_pos()+up*1.625) then
                    elapsed[playername] = (elapsed[playername] or 0)+dtime
                    while elapsed[playername] > 2 do
                        elapsed[playername] = elapsed[playername]-2
                        player:set_hp(player:get_hp()-1)
                    end
                end
            end
        })
        stellua.register_planet_warning(function (planet)
            if table.indexof(planet.weathers, name.."_hail") > 0 then return "HAZARDOUS PRECIPITATION" end
        end)
    end
end

stellua.register_planet_warning(function (planet)
    if planet.water_level and minetest.registered_nodes[planet.mapgen_water].damage_per_second > 0 then return "HAZARDOUS PRECIPITATION" end
end)

for _, val in pairs(stellua.registered_snows) do
    local name, defs = unpack(val)
    stellua.register_weather(name.."_fall", {
        cond = function (planet)
            return planet.snow_type1 == name or planet.snow_type2 == name
        end,
        temp = function (temp)
            return (temp*3+defs.temp)*0.25-10
        end,
        particles = function (pos)
            return {
                amount = 25,
                time = 1,
                exptime = stellua.get_particle_exptime(pos)*4,
                pos = {min=pos+vector.new(-30, 20, -30), max=pos+vector.new(30, 20, 30)},
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

--Wind which blows you in a certain direction
stellua.register_weather("stl_weather:wind", {
    description = "Strong winds",
    cond = function (planet)
        return planet.life_stat < 1 and planet.atmo_stat >= 1 and PcgRandom(planet.seed*2):next(1, 3) == 1
    end,
    temp = function (temp)
        return temp-20
    end,
    particles = function (pos, w)
        local planet = stellua.planets[stellua.get_planet_index(pos.y)]
        return {
            amount = 200,
            time = 1,
            exptime = 1,
            pos = {min=vector.new(pos.x-20, math.max(pos.y-20, planet.water_level or planet.level), pos.z-20), max=pos+vector.new(20, 20, 20)},
            vel = vector.multiply(w.dir, 25),
            collisiondetection = true,
            collision_removal = true,
            object_collision = true,
            texture = "stl_weather_wind.png",
            size = 4
        }
    end,
    on_start = function (w)
        w.dir = vector.rotate_around_axis(vector.new(0, 0, 1), up, math.random(1, 100)*0.02*math.pi)
    end,
    on_step = function (player, dtime, w)
        local exposed, dist = stellua.exposed_to_sky(player:get_pos()+up*1.625, vector.subtract(vector.zero(), w.dir))
        if exposed or dist >= 32 then
            player:add_velocity(vector.multiply(w.dir, dtime*25))
        end
    end
})