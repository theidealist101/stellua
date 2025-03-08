--The seat, which is the central node of a spaceship or any other vehicle
minetest.register_node("stl_vehicles:seat", {
    description = "Vehicle Seat",
    drawtype = "nodebox",
    tiles = {"wool_black.png"},
    node_box = {type="fixed", fixed={
        {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        {-0.5, -0.25, 0, 0.5, 0.375, 0.5},
        {-0.5, -0.25, -0.5, -0.25, 0.125, 0},
        {0.25, -0.25, -0.5, 0.5, 0.125, 0}
    }},
    collision_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}},
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "facedir", --lvae doesn't like 4dir
    groups = {cracky=1, spaceship=1, seat=1},
    sounds = stellua.node_sound_wood_defaults()
})

--The fuel tank, required to power the thrusters or engines of a vehicle
minetest.register_node("stl_vehicles:tank", {
    description = "Fuel Tank",
    tiles = {"stl_vehicles_tank_top.png", "stl_vehicles_tank_top.png", "stl_vehicles_tank.png"},
    groups = {cracky=2, spaceship=1, tank=1},
    sounds = stellua.node_sound_metal_defaults(),
    on_construct = function (pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("main", 16)
        meta:set_string("formspec", sfinv.make_formspec(nil, {nav_titles={}}, "list[context;main;3,1.5;2,2]", true))
        meta:set_string("infotext", "Fuel: 0")
        meta:set_string("fuel_group", "fuel")
    end,
    allow_metadata_inventory_put = function (_, _, _, itemstack)
        return minetest.get_item_group(itemstack:get_name(), "fuel") > 0 and 1000000 or 0
    end,
    after_dig_node = function (pos, node, meta, user)
        local inv = user:get_inventory()
        for _, itemstack in ipairs(meta.inventory.main) do
            minetest.add_item(pos, inv:add_item("main", itemstack))
        end
    end
})

minetest.register_craft({
    output = "stl_vehicles:tank",
    recipe = {
        {"stl_core:titanium", "stl_core:titanium", "stl_core:titanium", "stl_core:titanium"},
        {"stl_core:titanium", "", "", "stl_core:titanium"},
        {"stl_core:titanium", "", "", "stl_core:titanium"},
        {"stl_core:titanium", "stl_core:titanium", "stl_core:titanium", "stl_core:titanium"}
    }
})

--The rocket engine, for launching spaceships
minetest.register_node("stl_vehicles:rocket", {
    description = "Rocket Engine",
    drawtype = "nodebox",
    tiles = {"stl_vehicles_rocket.png"},
    node_box = {type="fixed", fixed={
        {-0.5, -0.5, -0.5, 0.5, 0, 0.5},
        {-0.25, 0, -0.25, 0.25, 0.5, 0.25}
    }},
    paramtype = "light",
    sunlight_propagates = true,
    groups = {cracky=2, spaceship=2, engine=3},
    sounds = stellua.node_sound_metal_defaults()
})

minetest.register_craft({
    output = "stl_vehicles:rocket",
    recipe = {
        {"", "stl_core:titanium", "stl_core:titanium", ""},
        {"", "stl_core:titanium", "stl_core:titanium", ""},
        {"stl_core:titanium", "", "", "stl_core:titanium"},
        {"stl_core:titanium", "", "", "stl_core:titanium"}
    }
})

--Technology assembler for crafting rocket components
minetest.register_node("stl_vehicles:assembler", {
    description = "Technology Assembler",
    drawtype = "mesh",
    mesh = "technology_assembler.obj",
    tiles = {"technology_assembler.png"},
    collision_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
    selection_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, 0, 0.5}},
    paramtype = "light",
    sunlight_propagates = true,
    on_rightclick = function (_, _, player)
        minetest.show_formspec(player:get_player_name(), "stl_vehicles:assembly", sfinv.make_formspec(nil, {nav_titles={}}, [[
            list[current_player;craft;0.75,0.25;4,4;]
            list[current_player;craftpreview;5.75,1.75;1,1;]
            image[4.75,1.75;1,1;sfinv_crafting_arrow.png]
            listring[current_player;main]
            listring[current_player;craft]
        ]], true))
    end,
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_on_joinplayer(function(player)
    local inv = player:get_inventory()
    inv:set_size("craft", 16)
    inv:set_width("craft", 4)
end)

--Impulse engine for travelling between planets
minetest.register_node("stl_vehicles:impulse_engine", {
    description = "Impulse Engine",
    drawtype = "nodebox",
    tiles = {"stl_vehicles_impulse_engine_top.png", "stl_vehicles_impulse_engine_top.png", "stl_vehicles_impulse_engine.png"},
    node_box = {type="fixed", fixed={
        {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        {-0.375, -0.25, -0.375, 0.375, 0.25, 0.375},
        {-0.5, 0.25, -0.5, 0.5, 0.5, 0.5},
    }},
    groups = {cracky=3, spaceship=1, impulse=1, tank=1},
    sounds = stellua.node_sound_metal_defaults(),
    on_construct = function (pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("main", 16)
        meta:set_string("formspec", sfinv.make_formspec(nil, {nav_titles={}}, "list[context;main;3,1.5;2,2]", true))
        meta:set_string("infotext", "Fuel: 0")
        meta:set_string("fuel_group", "fissile")
    end,
    allow_metadata_inventory_put = function (_, _, _, itemstack)
        return minetest.get_item_group(itemstack:get_name(), "fissile") > 0 and 1000000 or 0
    end,
    after_dig_node = function (pos, node, meta, user)
        local inv = user:get_inventory()
        for _, itemstack in ipairs(meta.inventory.main) do
            minetest.add_item(pos, inv:add_item("main", itemstack))
        end
    end
})

minetest.register_craft({
    output = "stl_vehicles:impulse_engine",
    recipe = {
        {"group:metal", "group:metal", "group:metal", "group:metal"},
        {"", "group:fissile", "group:fissile", ""},
        {"", "group:fissile", "group:fissile", ""},
        {"group:metal", "group:metal", "group:metal", "group:metal"}
    }
})