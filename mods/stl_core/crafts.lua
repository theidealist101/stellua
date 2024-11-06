--Override hand so it can break stuff
minetest.override_item("", {
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {
            cracky = {times={2}},
            crumbly = {times={1, 2}},
            snappy = {times={0.5}}
        }
    }
})

--Basic tools
minetest.register_tool("stl_core:stone_pick", {
    description = "Stone Pick",
    inventory_image = "default_tool_stonepick.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        groupcaps = {
            cracky = {times={1, 2}, uses=100}
        }
    }
})

minetest.register_tool("stl_core:stone_shovel", {
    description = "Stone Shovel",
    inventory_image = "default_tool_stoneshovel.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        groupcaps = {
            crumbly = {times={0.5, 1}, uses=100}
        }
    }
})

minetest.register_tool("stl_core:stone_axe", {
    description = "Stone Axe",
    inventory_image = "default_tool_stoneaxe.png",
    tool_capabilities = {
        full_punch_interval = 1.5,
        groupcaps = {
            snappy = {times={0.25}, uses=100}
        }
    }
})

minetest.register_craft({
    output = "stl_core:stone_pick",
    recipe = {
        {"stl_core:pebble", "stl_core:pebble", "stl_core:pebble"},
        {"", "stl_core:stick", ""},
        {"", "stl_core:stick", ""}
    }
})

minetest.register_craft({
    output = "stl_core:stone_shovel",
    recipe = {
        {"stl_core:pebble"},
        {"stl_core:stick"},
        {"stl_core:stick"}
    }
})

minetest.register_craft({
    output = "stl_core:stone_axe",
    recipe = {
        {"stl_core:pebble", "stl_core:pebble"},
        {"stl_core:pebble", "stl_core:stick"},
        {"", "stl_core:stick"}
    }
})