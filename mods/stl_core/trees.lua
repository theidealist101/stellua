local MOVES = "FfffTTTABCDabcd++--&&^^//**"

--Create random axiom recursively
local function make_axiom(rand)
    local out = ""
    for _ = 1, rand:next(2, 10) do
        local char = rand:next(-2, string.len(MOVES))
        if char <= 0 then out = out.."["..make_axiom(rand).."]"
        else out = out..string.sub(MOVES, char, char) end
    end
    return out
end

--Generate random L-system definition
function stellua.make_treedef(rand)
    return {
        axiom = make_axiom(rand),
        rules_a = make_axiom(rand),
        rules_b = make_axiom(rand),
        rules_c = make_axiom(rand),
        rules_d = make_axiom(rand),
        trunk = "stl_core:log"..rand:next(1, 8),
        leaves = "stl_core:leaves"..rand:next(1, 8),
        angle = rand:next(10, 50),
        iterations = rand:next(1, 6),
        random_level = rand:next(0, 3),
        trunk_type = ({"single", "single", "single", "double", "crossed"})[rand:next(1, 5)],
        thin_branches = true,
        fruit_chance = 0,
        seed = rand:next()
    }
end

--Command to spawn a tree with random definition, for debugging
minetest.register_chatcommand("spawntree", {
    params = "",
    description = "Spawn a tree at current position",
    privs = {give=true, debug=true},
    func = function (playername)
        minetest.spawn_tree(
            vector.round(minetest.get_player_by_name(playername):get_pos()),
            stellua.make_treedef(PcgRandom(math.floor(math.random()*1000000000)))
        )
    end
})