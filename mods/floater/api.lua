--Get list of hitboxes for node
function floater.get_boxes(nodebox, defs, param2, connections)
    if not nodebox or nodebox.type == "regular" then
        return {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    elseif nodebox.type == "fixed" then
        return nodebox.fixed
    elseif nodebox.type == "wallmounted" then
        if defs.paramtype2 ~= "wallmounted" or param2 == 0 then return nodebox.wall_top or {-0.5, 0.4375, -0.5, 0.5, 0.5, 0.5}
        elseif param2 == 1 then return nodebox.wall_bottom or {-0.5, -0.5, -0.5, 0.5, -0.4375, 0.5}
        else return nodebox.wall_side or {-0.5, -0.5, 0.4375, 0.5, 0.5, 0.5} end
    elseif nodebox.type == "connected" then
        connections = connections or {}
        local out = nodebox.fixed
        if type(out[1]) ~= "table" then out = {out} end
        for i, side in ipairs({"bottom", "top", "right", "left", "back", "front"}) do
            local c, dc = nodebox["connect_"..side], nodebox["disconnect_"..side]
            if connections[i] then
                if c then
                    if type(c[1]) == "table" then table.insert_all(out, c) else table.insert(out, c) end
                end
            elseif dc then
                if type(c[1]) == "table" then table.insert_all(out, dc) else table.insert(out, dc) end
            end
        end
        return out
    else
        return {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
    end
end

--Get single hitbox for node object
function floater.get_box(nodebox, defs, param2, connections)
    return floater.utils.rotate_box(floater.utils.bounding_box(floater.get_boxes(nodebox, defs, param2, connections)), {param2=param2}, defs)
end

--Get object properties based on node defs
function floater.get_props(node, defs, connections)
    local out = {
        visual = "sprite",
        textures = {"blank.png"},
        physical = false,
        is_visible = false
    }

    if defs and defs.drawtype ~= "airlike" then
        --set up default props for most types
        out.visual = "mesh"
        out.visual_size = {x=10, y=10}
        out.textures = defs.tiles
        for i, texture in ipairs(out.textures) do
            if type(texture) == "table" then
                out.textures[i] = texture.name
            end
        end
        out.physical = defs.walkable
        out.collisionbox = floater.get_box(defs.collision_box, defs, node.param2, connections)
        out.selectionbox = floater.get_box(defs.selection_box, defs, node.param2, connections)
        --BUG: selection_box from defs contains an erroneous fixed box with full block size, collision_box doesn't though
        out.is_visible = true

        --ordinary cube with all faces visible (disappearing faces will be taken care of by the floater)
        if defs.drawtype == "normal" or defs.drawtype == "allfaces" or defs.drawtype == "allfaces_optional"
        or defs.drawtype == "glasslike" or (defs.drawtype == "nodebox" and defs.node_box.type == "regular") then
            out.visual = "cube"
            out.visual_size = {x=1, y=1}
            while #out.textures < 6 do
                table.insert(out.textures, out.textures[#out.textures])
            end

        --similar but sorting out the textures for glasslike_framed nodes
        elseif defs.drawtype == "glasslike_framed" or defs.drawtype == "glasslike_framed_optional" then
            out.visual = "cube"
            out.visual_size = {x=1, y=1}
            local texture = defs.tiles[1].."^"..defs.tiles[2]
            out.textures = {texture, texture, texture, texture, texture, texture}

        --grass-like node with several faces in a cross shape (currently only the default)
        elseif defs.drawtype == "plantlike" then
            out.mesh = "plantlike.obj"

        --ladder-like node with one face against the bottom of the node
        elseif defs.drawtype == "signlike" then
            out.mesh = "signlike.obj"

        --nodebox node, having been converted to a mesh earlier
        elseif defs.drawtype == "nodebox" and defs.node_box.type ~= "regular" then
            out.mesh = floater.get_nodebox_mesh(node.name, connections)

        --basic mesh node
        elseif defs.drawtype == "mesh" then
            out.mesh = defs.mesh

        --if drawtype unsupported, show as airlike
        else
            out.is_visible = false
        end
    end

    return out
end

--Get whether two nodes connect to each other for purposes of forming floaters
function floater.can_connect(node1, node2, dir, push_dir)
    --check a few obvious cases: air, fluids, other game-specific stuff maybe
    if node2.name == "air" or minetest.registered_nodes[node2.name].liquidtype ~= "none" then
        return false
    end

    --check if this is the push direction
    if dir == push_dir then
        return true
    end

    --make sure the nodes allow connection that way
    if node1.name == "floaticator:floaticator_on" and minetest.wallmounted_to_dir(node1.param2) ~= dir
    or node2.name == "floaticator:floaticator_on" and minetest.wallmounted_to_dir(node2.param2) ~= dir then
        return false
    end

    --make sure the nodes are touching each other
    local mult = dir.x+dir.y+dir.z
    local defs1 = minetest.registered_nodes[node1.name]
    local defs2 = minetest.registered_nodes[node2.name]
    local connections = {true, true, true, true, true, true} --placeholder
    local side1 = floater.get_box(defs1.selection_box, defs1, node1.param2, connections)[floater.utils.dir_to_face(dir)] or mult*0.5
    local side2 = floater.get_box(defs2.selection_box, defs2, node2.param2, connections)[floater.utils.dir_to_face(-dir)] or -mult*0.5
    if side1*mult < 0.5 or side2*-mult < 0.5 then
        return false
    end

    return true
end

--Get whether a node is movable
function floater.can_move(node)
    return node.name ~= "ignore"
end

--Entity representing a node, with all the necessary collision and stuff
minetest.register_entity("floater:node", {
    initial_properties = floater.get_props(),
    node = {},
    node_defs = {},
    set_node = function (self, node)
        node = node or self.node
        if not node or not node.name then self.object:remove() return end
        local node_defs = minetest.registered_nodes[node.name]
        if node_defs.drawtype == "nodebox" and node_defs.node_box.type == "connected" then
            self.connections = self.connections or {false, false, false, false, false, false}
        else
            self.connections = nil
        end
        self.object:set_properties(floater.get_props(node, node_defs, self.connections))
        self.object:set_rotation(floater.utils.get_rotation(node, node_defs))
        self.node = node
        self.node_defs = node_defs
    end,
    on_activate = function (self, staticdata)
        if not staticdata or staticdata == "" then self.object:remove() return end
        self:set_node(minetest.deserialize(staticdata))
        self.object:set_armor_groups({immortal=1})
    end,
    get_staticdata = function (self)
        return minetest.serialize(self.node)
    end,
    connect = function (self, face, node)
        local defs = minetest.registered_nodes[node.name] or {}
        local opaque = defs.drawtype == "normal" --placeholder
        local drawtype = self.node_defs.drawtype
        if (((self.node.name == node.name or opaque) and (drawtype == "glasslike"
        or drawtype == "glasslike_framed" or drawtype == "glasslike_framed_optional"))
        or (drawtype == "normal" and opaque))
        and self.object:get_rotation() == vector.zero() then --temporary fix for rotations
            local props = self.object:get_properties()
            props.textures[face] = "blank.png"
            self.object:set_properties(props)
        elseif self.connections and self.node.name == node.name then
            self.connections[face] = true
            self:set_node()
        end
    end
})

--Collection of node objects considered as one entity
minetest.register_entity("floater:floater", {
    initial_properties = {
        visual = "sprite",
        textures = {"blank.png"},
        physical = false
    },
    node_data = {}, --schematics not used because of the contact system: it might overlap other stuff
    node_timers = {},
    metadata = {},
    on_activate = function (self, staticdata, dtime)
        if staticdata and staticdata ~= "" then
            self.node_data, self.node_timers, self.metadata = unpack(minetest.deserialize(staticdata))
            local selfpos = self.object:get_pos()
            for _, pair in ipairs(self.node_data) do
                local obj = minetest.add_entity(selfpos, "floater:node", minetest.serialize(pair[2]))
                obj:set_attach(self.object, "", vector.multiply(pair[1], 10), -vector.apply(floater.utils.get_rotation(pair[2]), math.deg), false)
            end
            self:update_connects()
        else
            self.object:remove()
            return
        end
        self.object:set_armor_groups({immortal=1})
    end,
    get_staticdata = function (self)
        return minetest.serialize({self.node_data, self.node_timers, self.metadata})
    end,
    dismantle = function (self)
        local selfpos = self.object:get_pos()
        for i, obj in ipairs(self.object:get_children()) do
            local pos = selfpos+({obj:get_attach()})[3]*0.1
            local node = obj:get_luaentity().node
            if node then
                obj:remove()
                minetest.set_node(pos, node)
            end
        end
        for _, val in ipairs(self.node_timers) do
            minetest.get_node_timer(val[1]+selfpos):set(val[2], val[3])
        end
        for _, val in ipairs(self.metadata) do
            local meta = minetest.get_meta(val[1]+selfpos)
            meta:from_table({fields=val[2], inventory=meta:to_table().inventory})
        end
        self.object:remove()
    end,
    on_punch = function (self, _, _, _, _, damage)
        if damage >= self.object:get_hp() then
            self:dismantle()
        end
    end,
    update_connects = function (self)
        for _, obj in ipairs(self.object:get_children()) do
            local entity = obj:get_luaentity()
            entity:set_node()
            local pos = ({obj:get_attach()})[3]*0.1
            for _, pair in ipairs(self.node_data) do
                if vector.distance(pair[1], pos) == 1 then
                    entity:connect(minetest.dir_to_wallmounted(pair[1]-pos)+1, pair[2])
                end
            end
        end
    end
})