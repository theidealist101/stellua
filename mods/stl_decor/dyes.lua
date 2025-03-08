minetest.register_node("stl_decor:flower", {
    description = "Flower",
    drawtype = "plantlike",
    tiles = {"stl_decor_flower.png"},
    inventory_image = "stl_decor_flower.png",
    selection_box = {type="fixed", fixed={-0.1875, -0.5, -0.1875, 0.1875, 0.1875, 0.1875}},
    walkable = false,
    paramtype = "light",
    waving = 1,
    sunlight_propagates = true,
    paramtype2 = "color",
    palette = "palette_dye.png",
    groups = {snappy=2, attached_node=1},
    sounds = stellua.node_sound_defaults()
})

minetest.register_craftitem("stl_decor:dye", {
    description = "Dye",
    inventory_image = "dye_white.png",
    palette = "palette_dye.png",
    on_place = function (itemstack, user, pointed)
        local node = minetest.get_node(pointed.under)
        local nodename = stellua.dyed_nodes[node.name]
        if nodename then
            minetest.swap_node(pointed.under, {name=nodename, param1=node.param1, param2=itemstack:get_meta():get_int("palette_index")})
            itemstack:take_item()
            return itemstack
        end
    end
})

minetest.register_craft({
    type = "shapeless",
    output = "stl_decor:dye 4",
    recipe = {"stl_decor:flower"}
})

stellua.register_color_craft("stl_decor:dye", "stl_decor:flower")

stellua.dyed_nodes = {}

function stellua.register_dyed_node(name, node, desc)
    local defs = table.copy(minetest.registered_nodes[node])
    defs.description = desc
    defs.paramtype2 = "color"
    defs.palette = "palette_dye.png"
    minetest.register_node(name, defs)
    minetest.register_craft({
        type = "shapeless",
        output = name,
        recipe = {node, "stl_decor:dye"}
    })
    minetest.register_craft({
        type = "shapeless",
        output = name,
        recipe = {name, "stl_decor:dye"}
    })
    stellua.register_color_craft(name, "stl_decor:dye")
    stellua.dyed_nodes[node] = name
    stellua.dyed_nodes[name] = name
end

stellua.register_dyed_node("stl_decor:stained_glass", "stl_decor:glass", "Stained Glass")
stellua.register_dyed_node("stl_decor:stained_wood", "stl_core:wood", "Stained Wood")

stellua.register_on_planet_generated(function (planet)
    local rand = PcgRandom(planet.seed)
    for _ = 1, math.ceil(planet.life_stat*2) do
        minetest.register_decoration({
            deco_type = "simple",
            place_on = {planet.mapgen_filler},
            fill_ratio = rand:next(1, 20)*0.0001,
            y_min = planet.level-500,
            y_max = planet.level+499,
            decoration = "stl_decor:flower",
            param2 = rand:next(0, 255)
        })
    end
end)

minetest.register_craft({
    type = "shapeless",
    output = "stl_decor:dye 2",
    recipe = {"stl_decor:dye", "stl_decor:dye"}
})

local function on_craft(itemstack, _, craft_grid)
    if itemstack:get_name() == "stl_decor:dye" then
        local x = {}
        local y = 0
        for _, ing in ipairs(craft_grid) do
            if ing:get_name() == "stl_decor:dye" then
                local c = ing:get_meta():get_int("palette_index")
                table.insert(x, c%16)
                y = y+math.floor(c/16)
            elseif not ing:is_empty() then return end
        end
        if #x ~= 2 then return end
        if x[1] > x[2] then x = {x[2], x[1]} end
        if math.abs(16+x[1]-x[2]) < math.abs(x[1]-x[2]) then x[1] = x[1]+16 end
        itemstack:get_meta():set_int("palette_index", math.round((x[1]+x[2])*0.5)%16+16*math.round(y*0.5))
        return itemstack
    end
end

minetest.register_craft_predict(on_craft)
minetest.register_on_craft(on_craft)