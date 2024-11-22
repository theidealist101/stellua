local modpath = minetest.get_modpath("stl_precursor").."/"

--Lots of nodes to incorporate into funky looking structures
minetest.register_node("stl_precursor:wall", {
    description = "Precursor Wall",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_wall.png"},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:wall_stripe", {
    description = "Precursor Wall",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_wall_stripe.png"},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:column", {
    description = "Precursor Column",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_column.png"},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:column_stripe", {
    description = "Precursor Column",
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_column_stripe.png"},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:floor", {
    description = "Precursor Floor",
    drawtype = "signlike",
    tiles = {"stl_precursor_floor.png"},
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 5,
    walkable = false,
    pointable = false,
    groups = {attached_node=1},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:podium", {
    description = "Precursor Podium",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.75, -0.5, -0.75, 0.75, 0.5, 0.75}},
    tiles = {"stl_precursor_wall_top.png", "stl_precursor_wall_top.png", "stl_precursor_wall_stripe.png"},
    sounds = stellua.node_sound_stone_defaults()
})

minetest.register_node("stl_precursor:gate", {
    description = "Precursor Gate",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={-0.5, -0.5, 0, 0.5, 0.5, 0}},
    tiles = {"stl_precursor_gate.png^[opacity:128"},
    use_texture_alpha = "blend",
    inventory_image = "stl_precursor_gate.png",
    paramtype = "light",
    sunlight_propagates = true,
    light_source = 5,
    paramtype2 = "4dir",
    walkable = false,
    pointable = false,
    buildable_to = true,
    sounds = stellua.node_sound_stone_defaults()
})

--Some rooms to spawn around randomly on the surface
stellua.register_structure({
    schematic = modpath.."schems/precursor_assembler_room.mts",
    offset = -2
})