--HUDs for temperature
local heat_huds, cold_huds, vignette_huds, vignette_ops = {}, {}, {}, {}

minetest.register_on_joinplayer(function(player)
    local immortal = player:get_armor_groups().immortal
    if immortal and immortal > 0 then return end
    local playername = player:get_player_name()
    heat_huds[playername] = player:hud_add({
        type = "statbar",
        z_index = 0,
        position = {x=0.5, y=1},
        alignment = {x=1, y=0},
        offset = {x=-265, y=-115},
        text = "stl_weather_hud_heat.png",
        text2 = "stl_weather_hud_heat_gone.png",
        number = 0,
        item = 0
    })
    cold_huds[playername] = player:hud_add({
        type = "statbar",
        z_index = 0,
        position = {x=0.5, y=1},
        alignment = {x=1, y=0},
        offset = {x=-265, y=-115},
        text = "stl_weather_hud_cold.png",
        text2 = "stl_weather_hud_cold_gone.png",
        number = 0,
        item = 0
    })
end)

--Get temperature at position for the player's purposes
function stellua.get_temperature(pos)
    --always room temperature inside vehicles, at least for now
    if stellua.assemble_vehicle(pos) then return 300 end

    --absolute zero in the vastness of space because I say so
    local index = stellua.get_planet_index(pos.y)
    if not index then return 0 end

    --base temperature is the planet's heat stat, altered by height
    local out = stellua.planets[index].heat_stat*((500-pos.y)%1000)*0.002

    --if in weather then it gets modified by that
    local weather = stellua.get_weather(index)
    if weather and weather ~= "" then
        out = stellua.registered_weathers[weather].temp(out)
    end

    --if in a liquid then it tends towards that liquid's preferred temperature
    local defs = minetest.registered_nodes[minetest.get_node(pos).name]
    if defs and defs.temp then out = (out+defs.temp)*0.5 end

    --insert any other temperature modifying things here (nearby nodes perhaps?)

    return out
end

--Make player temperature increase or decrease depending on the planet
local elapsed = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local immortal = player:get_armor_groups().immortal
        local playername = player:get_player_name()
        local meta = player:get_meta()

        --change player temperature
        local playertemp = meta:get_float("temp")
        local temp = player:get_attach() and 300 or stellua.get_temperature(vector.round(player:get_pos()))
        if temp < 270 or temp > 330 then
            playertemp = math.min(math.max(playertemp+dtime*math.sign(temp-300)*((temp-300)*0.005)^2, -20), 20)
        else
            playertemp = math.sign(playertemp)*math.max(math.abs(playertemp)-dtime*0.5, 0)
        end
        meta:set_float("temp", playertemp)

        if not immortal or immortal == 0 then
            --update HUDs
            player:hud_change(heat_huds[playername], "item", playertemp > 0 and 20 or 0)
            player:hud_change(cold_huds[playername], "item", playertemp < 0 and 20 or 0)
            player:hud_change(heat_huds[playername], "number", playertemp > 0 and playertemp or 0)
            player:hud_change(cold_huds[playername], "number", playertemp < 0 and -playertemp or 0)
            local op = meta:get_int("vignette_op")
            local vtype = meta:get_string("vignette_type")

            --deal damage if too hot or cold
            if playertemp <= -20 or playertemp >= 20 then
                elapsed[playername] = (elapsed[playername] or 0)+dtime
                while elapsed[playername] > 2 do
                    elapsed[playername] = elapsed[playername]-2
                    player:set_hp(player:get_hp()-1)
                end

                --show this with a vignette
                if not vignette_huds[playername] then
                    vtype = playertemp < 0 and "cold" or "heat"
                    vignette_huds[playername] = player:hud_add({
                        type = "image",
                        scale = {x=-100, y=-100},
                        text = "stl_weather_vignette_"..vtype..".png^[opacity:0",
                        position = {x=0.5, y=0.5},
                        alignment = {x=0, y=0},
                        offset = {x=0, y=0},
                        z_index = -400
                    })
                    op = 0
                elseif op < 255 then
                    op = op+1
                    player:hud_change(vignette_huds[playername], "text", "stl_weather_vignette_"..vtype..".png^[opacity:"..op)
                end
            elseif op > 0 then
                op = op-1
                player:hud_change(vignette_huds[playername], "text", "stl_weather_vignette_"..vtype..".png^[opacity:"..op)
            elseif vignette_huds[playername] then
                player:hud_remove(vignette_huds[playername])
                vignette_huds[playername] = nil
            end
            meta:set_int("vignette_op", op)
            meta:set_string("vignette_type", vtype)
        elseif vignette_huds[playername] then
            player:hud_remove(vignette_huds[playername])
            vignette_huds[playername] = nil
        end
    end
end)

--Restore temperature upon respawning
minetest.register_on_respawnplayer(function(player)
    local meta = player:get_meta()
    meta:set_float("temp", 0)
    meta:set_int("vignette_op", 0)
end)