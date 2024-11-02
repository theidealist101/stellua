--Override hand so it can break stuff
minetest.override_item("", {
    tool_capabilities = {
        full_punch_interval = 1,
        groupcaps = {
            crumbly = {times={2}}
        }
    }
})

--Basic stone variations used by all planets
for i = 1, 8 do
    minetest.register_node("stl_core:stone"..i, {
        description = "Stone "..i,
        tiles = {"stl_core_stone"..i..".png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {cracky=1}
    })
end

--Filler nodes
for i = 1, 8 do
    minetest.register_node("stl_core:filler"..i, {
        description = "Filler "..i,
        tiles = {"stl_core_filler"..i..".png"},
        paramtype2 = "color",
        palette = "palette.png",
        groups = {crumbly=1}
    })
end