local NORTH = vector.new(0, 0, -1)

--Skybox planet/star entity
minetest.register_entity("stl_core:skybox", {
    initial_properties = {
        visual = "mesh",
        visual_size = {x=100, y=100, z=32000},
        mesh = "skybox.obj",
        textures = {"blank.png"},
        use_texture_alpha = true,
        glow = -1,
        static_save = false,
        pointable = false
    },
    on_activate = function (self, staticdata)
        self.player = minetest.get_player_by_name(staticdata)
    end,
    set_star = function (self, i)
        self.star = i
        self.object:set_properties({textures={"sun.png"}})
    end,
    set_planet = function (self, i)
        self.planet = i
        self.object:set_properties({textures={stellua.planets[i].icon}})
    end,
    on_step = function (self)
        if not self.player:is_valid() then self.object:remove() return end
        local pos = self.player:get_pos()
        pos.y = pos.y+self.player:get_properties().eye_height
        if vector.distance(self.object:get_pos(), pos) > 90 then self.object:remove() return end

        local index = stellua.get_planet_index(pos.y)
        local slot = stellua.get_slot_index(pos)
        local current_star, current_pos, fog_dist
        if index then
            local planet = stellua.planets[index]
            current_star, current_pos = planet.star, planet.pos
            fog_dist = planet.fog_dist
        elseif slot then
            current_star, current_pos = stellua.get_slot_info(slot)
            fog_dist = 180
        else self.object:remove() return end

        self.object:set_pos(pos)
        self.object:set_velocity(self.player:get_velocity())
        local rot = vector.dir_to_rotation(vector.rotate_around_axis(self.star and stellua.stars[self.star].pos-stellua.stars[current_star].pos or stellua.planets[self.planet].pos-current_pos, NORTH, (minetest.get_timeofday()+0.5)*2*math.pi))
        self.object:set_rotation(rot)
        local dist = 160*(fog_dist-10)
        local scale = dist*(self.star and 0.005 or 0.1*stellua.planets[self.planet].scale/vector.distance(stellua.planets[self.planet].pos, current_pos))
        self.object:set_properties({visual_size={x=scale, y=scale, z=dist-scale*0.5}})
    end
})

--Show player planet sky
minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = player:get_pos()
        local index = stellua.get_planet_index(pos.y)
        local current_star
        if not index then
            player:set_sky({
                type = "plain",
                base_color = "#000000",
                clouds = false
            })
            player:set_sun({visible=false})
            player:set_stars({day_opacity=1})
            local slot = stellua.get_slot_index(pos)
            current_star = slot and stellua.get_slot_info(slot)
        else
            local planet = stellua.planets[index]
            pos.y = pos.y+player:get_properties().eye_height
            local height = math.min(math.max(((planet.water_level or planet.level)-pos.y)*0.004+1, 0), 1)
            current_star = planet.star

            player:set_sky(planet.sky(minetest.get_timeofday(), height))
            player:set_sun(planet.sun)
            player:set_stars(planet.stars(height))
            player:set_clouds({height=(planet.water_level or planet.level)+120})
            player:set_physics_override({gravity=planet.gravity, speed=planet.walk_speed})
        end

        for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 100)) do
            local entity = obj:get_luaentity()
            if entity and entity.name == "stl_core:skybox" and entity.player == player then return end
        end
        for i, star in ipairs(stellua.stars) do
            if i ~= current_star then
                local obj = minetest.add_entity(pos, "stl_core:skybox", player:get_player_name())
                if obj then obj:get_luaentity():set_star(i) end
            end
        end
        if current_star then
            for _, i in ipairs(stellua.stars[current_star].planets) do
                if i ~= index then
                    local obj = minetest.add_entity(pos, "stl_core:skybox", player:get_player_name())
                    if obj then obj:get_luaentity():set_planet(i) end
                end
            end
        end
    end
end)

minetest.register_on_joinplayer(function(player)
    player:set_sun({sunrise_visible=false})
    player:set_moon({visible=false})
    player:set_stars({star_color = "#ebebff20"})
end)