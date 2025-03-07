--Remember slot usage in mod storage
local storage = minetest.get_mod_storage()
local slots = minetest.deserialize(storage:get_string("slots")) or {}
local player_slots = {}

--Quickly convert slot index to actual position
function stellua.get_slot_pos(index)
    return vector.new((index-1)%61-30, 0, math.ceil(index/61)-31)*1000
end

--Quickly convert actual position to slot index
function stellua.get_slot_index(pos)
    if pos.y < -500 or pos.y >= 500 then return end
    pos = vector.round(pos*0.001)
    return pos.x+31+(pos.z+30)*61
end

--Allocate slot to a player
function stellua.alloc_slot(player, star, pos, rot)
    if player_slots[player] then return player_slots[player], false end
    local index = #slots+1
    slots[index] = {star, pos, rot}
    player_slots[player] = index
    storage:set_string("slots", minetest.serialize(slots))
    return index, true
end

--Free up slot and clear area
function stellua.free_slot(index)
    slots[index] = nil
    storage:set_string("slots", minetest.serialize(slots))
end

--Get position of slot in-world
function stellua.get_slot_info(index)
    if not slots[index] then return end
    return unpack(slots[index])
end