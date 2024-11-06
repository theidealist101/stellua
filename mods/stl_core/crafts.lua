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

local function on_craft(itemstack, player, craft_grid)
    if itemstack:to_string() == "stl_core:pebble 4" then
        for _, ing in ipairs(craft_grid) do
            if ing:get_name() == "stl_core:cobble" then
                itemstack:get_meta():set_int("palette_index", ing:get_meta():get_int("palette_index"))
                return itemstack
            end
        end
    elseif itemstack:to_string() == "stl_core:cobble" then
        local pebbles = {}
        local col
        for i, ing in ipairs(craft_grid) do
            if ing:get_name() == "stl_core:pebble" then
                local newcol = ing:get_meta():get_int("palette_index")
                if not col then col = newcol elseif col ~= newcol then return ItemStack("") end
                table.insert(pebbles, i)
            end
        end
        itemstack:get_meta():set_int("palette_index", col)
        return itemstack
    end
end

minetest.register_craft_predict(on_craft)
minetest.register_on_craft(on_craft)

--Basic tools
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