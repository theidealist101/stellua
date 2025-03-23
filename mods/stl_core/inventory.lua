--Register extra fields to add to planet info
stellua.registered_planet_infos = {}

function stellua.register_planet_info(func)
    table.insert(stellua.registered_planet_infos, func)
end

stellua.registered_planet_warnings = {}

function stellua.register_planet_warning(func)
    table.insert(stellua.registered_planet_warnings, func)
end

--Settings for planet info units
local units = {
    Kelvin = {"K", 1, 0},
    Celsius = {"°C", 1, -273.15},
    Fahrenheit = {"°F", 1.8, -459.67},
    Rankine = {"°R", 1.8, 0},
    Reaumur = {"°Ré", 0.8, -218.52},
    Nguh = {"°Ŋ", 1/13, -273.15/13},
    atmospheres = {"atm", 1},
    kilopascals = {"kPa", 101.325},
    psi = {"psi", 14.69595},
    bars = {"bar", 1.01325}
}

--Page giving a menu for planet info
sfinv.register_page("stl_core:planets", {
    title = "Planets",
    get = function (self, player, context)
        local out = {}
        local index = stellua.get_planet_index(player:get_pos().y)
        local slot = stellua.get_slot_index(player:get_pos())
        if not context.planet then context.planet = index or 0 end
        if context.planet == 0 then
            local x, y = 0, 0.5
            for i, star in ipairs(stellua.stars) do
                table.insert(out, "image_button["..(x*2)..","..(y*2)..";2,2;sun.png;star"..i..";"..star.name.."]")
                x = x+1
                if x > 3 then x, y = 0, y+1 end
            end
        elseif context.planet < 0 then
            local x, y = 0, 0.5
            for _, i in ipairs(stellua.stars[-context.planet].planets) do
                local planet = stellua.planets[i]
                table.insert(out, "image_button["..(x*2)..","..(y*2)..";2,2;"..planet.icon..";planet"..i..";"..planet.name.."]")
                x = x+1
                if x > 3 then x, y = 0, y+1 end
            end
            table.insert(out, "button[0,-0.15;1,1;back;<]")
        else
            local planet = stellua.planets[context.planet]
            local heat_unit = units[minetest.settings:get("stl_heat_unit") or "Celsius"]
            local atmo_unit = units[minetest.settings:get("stl_atmo_unit") or "atmospheres"]
            local info = {
                "Average Temperature: "..(0.01*math.round(100*(heat_unit[2]*planet.heat_stat+heat_unit[3]))).." "..heat_unit[1],
                "Atmospheric Pressure: "..(0.01*math.round(100*atmo_unit[2]*planet.atmo_stat)).." "..atmo_unit[1],
                planet.water_level and string.sub(planet.water_name, 1, 1)..string.lower(string.sub(planet.water_name, 2)).." oceans" or "No surface liquid",
                planet.life_stat > 1 and "High biodiversity" or planet.life_stat > 0.5 and "Low biodiversity" or planet.life_stat > 0 and "Only low-lying grasses" or "No plant life",
                (planet.depth_filler == 0 and "Surface" or planet.water_level and planet.depth_seabed == 0 and "Seabed" or "Underground").." "..planet.ore_common.." deposits"
            }
            for _, val in pairs(stellua.registered_planet_infos) do
                local t = val(planet)
                if t then table.insert(info, t) end
            end
            for _, val in pairs(stellua.registered_planet_warnings) do
                local t = val(planet)
                if t then table.insert(info, "WARNING: "..string.upper(t)) end
            end
            out = {
                "label[0,2;"..table.concat(info, "\n").."]",
                "style_type[label;font_size=*3]",
                "label[0,1;"..planet.name.."]",
                "image[5,0.5;3,3;"..planet.icon..";]",
                "button[0,-0.15;1,1;back;<]"
            }
            if slot then
                local star, pos = stellua.get_slot_info(slot)
                local cost = planet.star == star and vector.distance(planet.pos, pos) or 16*vector.distance(stellua.stars[planet.star].pos, stellua.stars[star].pos)
                table.insert(out, "button[1,-0.15;3,1;tp;Go here ("..math.round(cost+0.3).." Uranium)]")
            end
        end
        return sfinv.make_formspec(player, context, table.concat(out), false)
    end,
    on_player_receive_fields = function (self, player, context, fields)
        local playername = player:get_player_name()
        if fields.back then
            context.planet = context.planet and context.planet > 0 and -stellua.planets[context.planet].star or 0
            sfinv.set_page(player, "stl_core:planets")
            return
        end
        if fields.tp then
            local slot = stellua.get_slot_index(player:get_pos())
            local ent = stellua.detach_vehicle(stellua.get_slot_pos(slot))
            local planet = stellua.planets[context.planet]
            local star, spos = stellua.get_slot_info(slot)
            local cost = planet.star == star and vector.distance(planet.pos, spos) or 16*vector.distance(stellua.stars[planet.star].pos, stellua.stars[star].pos)
            local fuel, ignite = stellua.get_fuel(ent.tanks, math.round(cost+0.3), "fissile")
            if not fuel and not minetest.is_creative_enabled(playername) then
                stellua.land_vehicle(ent, stellua.get_slot_pos(slot))
                minetest.chat_send_player(playername, "Not enough impulse fuel!")
                if ignite then minetest.sound_play({name="fire_flint_and_steel", gain=0.2}, {pos=stellua.get_slot_pos(slot)}, true) end
                return
            end
            local pos = vector.new(0, stellua.get_planet_level(context.planet)+150, 0)
            ent.player = playername
            ent.object:set_pos(pos)
            player:set_pos(pos)
            stellua.set_player_slot(playername)
            context.planet = nil
            minetest.close_formspec(playername, "")
            sfinv.set_page(player, "stl_core:planets")
            if ignite then minetest.sound_play({name="fire_flint_and_steel", gain=0.2}, {object=ent.object}, true) end
        end
        for i = 1, 60 do
            if fields["planet"..i] then
                context.planet = i
                sfinv.set_page(player, "stl_core:planets")
                return
            end
        end
        for i = 1, 16 do
            if fields["star"..i] then
                context.planet = -i
                sfinv.set_page(player, "stl_core:planets")
                return
            end
        end
    end
})

