--Assemble a vehicle from any node
function stellua.assemble_vehicle(pos)
    local checking = {pos}
    local checked = {minetest.hash_node_position(pos)}
    local out = {}
    local seat

    while #checking > 0 and #out < 1000 do
        local p = table.remove(checking, 1)
        local nodename = minetest.get_node(p).name
        local s = minetest.get_item_group(nodename, "spaceship")
        if s > 0 then table.insert(out, p) end
        if s > 0 or nodename == "air" then
            if s == 1 then
                for i = 0, 5 do
                    local newp = p+minetest.wallmounted_to_dir(i)
                    local hash = minetest.hash_node_position(newp)
                    if table.indexof(checked, hash) <= 0 then
                        table.insert(checking, newp)
                        table.insert(checked, hash)
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

--Detach a vehicle and return the LVAE
function stellua.detach_vehicle(pos)
    local lvae = LVAE(pos)
    local minp, maxp
    for _, p in ipairs(stellua.assemble_vehicle(vector.round(pos)) or {}) do
        lvae:set_node(p-pos, minetest.get_node(p))
        local node = lvae.data[lvae.area:indexp(p-pos)].entity.object
        node:set_pos(node:get_pos()+vector.new(0, 0.5, 0))
        minetest.remove_node(p)
        if not minp then minp = table.copy(p) else
            for _, d in ipairs({"x", "y", "z"}) do
                if p[d] < minp[d] then minp[d] = p[d] end
            end
        end
        if not maxp then maxp = table.copy(p) else
            for _, d in ipairs({"x", "y", "z"}) do
                if p[d] > maxp[d] then maxp[d] = p[d] end
            end
        end
    end
    minp, maxp = minp-pos, maxp-pos
    lvae.object:set_properties({physical=true, collisionbox={minp.x-0.5, minp.y-0.5, minp.z-0.5, maxp.x+0.5, maxp.y+0.5, maxp.z+0.5}})
    return lvae
end

--Reattach a vehicle to the node grid and destroy the LVAE
function stellua.land_vehicle(vehicle)
    local pos = vehicle:get_pos()
    for _, node in pairs(vehicle:get_luaentity().data) do
        if node.entity then
            minetest.set_node(node.entity.pos+pos, node)
        end
    end
    vehicle:get_luaentity():remove()
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

minetest.register_globalstep(function()
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = vector.round(player:get_pos())
        local control = player:get_player_control()
        if (control.aux1 or control.jump) and stellua.assemble_vehicle(pos) then
            --make player exit on aux1
            if control.aux1 then
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
            --make vehicle launch on jump
            elseif control.jump then
                player:set_attach(stellua.detach_vehicle(pos).object)
            end
        end

        --allow player to control vehicle
        local vehicle = player:get_attach()
        if vehicle then
            if control.aux1 then
                player:set_detach()
                stellua.land_vehicle(vehicle)
            else
                local vel = vehicle:get_velocity()
                local rot = vector.new(0, player:get_look_horizontal(), 0)
                if control.jump then vel.y = vel.y+1 end
                if control.sneak then vel.y = vel.y-1 end
                if control.up then vel = vel+vector.rotate(vector.new(0, 0, 1), rot) end
                if control.down then vel = vel-vector.rotate(vector.new(0, 0, 1), rot) end
                if control.left then vel = vel-vector.rotate(vector.new(1, 0, 0), rot) end
                if control.right then vel = vel+vector.rotate(vector.new(1, 0, 0), rot) end
                vel = vector.normalize(vel)*math.max(vector.length(vel)-0.5, 0)
                vel = vector.normalize(vector.new(vel.x, 0, vel.z))*math.min(vector.length(vel), 4)+vector.new(0, math.min(math.max(vel.y, -4), 10), 0)
                vehicle:set_velocity(vel)
                vehicle:set_rotation(rot)
            end
        end
    end
end)