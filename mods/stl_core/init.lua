stellua = {}

--shut up vs code
table.insert_all = table.insert_all
table.indexof = table.indexof
math.round = math.round
table.copy = table.copy

local modpath = minetest.get_modpath("stl_core").."/"
dofile(modpath.."names.lua")
dofile(modpath.."nodes.lua")
dofile(modpath.."mapgen.lua")

minetest.register_chatcommand("planet", {
    params = "",
    description = "Get info about the current planet",
    privs = {debug=true},
    func = function (playername)
        local index = stellua.get_planet_index(minetest.get_player_by_name(playername):get_pos().y)
        if not index then return false, "Not currently in a planet" end
        local planet = stellua.planets[index]
        return true, "Name: "..planet.name.."\nSeed: "..planet.seed.."\nHeat: "..planet.heat_stat.."K\nAtmosphere: "..planet.atmo_stat.."atm\n"..(planet.water_level and planet.water_name.." Level: "..(planet.water_level-planet.level) or "No surface liquid").."\nLife: "..planet.life_stat.."   Dist: "..planet.dist
    end
})

minetest.register_chatcommand("star", {
    params = "",
    description = "Get info about the current star system",
    privs = {debug=true},
    func = function (playername)
        local index = stellua.get_planet_index(minetest.get_player_by_name(playername):get_pos().y)
        if not index then return false, "Not currently in a planet" end
        local star = stellua.stars[stellua.planets[index].star]
        local out = {}
        for _, i in ipairs(star.planets) do
            local planet = stellua.planets[i]
            table.insert(out, "- "..planet.name.." ("..i..")")
        end
        return true, "Name: "..star.name.."\nSeed: "..star.seed.."\nScale: "..star.scale.."\nPlanets:\n"..table.concat(out, "\n")
    end
})