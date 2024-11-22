local default = stellua

--The following is borrowed directly from functions.lua in Minetest Game, see LICENSE.txt

function default.node_sound_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "", gain = 1.0}
	tbl.dug = tbl.dug or
			{name = "default_dug_node", gain = 0.25}
	tbl.place = tbl.place or
			{name = "default_place_node_hard", gain = 1.0}
	return tbl
end

function default.node_sound_stone_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_hard_footstep", gain = 0.2}
	tbl.dug = tbl.dug or
			{name = "default_hard_footstep", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_dirt_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_dirt_footstep", gain = 0.25}
	tbl.dig = tbl.dig or
			{name = "default_dig_crumbly", gain = 0.4}
	tbl.dug = tbl.dug or
			{name = "default_dirt_footstep", gain = 1.0}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_sand_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_sand_footstep", gain = 0.05}
	tbl.dug = tbl.dug or
			{name = "default_sand_footstep", gain = 0.15}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_gravel_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_gravel_footstep", gain = 0.25}
	tbl.dig = tbl.dig or
			{name = "default_gravel_dig", gain = 0.35}
	tbl.dug = tbl.dug or
			{name = "default_gravel_dug", gain = 1.0}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_wood_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_wood_footstep", gain = 0.15}
	tbl.dig = tbl.dig or
			{name = "default_dig_choppy", gain = 0.4}
	tbl.dug = tbl.dug or
			{name = "default_wood_footstep", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_leaves_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_grass_footstep", gain = 0.45}
	tbl.dug = tbl.dug or
			{name = "default_grass_footstep", gain = 0.7}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_glass_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_glass_footstep", gain = 0.3}
	tbl.dig = tbl.dig or
			{name = "default_glass_footstep", gain = 0.5}
	tbl.dug = tbl.dug or
			{name = "default_break_glass", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_ice_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_ice_footstep", gain = 0.15}
	tbl.dig = tbl.dig or
			{name = "default_ice_dig", gain = 0.5}
	tbl.dug = tbl.dug or
			{name = "default_ice_dug", gain = 0.5}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_metal_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_metal_footstep", gain = 0.2}
	tbl.dig = tbl.dig or
			{name = "default_dig_metal", gain = 0.5}
	tbl.dug = tbl.dug or
			{name = "default_dug_metal", gain = 0.5}
	tbl.place = tbl.place or
			{name = "default_place_node_metal", gain = 0.5}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_water_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_water_footstep", gain = 0.2}
	default.node_sound_defaults(tbl)
	return tbl
end

function default.node_sound_snow_defaults(tbl)
	tbl = tbl or {}
	tbl.footstep = tbl.footstep or
			{name = "default_snow_footstep", gain = 0.2}
	tbl.dig = tbl.dig or
			{name = "default_snow_footstep", gain = 0.3}
	tbl.dug = tbl.dug or
			{name = "default_snow_footstep", gain = 0.3}
	tbl.place = tbl.place or
			{name = "default_place_node", gain = 1.0}
	default.node_sound_defaults(tbl)
	return tbl
end
