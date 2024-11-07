--Convert a nodebox into a mesh file and output that as a string
function floater.nodebox_to_mesh(boxes)
    if type(boxes[1]) ~= "table" then boxes = {boxes} end
    --convert all to mesh parts
    local out = {
        "# Auto-generated from nodebox by Floater API",
        "usemtl none",
        "vn 0 1 0",
        "vn 0 -1 0",
        "vn 1 0 0",
        "vn -1 0 0",
        "vn 0 0 1",
        "vn 0 0 -1",
    }
    local faces = {{}, {}, {}, {}, {}, {}}
    for i, box in ipairs(boxes) do
        --vertices, order ---, --+, -+-, -++, +--, +-+, ++-, +++
        for _, x in ipairs({-box[4], -box[1]}) do
            for _, y in ipairs({box[2], box[5]}) do
                for _, z in ipairs({box[3], box[6]}) do
                    table.insert(out, table.concat({"v", x, y, z}, " "))
                end
            end
        end
        --textures, same order as coords in faces
        for j = 1, 6 do
            local uv --u1, u2, v1, v2
            if j <= 2 then
                uv = {box[1], box[4], box[3], box[6]} --no y: uv=xz
            elseif j <= 4 then
                uv = {box[3], box[6], box[2], box[5]} --no x: uv=zy
            else
                uv = {box[1], box[4], box[2], box[5]} --no z: uv=xy
            end
            if j == 2 or j == 4 or j == 5 then --I have no fucking clue why this works but it does
                uv = {-uv[2], -uv[1], uv[3], uv[4]}
                if j == 2 then
                    uv = {-uv[1], -uv[2], -uv[3], -uv[4]}
                end
            end
            uv = {uv[1]+0.5, uv[2]+0.5, uv[3]+0.5, uv[4]+0.5}
            table.insert_all(out, {
                table.concat({"vt", uv[2], uv[3]}, " "),
                table.concat({"vt", uv[2], uv[4]}, " "),
                table.concat({"vt", uv[1], uv[4]}, " "),
                table.concat({"vt", uv[1], uv[3]}, " ")
            })
        end
        --faces, should be the same for any box
        table.insert(faces[1], {3, 4, 8, 7})
        table.insert(faces[2], {5, 6, 2, 1})
        table.insert(faces[3], {2, 4, 3, 1})
        table.insert(faces[4], {5, 7, 8, 6})
        table.insert(faces[5], {6, 8, 4, 2})
        table.insert(faces[6], {1, 3, 7, 5})
    end
    --add back in the faces
    for i, side in ipairs(faces) do
        table.insert(out, "g m"..i)
        for j, face in ipairs(side) do
            local face_string = {"f "}
            for k, v in ipairs(face) do
                table.insert_all(face_string, {
                    (j-1)*8+v, "/",
                    (j-1)*24+(i-1)*4+k, "/",
                    i, " "
                })
            end
            table.insert(out, table.concat(face_string))
        end
    end

    return table.concat(out, "\n")
end

--Actually do the converting for everything and save as files
local nodebox_meshes = {}

local function save_nodebox(node, defs, cp)
    local name = table.concat(string.split(node, ":"), "_")..(cp or "")..".obj"
    local file = floater.utils.get_nodebox_file(name)
    if file then
        local connections = cp and floater.utils.unpack_connections(cp)
        local boxes = floater.get_boxes(defs.node_box, defs, node.param2, connections)
        local mesh = floater.nodebox_to_mesh(boxes)
        if mesh and file:write(mesh) then
            if cp then nodebox_meshes[node][cp] = name
            else nodebox_meshes[node] = name end
        end
        file:close()
    end
end

local function save_nodeboxes()
    for node, defs in pairs(minetest.registered_nodes) do
        if defs.drawtype == "nodebox" and defs.node_box.type ~= "regular" then
            if defs.node_box.type == "connected" then
                nodebox_meshes[node] = {}
                for connect_packed = 0, 63 do
                    save_nodebox(node, defs, connect_packed)
                end
            else
                save_nodebox(node, defs)
            end
        end
    end
end

minetest.register_on_mods_loaded(save_nodeboxes)

--Retrieve name of mesh file for node with given connections
function floater.get_nodebox_mesh(nodename, connections)
    local out = nodebox_meshes[nodename]
    if connections then out = out[floater.utils.pack_connections(connections)] end
    return out
end