--Builtin planet info
stellua.register_planet_info(function(planet)
    if planet.caves then return "Cave systems" end
end)

stellua.register_planet_info(function(planet)
    if planet.caves and planet.lava_level then return "Underground "..string.lower(planet.lava_name).." pools" end
end)

stellua.register_planet_info(function(planet)
    if planet.snow_type1 then return minetest.registered_nodes[planet.snow_type1].description end
end)

stellua.register_planet_info(function(planet)
    if planet.snow_type2 ~= planet.snow_type1 and planet.snow_type2 then return minetest.registered_nodes[planet.snow_type2].description end
end)

stellua.register_planet_info(function(planet)
    if planet.life_stat > 1.5 then return "Moss" end
end)

stellua.register_planet_info(function(planet)
    if planet.quartz then return minetest.registered_nodes[planet.quartz].description end
end)

stellua.register_planet_info(function(planet)
    if planet.crystal then return minetest.registered_nodes[planet.crystal].description end
end)

stellua.register_planet_info(function(planet)
    if planet.sulfur then return "Underground "..string.lower(minetest.registered_nodes[planet.sulfur].description) end
end)

stellua.register_planet_warning(function(planet)
    if planet.scale > 1.1 then return "HIGH GRAVITY" end
end)

stellua.register_planet_warning(function(planet)
    if planet.atmo_stat < 0.5 then return "LOW ATMOSPHERE" end
end)

stellua.register_planet_warning(function(planet)
    if planet.heat_stat < 200 then return "VERY COLD" end
end)

stellua.register_planet_warning(function(planet)
    if planet.heat_stat > 400 then return "VERY HOT" end
end)