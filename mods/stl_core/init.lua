stellua = {}

--shut up vs code
table.insert_all = table.insert_all
table.indexof = table.indexof
math.round = math.round

local modpath = minetest.get_modpath("stl_core").."/"
dofile(modpath.."names.lua")
dofile(modpath.."mapgen.lua")

minetest.register_chatcommand("planet", {
    params = "",
    description = "Get info about the current planet",
    privs = {debug=true},
    func = function (playername)
        local index = stellua.get_planet_index(minetest.get_player_by_name(playername):get_pos())
        if not index then return false, "Not currently in a planet" end
        return true, "Planet Index: "..index.."\nName: "..stellua.planets[index].name.."\nSeed: "..stellua.planets[index].seed
    end
})