--HUDs for temperature
local heat_huds, cold_huds = {}, {}

minetest.register_on_joinplayer(function(player)
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

--Get temperature at position
function stellua.get_temperature(pos)
    if stellua.assemble_vehicle(vector.round(pos)) then return 300 end
    local index = stellua.get_planet_index(pos.y)
    if not index then return 0 end
    --insert any other temperature modifying things here (nearby nodes perhaps?)
    return stellua.planets[index].heat_stat
end

--Make player temperature increase or decrease depending on the planet
local elapsed = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local playername = player:get_player_name()
        local meta = player:get_meta()
        local playertemp = meta:get_float("temp")
        local temp = stellua.get_temperature(player:get_pos())
        if temp < 270 or temp > 330 then
            playertemp = math.min(math.max(playertemp+(temp-300)*0.005*dtime, -20), 20)
        else
            playertemp = math.sign(playertemp)*math.max(math.abs(playertemp)-0.5*dtime, 0)
        end
        meta:set_float("temp", playertemp)
        player:hud_change(heat_huds[playername], "item", playertemp > 0 and 20 or 0)
        player:hud_change(cold_huds[playername], "item", playertemp < 0 and 20 or 0)
        player:hud_change(heat_huds[playername], "number", playertemp > 0 and playertemp or 0)
        player:hud_change(cold_huds[playername], "number", playertemp < 0 and -playertemp or 0)
        if playertemp <= -20 or playertemp >= 20 then
            elapsed[playername] = (elapsed[playername] or 0)+dtime
            while elapsed[playername] > 2 do
                elapsed[playername] = elapsed[playername]-2
                player:set_hp(player:get_hp()-1)
            end
        end
    end
end)

--Restore temperature upon respawning
minetest.register_on_respawnplayer(function(player)
    player:get_meta():set_float("temp", 0)
end)