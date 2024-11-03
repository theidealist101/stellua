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
        return true, "Planet Index: "..index.."\nName: "..planet.name.."\nSeed: "..planet.seed.."\nHeat: "..planet.heat_stat.."K\nAtmosphere: "..planet.atmo_stat.."atm\nWater Level: "..(planet.water_level and planet.water_level-planet.level or "No surface liquid").."\nLife: "..planet.life_stat
    end
})