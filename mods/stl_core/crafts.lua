--Override hand so it can break stuff
minetest.override_item("", {
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {
            cracky = {times={2}},
            crumbly = {times={1, 2}},
            snappy = {times={0.5, 1}},
            choppy = {times={1, 2}}
        }
    }
})

--A simple system for crafts which retain their constituents' color
stellua.registered_color_crafts = {}

function stellua.register_color_craft(output, recipe)
    table.insert(stellua.registered_color_crafts, {output, recipe})
end

local function on_craft(itemstack, player, craft_grid)
    for _, val in ipairs(stellua.registered_color_crafts) do
        local output, recipe = unpack(val)
        if itemstack:get_name() == output then
            local col
            for i, ing in ipairs(craft_grid) do
                if ing:get_name() == recipe then
                    local newcol = ing:get_meta():get_int("palette_index")
                    if not col then col = newcol elseif col ~= newcol then return ItemStack("") end
                end
            end
            if col then
                itemstack:get_meta():set_int("palette_index", col)
                return itemstack
            end
        end
    end
end

minetest.register_craft_predict(on_craft)
minetest.register_on_craft(on_craft)

--Craft cobble into pebbles, or four pebbles of the same type into cobble
minetest.register_craft({
    type = "shapeless",
    output = "stl_core:pebble 4",
    recipe = {"stl_core:cobble"}
})

minetest.register_craft({
    output = "stl_core:cobble",
    recipe = {
        {"stl_core:pebble", "stl_core:pebble"},
        {"stl_core:pebble", "stl_core:pebble"}
    }
})

stellua.register_color_craft("stl_core:pebble", "stl_core:cobble")
stellua.register_color_craft("stl_core:cobble", "stl_core:pebble")

--Craft logs into wood and wood into sticks
for i = 1, 8 do
    minetest.register_craft({
        type = "shapeless",
        output = "stl_core:wood 4",
        recipe = {"stl_core:log"..i}
    })
    stellua.register_color_craft("stl_core:wood", "stl_core:log"..i)
end

minetest.register_craft({
    type = "shapeless",
    output = "stl_core:stick 4",
    recipe = {"stl_core:wood"}
})

stellua.register_color_craft("stl_core:stick", "stl_core:wood")

--Basic tools
minetest.register_tool("stl_core:wood_pick", {
    description = "Wood Pick",
    inventory_image = "default_tool_woodpick.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        groupcaps = {
            cracky = {times={1.6, 3.2}, uses=60}
        }
    }
})

minetest.register_tool("stl_core:wood_shovel", {
    description = "Wood Shovel",
    inventory_image = "default_tool_woodshovel.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        groupcaps = {
            crumbly = {times={0.8, 1.6}, uses=60}
        }
    }
})

minetest.register_tool("stl_core:wood_axe", {
    description = "Wood Axe",
    inventory_image = "default_tool_woodaxe.png",
    tool_capabilities = {
        full_punch_interval = 1.5,
        groupcaps = {
            snappy = {times={0.4, 0.8}, uses=60},
            choppy = {times={0.8, 1.6}, uses=60}
        }
    }
})

minetest.register_craft({
    output = "stl_core:wood_pick",
    recipe = {
        {"stl_core:wood", "stl_core:wood", "stl_core:wood"},
        {"", "stl_core:stick", ""},
        {"", "stl_core:stick", ""}
    }
})

minetest.register_craft({
    output = "stl_core:wood_shovel",
    recipe = {
        {"stl_core:wood"},
        {"stl_core:stick"},
        {"stl_core:stick"}
    }
})

minetest.register_craft({
    output = "stl_core:wood_axe",
    recipe = {
        {"stl_core:wood", "stl_core:wood"},
        {"stl_core:wood", "stl_core:stick"},
        {"", "stl_core:stick"}
    }
})

minetest.register_tool("stl_core:stone_pick", {
    description = "Stone Pick",
    inventory_image = "default_tool_stonepick.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        groupcaps = {
            cracky = {times={1, 2, 4}, uses=100}
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
            snappy = {times={0.25, 0.5}, uses=100},
            choppy = {times={0.5, 1}, uses=100}
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

minetest.register_tool("stl_core:copper_pick", {
    description = "Copper Pick",
    inventory_image = "default_tool_bronzepick.png",
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {
            cracky = {times={0.5, 1, 2, 3}, uses=100}
        }
    }
})

minetest.register_tool("stl_core:copper_shovel", {
    description = "Copper Shovel",
    inventory_image = "default_tool_bronzeshovel.png",
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {
            crumbly = {times={0.25, 0.5}, uses=100}
        }
    }
})

