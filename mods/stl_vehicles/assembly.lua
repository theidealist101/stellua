--Remember the next inventory id
local storage = minetest.get_mod_storage()
local inv_count = storage:get_int("inv_count")

--Override static saving functions for LVAE to allow saving more arbitrary data
local lvae_defs = minetest.registered_entities["lvae:lvae"]

local old_get_staticdata = lvae_defs.get_staticdata
local old_on_activate = lvae_defs.on_activate
--local old_on_step = lvae_defs.on_step

function lvae_defs.get_staticdata(self)
    return minetest.serialize({old_get_staticdata(self), self.player, self.power, self.tanks, self.collisionbox})
end

function lvae_defs.on_activate(self, staticdata, dtime)
    if staticdata and staticdata ~= "" and not tonumber(staticdata) then
        staticdata, self.player, self.power, self.tanks, self.collisionbox = unpack(minetest.deserialize(staticdata))
        self.object:set_properties({physical=true, collisionbox=self.collisionbox})
    end
    return old_on_activate(self, staticdata, dtime)
end

function lvae_defs.on_step(self, dtime)
    local player = self.player and minetest.get_player_by_name(self.player)
    if player and not player:get_attach() then
        player:set_attach(self.object)
    end
    --return old_on_step(self, dtime)
end

--Override placing and digging functions, we don't want that
local lvae_node_defs = minetest.registered_entities["lvae:node"]
lvae_node_defs.on_rightclick = nil
lvae_node_defs.on_punch = nil

--Assemble a vehicle from any node
function stellua.assemble_vehicle(pos)
    local checking = {pos}
    local checked = {minetest.hash_node_position(pos)}
    local out = {}
    local seat
    local engines = {}
    local tanks = {}
    local power = 0

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
            if minetest.get_item_group(nodename, "tank") > 0 then
                table.insert(tanks, p)
            end
            local engine_power = minetest.get_item_group(nodename, "engine")
            if engine_power > 0 then
                table.insert(engines, p)
                power = power+engine_power
            end
        end
    end

    if #out < 1000 and seat then return out, seat, engines, power, tanks end
end

--Detach a vehicle and return the LVAE
function stellua.detach_vehicle(pos)
    local lvae = LVAE(pos)
    local minp, maxp
    local ship, seat, engines, power, tanks = stellua.assemble_vehicle(vector.round(pos))
    lvae.power = power
    lvae.tanks = {}
    for _, p in ipairs(tanks or {}) do
        local inv = minetest.create_detached_inventory("spaceship_inv"..inv_count, {})
        local meta = minetest.get_meta(p)
        inv:set_lists(meta:get_inventory():get_lists())
        table.insert(lvae.tanks, {p-pos, "spaceship_inv"..inv_count, meta:get_float("fuel"), meta:get_string("fuel_group")})
        inv_count = inv_count+1
        storage:set_int("inv_count", inv_count)
    end
    for _, p in ipairs(ship or {}) do
        lvae:set_node(p-pos, minetest.get_node(p))
        lvae.data[lvae.area:indexp(p-pos)].entity.object:set_properties({infotext=""})
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
    lvae.collisionbox = {minp.x-0.5, minp.y-0.5, minp.z-0.5, maxp.x+0.5, maxp.y+0.5, maxp.z+0.5}
    lvae.object:set_properties({physical=true, collisionbox=lvae.collisionbox})
    return lvae
end

--Reattach a vehicle to the node grid and destroy the LVAE
function stellua.land_vehicle(vehicle, pos)
    pos = pos or vehicle:get_pos()
    if vehicle.get_luaentity then vehicle = vehicle:get_luaentity() end
    for _, node in pairs(vehicle.data) do
        if node.entity then
            minetest.set_node(node.entity.pos+pos, node)
        end
    end
    for _, val in ipairs(vehicle.tanks) do
        local p, invname, fuel = unpack(val)
        local meta = minetest.get_meta(pos+p)
        meta:set_float("fuel", fuel)
        meta:set_string("infotext", "Fuel: "..math.ceil(fuel))
        local inv = minetest.get_inventory({type="detached", name=invname})
        if inv then
            meta:get_inventory():set_lists(inv:get_lists())
            minetest.remove_detached_inventory(invname)
        end
        --not working right now when you leave and rejoin lol
    end
    if vehicle.sound then minetest.sound_fade(vehicle.sound, 5, 0) end
    vehicle:remove()
