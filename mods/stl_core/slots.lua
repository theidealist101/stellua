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
    minetest.log("action", "allocating slot "..index.." for player "..player.." (star="..star..")")
    return index, true
end

local DIAG = vector.new(300, 300, 300)

--Free up slot and clear area
function stellua.free_slot(index)
    slots[index] = nil
    storage:set_string("slots", minetest.serialize(slots))
    local pos = stellua.get_slot_pos(index)
    --minetest.delete_area(pos-DIAG, pos+DIAG) --takes far too long (is there a way to do it asynchronously?)
    minetest.log("action", "freeing slot "..index)
end

--Change slot that player is recognised as owning
function stellua.set_player_slot(player, index)
    local old_index = player_slots[player]
    player_slots[player] = index
    minetest.log("action", "setting slot of player "..player.." from "..dump(old_index).." to "..dump(index))

    --free up slot if unowned
    if not old_index then return end
    for _, i in pairs(player_slots) do
        if i == old_index then return end
    end
    stellua.free_slot(old_index)
end

--Get position of slot in-world
function stellua.get_slot_info(index)
    if not slots[index] then return end
    return unpack(slots[index])
end

--Make sure player owns their current slot on load
minetest.register_on_joinplayer(function (player)
    stellua.set_player_slot(player:get_player_name(), stellua.get_slot_index(player:get_pos()))
end)