minetest.register_tool("stl_core:copper_axe", {
    description = "Copper Axe",
    inventory_image = "default_tool_bronzeaxe.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        groupcaps = {
            snappy = {times={0.1, 0.2}, uses=100},
            choppy = {times={0.25, 0.5}, uses=100}
        }
    }
})

minetest.register_craft({
    output = "stl_core:copper_pick",
    recipe = {
        {"stl_core:copper", "stl_core:copper", "stl_core:copper"},
        {"", "stl_core:stick", ""},
        {"", "stl_core:stick", ""}
    }
})

minetest.register_craft({
    output = "stl_core:copper_shovel",
    recipe = {
        {"stl_core:copper"},
        {"stl_core:stick"},
        {"stl_core:stick"}
    }
})

minetest.register_craft({
    output = "stl_core:copper_axe",
    recipe = {
        {"stl_core:copper", "stl_core:copper"},
        {"stl_core:copper", "stl_core:stick"},
        {"", "stl_core:stick"}
    }
})

minetest.register_tool("stl_core:titanium_pick", {
    description = "Titanium Pick",
    inventory_image = "default_tool_steelpick.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        groupcaps = {
            cracky = {times={0.8, 1.6, 3.2, 4.8}, uses=180}
        }
    }
})

minetest.register_tool("stl_core:titanium_shovel", {
    description = "Titanium Shovel",
    inventory_image = "default_tool_steelshovel.png",
    tool_capabilities = {
        full_punch_interval = 1.2,
        groupcaps = {
            crumbly = {times={0.4, 0.8}, uses=180}
        }
    }
})

minetest.register_tool("stl_core:titanium_axe", {
    description = "Titanium Axe",
    inventory_image = "default_tool_steelaxe.png",
    tool_capabilities = {
        full_punch_interval = 1.5,
        groupcaps = {
            snappy = {times={0.2, 0.4}, uses=180},
            choppy = {times={0.4, 0.8}, uses=180}
        }
    }
})

minetest.register_craft({
    output = "stl_core:titanium_pick",
    recipe = {
        {"stl_core:titanium", "stl_core:titanium", "stl_core:titanium"},
        {"", "stl_core:stick", ""},
        {"", "stl_core:stick", ""}
    }
})

minetest.register_craft({
    output = "stl_core:titanium_shovel",
    recipe = {
        {"stl_core:titanium"},
        {"stl_core:stick"},
        {"stl_core:stick"}
    }
})

minetest.register_craft({
    output = "stl_core:titanium_axe",
    recipe = {
        {"stl_core:titanium", "stl_core:titanium"},
        {"stl_core:titanium", "stl_core:stick"},
        {"", "stl_core:stick"}
    }
})

--Resource blocks for metals and stuff
minetest.register_node("stl_core:copper_block", {
    description = "Copper Block",
    tiles = {"default_copper_block.png"},
    groups = {cracky=3, spaceship=1},
    sounds = stellua.node_sound_metal_defaults()
})

minetest.register_node("stl_core:titanium_block", {
    description = "Titanium Block",
    tiles = {"default_tin_block.png"},
    groups = {cracky=3, spaceship=1},
    sounds = stellua.node_sound_metal_defaults()
})

minetest.register_craft({
    output = "stl_core:copper_block",
    recipe = {
        {"stl_core:copper", "stl_core:copper"},
        {"stl_core:copper", "stl_core:copper"}
    }
})

minetest.register_craft({
    output = "stl_core:titanium_block",
    recipe = {
        {"stl_core:titanium", "stl_core:titanium"},
        {"stl_core:titanium", "stl_core:titanium"}
    }
})

minetest.register_craft({
    type = "shapeless",
    output = "stl_core:copper 4",
    recipe = {"stl_core:copper_block"}
})

minetest.register_craft({
    type = "shapeless",
    output = "stl_core:titanium 4",
    recipe = {"stl_core:titanium_block"}
})