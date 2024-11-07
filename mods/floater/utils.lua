--Convert array of connections to bitmask and vice versa
function floater.utils.pack_connections(connections)
    return (connections[1] and 32 or 0)
    +(connections[2] and 16 or 0)
    +(connections[3] and 8 or 0)
    +(connections[4] and 4 or 0)
    +(connections[5] and 2 or 0)
    +(connections[6] and 1 or 0)
end

function floater.utils.unpack_connections(cp)
    return {cp%64 >= 32, cp%32 >= 16, cp%16 >= 8, cp%8 >= 4, cp%4 >= 2, cp%2 >= 1}
end

--Convert direction vector to side of nodebox
function floater.utils.dir_to_face(dir)
    return table.indexof({
        vector.new(-1, 0, 0),
        vector.new(0, -1, 0),
        vector.new(0, 0, -1),
        vector.new(1, 0, 0),
        vector.new(0, 1, 0),
        vector.new(0, 0, 1)
    }, dir)
end

--Turn a bunch of nodeboxes into a single box surrounding all of them
function floater.utils.bounding_box(boxes)
    if not boxes then return end
    if type(boxes[1]) == "table" then
        local out = boxes[1]
        for i, box in ipairs(boxes) do
            for c = 1, 3 do
                out[c] = math.min(out[c], box[c])
            end
            for c = 4, 6 do
                out[c] = math.max(out[c], box[c])
            end
        end
        return out
    else
        return boxes
    end
end

--Get rotation of node from param2 and defs
function floater.utils.get_rotation(node, defs)
    defs = defs or minetest.registered_nodes[node.name]
    local param2 = node.param2
    local paramtype2 = defs.paramtype2
    if paramtype2 == "wallmounted" then
        return vector.dir_to_rotation(minetest.wallmounted_to_dir(param2))+vector.new(math.pi*0.5, 0, 0)
    elseif paramtype2 == "4dir" then
        return vector.dir_to_rotation(minetest.fourdir_to_dir(param2))
    elseif paramtype2 == "facedir" then
        return vector.dir_to_rotation(minetest.facedir_to_dir(param2))
    else
        return vector.zero()
    end
end

--Rotate a single nodebox (can't just use rotate=true, that doesn't work for collision boxes)
function floater.utils.rotate_box(box, node, defs)
    box = table.copy(box)
    local rotation = floater.utils.get_rotation(node, defs)
    --do some matrix multiplication to rotate the nodebox
    local cos, sin = math.cos(rotation.y), math.sin(rotation.y)
    box = {
        cos*box[1]-sin*box[3], box[2], sin*box[1]+cos*box[3],
        cos*box[4]-sin*box[6], box[5], sin*box[4]+cos*box[6]
    }
    box = {
        math.min(box[1], box[4]),
        math.min(box[2], box[5]),
        math.min(box[3], box[6]),
        math.max(box[1], box[4]),
        math.max(box[2], box[5]),
        math.max(box[3], box[6])
    }
    return box
end