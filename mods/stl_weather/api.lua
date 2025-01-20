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

local sound_handles = {}

--Do the particles and stuff each globalstep
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local playername = player:get_player_name()
        local pos = player:get_pos()
        local planet = stellua.get_planet_index(pos.y)
        if planet then
            --check if we need to start a new weather type
            local w = weather[planet] or {start=0}
            weather[planet] = w
            local planetdefs = stellua.planets[planet]
            local time = minetest.get_gametime()
            if time-w.start > 420 then
                w.start = time
                local options = planetdefs.weathers
                w.name = options[math.random(#options)]
                if w.name ~= "" then
                    local wdefs = stellua.registered_weathers[w.name]
                    if wdefs.on_start then wdefs.on_start(w) end
                end
            end
            --stop old weather sound if no longer valid
            local on_surface = pos.y-(planetdefs.water_level or planetdefs.level) > -20 or stellua.exposed_to_sky(pos)
            local sh = sound_handles[playername]
            if sh and (sh[1] ~= w.name or not on_surface) then
                minetest.sound_fade(sh[2], stellua.registered_weathers[sh[1]].sound.fade or 100, 0)
                sound_handles[playername] = nil
            end
            --show effects for current weather type
            if on_surface then
                local wdefs
                if w.name and w.name ~= "" then
                    wdefs = stellua.registered_weathers[w.name]
                    --particles for weather type
                    if wdefs.particles then
                        local pdefs = wdefs.particles(vector.round(pos), w)
                        pdefs.playername = playername
                        minetest.add_particlespawner(pdefs)
                    end
                    --apply weather effects to player, such as damaging them if exposed
                    if wdefs.on_step then wdefs.on_step(player, dtime, w) end
                    --play the correct sound for the player
                    if sound_handles[playername] == nil and wdefs.sound then
                        sound_handles[playername] = {w.name, minetest.sound_play(wdefs.sound, {loop=true, to_player=playername})}
                    end
                end
            end
        end
    end
    storage:set_string("weather", minetest.serialize(weather))
end)

minetest.register_on_leaveplayer(function(player)
    sound_handles[player:get_player_name()] = nil
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
        if string.sub(param, 1, 1) == "#" then
            param = string.sub(param, 2)
            if not stellua.registered_weathers[param] then
                return false, "Weather type "..param.." does not exist!"
            end
        elseif table.indexof(planet.weathers, param) <= 0 then
            return false, "Weather type "..param.." does not exist"..(stellua.registered_weathers[param] and " on this planet!" or "!")
        end
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
        sound = {name="212799__ayton__rain-loop-ontario", gain=0.5, fade=0.1},
        on_step = function (player, dtime)
            local playername = player:get_player_name()
            if defs.damage_per_second and not player:get_attach() and stellua.exposed_to_sky(player:get_pos()+up*1.625) then
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
                    pos = {min=pos+vector.new(-30, 20, -30), max=pos+vector.new(30, 20, 30)},
                    vel = vector.new(0, -20, 0),
                    collisiondetection = true,
                    bounce = 0,
                    texture = "stl_weather_hailstone.png^[mask:"..defs.frozen_tiles,
                    size = 8
                }
            end,
            sound = {name="624267__iwaobisou__soft-hail-leaves-looped", gain=1, fade=0.2},
            on_step = function (player, dtime)
                local playername = player:get_player_name()
                if not player:get_attach() and stellua.exposed_to_sky(player:get_pos()+up*1.625) then
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
                texture = "stl_weather_"..(defs.actual_snow and "snowflake" or "ash")..".png^[mask:"..defs.tiles,
                size = 4
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
    end,
    sound = {name="777331__matthiasflowers__101glcglitzer-teckyy-kachelhi_endonly", gain=0.05, fade=0.01}
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
            vel = vector.multiply(w.dir, 40),
            collisiondetection = true,
            collision_removal = true,
            object_collision = true,
            texture = "stl_weather_wind.png",
            size = 8
        }
    end,
    sound = {name="651545__nsstudios__wind-draft-loop-3", gain=1, fade=0.2},
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

--Showers of tiny meteors on barren planets
stellua.register_weather("stl_weather:meteors", {
    description = "Frequent meteor showers",
    cond = function (planet)
        return planet.atmo_stat <= 0.2 or planet.atmo_stat < 0.5 and PcgRandom(planet.seed*4):next(1, 2) == 1
    end,
    temp = function (temp)
        return temp
    end,
    on_step = function (player, dtime, w)
        w.elapsed = (w.elapsed or 0)-dtime
        if w.elapsed <= 0 and math.random(1, #minetest.get_connected_players()) == 1 then
            minetest.add_entity(player:get_pos()+vector.new(math.random(-20, 20), 50, math.random(-20, 20)), "stl_weather:meteor")
            w.elapsed = math.random(1, 5)*0.2
        end
    end
})

minetest.register_entity("stl_weather:meteor", {
    initial_properties = {
        visual = "sprite",
        textures = {"blank.png"},
        physical = true,
        collisionbox = {-0.2, -0.2, -0.2, 0.2, 0.2, 0.2}
    },
    on_activate = function (self, staticdata)
        if staticdata and staticdata ~= "" then
            self.vel = minetest.deserialize(staticdata)
        else
            self.vel = vector.normalize(vector.random_direction()-vector.new(0, 2, 0))*20
        end
        self.object:set_velocity(self.vel)
    end,
    on_step = function (self, _, moveresult)
        local pos = self.object:get_pos()
        if #moveresult.collisions > 0 then
            for obj in minetest.objects_inside_radius(pos, 1) do
                obj:set_hp(obj:get_hp()-16)
            end
            self.object:remove()
            minetest.add_particlespawner({
                amount = 100,
                time = 0.1,
                exptime = {min=0.5, max=1},
                pos = pos,
                radius = {min=0, max=2, bias=1},
                drag = 1,
                texture = "stl_weather_ash.png^[mask:stl_core_ash.png",
                size = 4,
                attract = {
                    kind = "point",
                    origin = pos,
                    strength = -2
                }
            })
            minetest.sound_play({name="717995__johnny25225__heavywobblyimpacthit_06", gain=1, pitch=2^(math.random(-10, 0)*0.1)}, {pos=pos}, true)
            return
        end
        minetest.add_particle({
            expirationtime = 0.2,
            pos = pos,
            velocity = vector.zero(),
            jitter = {min=vector.new(-2, -2, -2), max=vector.new(2, 2, 2)},
            texture = "stl_weather_ash.png^[mask:stl_core_ash.png",
            size = 4
        })
    end,
    get_staticdata = function (self)
        return minetest.serialize(self.vel)
    end
})