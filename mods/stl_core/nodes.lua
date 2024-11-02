--Basic stone variations used by all planets
for i = 1, 8 do
    minetest.register_node("stl_core:stone"..i, {
        description = "Stone "..i
    })
end