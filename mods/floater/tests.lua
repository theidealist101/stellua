--Debug tool to turn node into node object and vice versa
local function nodeify(_, _, pointed)
    if pointed.type == "node" then
        local node = minetest.get_node(pointed.under)
        minetest.remove_node(pointed.under)
        minetest.add_entity(pointed.under, "floater:node", minetest.serialize(node))
    elseif pointed.type == "object" then
        local pos = pointed.ref:get_pos()
        if pointed.ref:get_attach() then pos = pos+({pointed.ref:get_attach()})[3]*0.1 end
        local node = pointed.ref:get_luaentity().node
        if not node then return end
        pointed.ref:remove()
        minetest.set_node(pos, node)
    end
end

minetest.register_craftitem("floater:nodeifier", {
    description = "Nodeifier",
    inventory_image = "default_stick.png",
    groups = {not_in_creative_inventory=1},
    on_place = nodeify,
    on_secondary_use = nodeify
})

--Debug nodebox thing
minetest.register_node("floater:testcube", {
    description = "Test Cube",
    drawtype = "nodebox",
    tiles = {"testcube0.png", "testcube1.png", "testcube2.png", "testcube3.png", "testcube4.png", "testcube5.png"},
    node_box = {
        type = "fixed",
        fixed = {{-0.5, -0.5, -0.5, 0.5, 0, 0.5}, {-0.5, 0, -0.5, 0, 0.5, 0}}
    },
    groups = {cracky=3, not_in_creative_inventory=1}
})