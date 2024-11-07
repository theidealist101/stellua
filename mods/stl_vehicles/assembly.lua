--Assemble a vehicle from any node
function stellua.assemble_vehicle(pos)
    local checking = {pos}
    local checked = {}
    local out = {}
    local seat

    while #checking > 0 and #out < 1000 do
        local p = table.remove(checking, 1)
        table.insert(checked, minetest.hash_node_position(p))
        local nodename = minetest.get_node(p).name
        local s = minetest.get_item_group(nodename, "spaceship")
        if s > 0 then table.insert(out, p) end
        if s > 0 or nodename == "air" then
            if s == 1 then
                for i = 0, 5 do
                    local newp = p+minetest.wallmounted_to_dir(i)
                    if table.indexof(checked, minetest.hash_node_position(newp)) <= 0 then
                        table.insert(checking, newp)
                    end
                end
            end
            if minetest.get_item_group(nodename, "seat") > 0 then
                if seat and seat ~= p then return else seat = p end
            end
        end
    end

    if #out < 1000 and seat then return out, seat end
end

--Make the player enter vehicles on rightclick
minetest.register_on_mods_loaded(function()
    for name, defs in pairs(minetest.registered_nodes) do
        if minetest.get_item_group(name, "spaceship") > 0 then
            local on_rightclick = defs.on_rightclick
            minetest.override_item(name, {on_rightclick = function (pos, node, user, itemstack, pointed)
                if on_rightclick then on_rightclick(pos, node, user)
                elseif (itemstack:is_empty() or not ({minetest.item_place_node(itemstack, user, pointed)})[2]) and not stellua.assemble_vehicle(user:get_pos()) then
                    local ship, seat = stellua.assemble_vehicle(pos)
                    if seat then
                        user:set_pos(seat-vector.new(0, 0.5, 0))
                    end
                end
            end})
        end
    end
end)

local UP = vector.new(0, 1, 0)

--The same for leaving vehicles on aux1
minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = vector.round(player:get_pos())
        if player:get_player_control().aux1 and stellua.assemble_vehicle(pos) then
            local dir = player:get_look_dir()
            while stellua.assemble_vehicle(pos) do
                pos = vector.round(pos+dir)
            end
            while minetest.registered_nodes[minetest.get_node(pos).name].walkable
            or minetest.registered_nodes[minetest.get_node(pos+UP).name].walkable do
                pos = pos+UP
            end
            while not minetest.registered_nodes[minetest.get_node(pos).name].walkable do
                pos = pos-UP
            end
            player:set_pos(pos+0.5*UP)
        end
    end
end)