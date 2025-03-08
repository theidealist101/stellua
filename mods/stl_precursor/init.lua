local modpath = minetest.get_modpath("stl_precursor").."/"

--Lots of nodes to incorporate into funky looking structures
minetest.register_node("stl_precursor:wall", {
    description = "Precursor Wall",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_wall.png"},
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:wall_stripe", {
    description = "Precursor Wall with Stripe",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_wall_stripe.png"},
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:column", {
    description = "Precursor Column",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_column.png"},
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:column_stripe", {
    description = "Precursor Column with Stripe",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_column_stripe.png"},
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:floor", {
    description = "Precursor Floor",
    drawtype = "signlike",
    selection_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, -0.375, 0.5}},
    tiles = {"stl_precursor_floor.png"},
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 5,
    walkable = false,
    pointable = false,
    groups = {attached_node=1, precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:podium", {
    description = "Precursor Podium",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.75, -0.501, -0.75, 0.75, 0.501, 0.75}},
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_wall_stripe.png"},
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:gate", {
    description = "Precursor Gate",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.5, -0.5, 0, 0.5, 0.5, 0}},
    selection_box = {type="fixed", fixed={-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625}},
    tiles = {"stl_precursor_gate.png^[opacity:128"},
    use_texture_alpha = "blend",
    inventory_image = "stl_precursor_gate.png",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 5,
    paramtype2 = "4dir",
    walkable = false,
    pointable = false,
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:beam", {
    description = "Precursor Beam",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}},
    selection_box = {type="fixed", fixed={-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}},
    tiles = {"blank.png", "blank.png", {name="stl_precursor_beam.png^[opacity:128", backface_culling=false}},
    use_texture_alpha = "blend",
    paramtype = "light",
    sunlight_propagates = true,
    --post_effect_color = "#ffa5a580",
    light_source = 5,
    walkable = false,
    pointable = false,
    climbable = true,
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:column_sigil", {
    description = "Precursor Column with Sigil",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_column_sigil.png"},
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:vigil_spawner", {
    description = "Vigil Spawner",
    drawtype = "airlike",
    groups = {precursor=1, not_in_creative_inventory=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults(),
    on_timer = function (pos)
        if minetest.add_entity(pos, "stl_precursor:vigil") then
            minetest.remove_node(pos)
        end
    end
})

minetest.register_node("stl_precursor:lamp", {
    description = "Precursor Lamp",
    tiles = {"stl_precursor_lamp.png"},
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14,
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:post", {
    description = "Precursor Post",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}},
    selection_box = {type="fixed", fixed={-0.125, -0.5, -0.125, 0.125, 0.5, 0.125}},
    tiles = {"stl_precursor_column.png"},
    paramtype = "light",
    sunlight_propagates = true,
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:air", {
    description = "Precursor Air",
    drawtype = "airlike",
    walkable = false,
    pointable = false,
    buildable_to = true,
    paramtype = "light",
    sunlight_propagates = true
})

minetest.register_node("stl_precursor:antenna_stem", {
    description = "Precursor Antenna Stem",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}},
    selection_box = {type="fixed", fixed={-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}},
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_antenna_stem.png"},
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:antenna_ring", {
    description = "Precursor Antenna Ring",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={{-1, -0.375, -1, 1, 0.375, 1}, {-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}}},
    selection_box = {type="fixed", fixed={{-1, -0.375, -1, 1, 0.375, 1}, {-0.375, -0.5, -0.375, 0.375, 0.5, 0.375}}},
    tiles = {"stl_precursor_antenna_ring_top.png", "stl_precursor_antenna_ring_top.png", "stl_precursor_antenna_ring.png"},
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:antenna", {
    description = "Precursor Antenna",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.75, -0.75, -0.75, 0.75, 0.75, 0.75}},
    selection_box = {type="fixed", fixed={-0.75, -0.75, -0.75, 0.75, 0.75, 0.75}},
    tiles = {"stl_precursor_antenna.png"},
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 14,
    groups = {precursor=1},
    pointabilities = {nodes={["group:precursor"]=true}},
    sounds = stellua.node_sound_stone_defaults(),
    on_timer = function (pos)
        --will put sound play here but haven't found a good one yet
        minetest.get_node_timer(pos):start(20)
    end
})

--Tool for breaking precursor buildings
minetest.register_tool("stl_precursor:magic_stick", {
    description = "Magic Stick",
    inventory_image = "stl_precursor_magic_stick.png",
    pointabilities = {nodes={["group:precursor"]=true}},
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {precursor={uses=0, times={0.1}}}
    }
})

--[[
--Some rooms to spawn around randomly on the surface
minetest.register_decoration({
    deco_type = "schematic",
    place_on = "group:ground",
    fill_ratio = 0.0000005,
    place_offset_y = -2,
    schematic = modpath.."schems/precursor_assembler_room.mts",
    flags = "place_center_x, place_center_z, force_placement, all_floors"
})]]

--Generate precursor structures on generation
minetest.register_mapgen_script(modpath.."mapgen_env.lua")

--Make sure generated nodes are running smoothly
minetest.register_abm({
    nodenames = {"stl_precursor:antenna", "stl_precursor:vigil_spawner"},
    interval = 2,
    chance = 1,
    action = function (pos)
        local timer = minetest.get_node_timer(pos)
        if not timer:is_started() then timer:start(0) end
    end
})

--Vigils, little turret things that shoot at the player when in line of sight
minetest.register_entity("stl_precursor:vigil", {
    initial_properties = {
        visual = "mesh",
        visual_size = {x=15, y=15},
        mesh = "stl_precursor_vigil.gltf",
        textures = {"stl_precursor_vigil.png"},
        glow = 5,
        physical = true,
        collisionbox = {-0.5, -0.25, -0.5, 0.5, 0.25, 0.5},
        selectionbox = {-0.5, -0.25, -0.5, 0.5, 0.25, 0.5}
    }
})