end

--Try to get fuel from the stored data on vehicle fuel tanks
function stellua.get_fuel(tanks, amount, group)
    if amount == 0 then return true end
    group = group or "fuel"
    local ignite = false
    for _, val in ipairs(tanks) do
        local p, invname, fuel, fuel_group = unpack(val)
        if fuel_group == group then
            if fuel >= amount then val[3] = fuel-amount return true, ignite end
            local inv = minetest.get_inventory({type="detached", name=invname})
            if inv and not inv:is_empty("main") then
                for i, itemstack in ipairs(inv:get_list("main")) do
                    local new_fuel = minetest.get_item_group(itemstack:get_name(), group)
                    local replacement = itemstack:get_definition().fuel_replacement
                    while not itemstack:is_empty() and new_fuel > 0 do
                        ignite = true
                        fuel = fuel+new_fuel
                        itemstack:take_item()
                        inv:set_stack("main", i, itemstack)
                        if replacement then inv:add_item("main", ItemStack(replacement)) end
                        if fuel >= amount then val[3] = fuel-amount return true, ignite end
                    end
                end
            end
        end
    end
    return false, ignite
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
                        user:set_pos(seat)
                        minetest.sound_play({name="doors_steel_door_close", gain=0.2}, {pos=seat}, true)
                    end
                end
            end})
        end
    end
end)

--Detect if vehicle is on ground
local function on_ground(self, pos)
    pos = pos or vector.round(self.object:get_pos())
    local y = pos.y+math.round(self.collisionbox[2]-0.5)
    for x = pos.x+math.round(self.collisionbox[1]-0.5), pos.x+math.round(self.collisionbox[4]+0.5) do
        for z = pos.z+math.round(self.collisionbox[3]-0.5), pos.z+math.round(self.collisionbox[6]+0.5) do
            if minetest.registered_nodes[minetest.get_node(vector.new(x, y, z)).name].walkable then return true end
        end
    end
    return false
end

local UP = vector.new(0, 1, 0)
local NORTH = vector.new(0, 0, -1)

local ACCEL = 0.5
local FRICT = 0.2

local aux1s = {}

minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local pos = vector.round(player:get_pos())
        local index = stellua.get_planet_index(pos.y)
        local control = player:get_player_control()
        local playername = player:get_player_name()

        local aux1 = control.aux1 and not aux1s[playername]
        aux1s[playername] = control.aux1

        if (aux1 or control.jump) and stellua.assemble_vehicle(pos) then

            --make player exit on aux1
            if aux1 then
                --move forward until out of the vehicle
                local dir = player:get_look_dir()
                while stellua.assemble_vehicle(pos) do
                    pos = vector.round(pos+dir)
                end

                local attempts = 0

                --go up until there's space
                while (minetest.registered_nodes[minetest.get_node(pos).name].walkable
                or minetest.registered_nodes[minetest.get_node(pos+UP).name].walkable) and attempts < 8 do
                    pos = pos+UP
                    attempts = attempts+1
                end

                --if in outer space, skip placement
                if index then
                    --go down until there's something to stand on
                    while not minetest.registered_nodes[minetest.get_node(pos).name].walkable and attempts < 8 do
                        pos = pos-UP
                        attempts = attempts+1
                    end
                else pos = pos-UP end

                --if we could find a valid position then do it
                if attempts < 8 then
                    player:set_pos(pos+0.5*UP)
                    minetest.sound_play({name="doors_steel_door_close", gain=0.2}, {pos=pos}, true)
                end

            --make vehicle launch on jump
            elseif control.jump and index then
                local ent = stellua.detach_vehicle(pos)
                player:set_attach(ent.object)
                ent.player = playername
                minetest.sound_play({name="doors_door_close", gain=0.3}, {pos=pos}, true)
            end
        end

        --allow player to control vehicle
        local vehicle = player:get_attach()
        if vehicle then
            local ent = vehicle:get_luaentity()
            local y = vehicle:get_pos().y
            local rel_y = (y-500)%1000

            --land vehicle with aux1
            if aux1 and on_ground(ent, pos) then
                player:set_detach()
                player:set_pos(pos)
                minetest.sound_play({name="doors_door_close", gain=0.3}, {pos=vehicle:get_pos()}, true)
                stellua.land_vehicle(vehicle)
                stellua.set_respawn(player, pos)

            else
                --load up slot if above y=200
                if index and rel_y >= 700 then
                    local planet = stellua.planets[index]
                    local rot = (minetest.get_timeofday()+0.5)*2*math.pi
                    local slot = stellua.alloc_slot(playername, planet.star, planet.pos+0.15*planet.scale*vector.rotate_around_axis(UP, NORTH, -rot), vector.dir_to_rotation(vector.rotate_around_axis(UP, NORTH, rot)))
                    local slotpos = stellua.get_slot_pos(slot)
                    minetest.emerge_area(slotpos, slotpos)

                    --move to slot if above y=250
                    if rel_y >= 750 then
                        player:set_detach()
                        stellua.land_vehicle(ent, slotpos)
                        player:set_pos(slotpos)
                        stellua.set_respawn(player, slotpos)
                    end
                end

                if rel_y < 750 then
                    local vel = vehicle:get_velocity()
                    local power = vehicle:get_luaentity().power

                    --handle launching
                    local launch = control.jump and control.sneak
                    if launch then
                        local fuel, ignite = stellua.get_fuel(vehicle:get_luaentity().tanks, dtime*power)
                        if ignite then minetest.sound_play({name="fire_flint_and_steel", gain=0.2}, {object=vehicle}, true) end
                        if fuel or minetest.is_creative_enabled(playername) then vel.y = vel.y+ACCEL+power*0.1 else launch = false end
                    end
                    if not launch then
                        if control.jump and rel_y < 650 then vel.y = vel.y+ACCEL
                        elseif control.sneak then vel.y = vel.y-ACCEL end
                    end

                    --handle other controls
                    local rot = vector.new(0, player:get_look_horizontal(), 0)
                    if control.up then vel = vel+vector.rotate(vector.new(0, 0, ACCEL), rot) end
                    if control.down then vel = vel-vector.rotate(vector.new(0, 0, ACCEL), rot) end
                    if control.left then vel = vel-vector.rotate(vector.new(ACCEL, 0, 0), rot) end
                    if control.right then vel = vel+vector.rotate(vector.new(ACCEL, 0, 0), rot) end

                    --calculate velocity and apply
                    local xvel = vector.normalize(vector.new(vel.x, 0, vel.z))*math.min(math.max(math.hypot(vel.x, vel.z)-FRICT, 0), 8)
                    local yvel = vector.new(0, math.min(math.max(math.max(math.abs(vel.y)-FRICT, 0)*math.sign(vel.y), -8), 4+(launch and power or 0)), 0)
                    vehicle:set_velocity(xvel+yvel)
                    vehicle:set_rotation(rot)

                    --deal with sounds
                    if launch and ent.launch ~= true then
                        ent.launch = true
                        if ent.sound then minetest.sound_fade(ent.sound, 5, 0) end
                        ent.sound = minetest.sound_play({name="534856__m_cel__jet-engine", gain=0.5}, {loop=true, object=vehicle, fade=5})
                    elseif ent.launch ~= false and not launch then
                        ent.launch = false
                        if ent.sound then minetest.sound_fade(ent.sound, 5, 0) end
                        ent.sound = minetest.sound_play({name="242740__marlonhj__engine", gain=0.1}, {loop=true, object=vehicle, fade=5})
                    end
                end
            end
        end
    end
end)