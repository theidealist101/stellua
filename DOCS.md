Mapgen
======

Stellua divides the world into 61 slices, each 1000 nodes tall, of which the middle one y=-500 to y=500 is used for slots (see below), and the rest are used for planets.

Stars
-----

Each planet belongs to one of 16 star systems, randomly chosen.

* `stellua.stars`
    * List of star definitions, generated on world creation but after mods are loaded.

A star definition is a table with the following fields:

```lua
{
    name = "Name",
    --Randomly generated name shown in the menus and used for its planets

    seed = 15743796538,
    --Seed used for generation of its parameters

    scale = 1,
    --Visual size modifier of the star, modified in practice by distance from the star
    --Ranges from ~0.63 to ~1.58

    planets = {},
    --List of all planet indices which belong to this star

    pos = {x=0, y=0, z=0}
    --Position of star in space, in parsecs; determines where other stars are shown in the sky
    --Each element ranges from -2 to 2
}
```

Planets
-------

* `stellua.planets`
    * List of planet definitions, generated at the same time as stars.

* `stellua.get_planet_index(y)`
    * Returns the index of the planet which occupies the given y position in-world.

* `stellua.get_planet_level(index)`
    * Returns the y position in-world of the planet with the given index; specifically, the level of the middle of the slice.

* `stellua.registered_on_planets_generated`
    * List of functions to run when each planet is generated.

* `stellua.register_on_planet_generated(function(planet))`
    * Registers a function to be run when each planet is generated, with the planet definition as argument.
    * It is highly recommended to use `planet.seed` plus an arbitrary value in seeding any random numbers you use.

A planet definition is a table with the following fields:

```lua
{
    name = "Name I",
    --Randomly generated name shown in the menus

    seed = 9048282890398947,
    --Seed used for generation of its parameters

    star = 1,
    --Index of the star it belongs to

    level = -30000,
    --Y level of the planet, as obtained by stellua.get_planet_level

    heat_stat = 300,
    atmo_stat = 1,
    --Temperature in Kelvin and atmospheric pressure in atmospheres, as seen in planet info ingame
    --Temperature ranges from 100 to 500, pressure from 0 to 3

    life_stat = 0,
    --An abstract stat giving roughly how much different life is to be found on the planet
    --Displayed approximately in planet info as biodiversity levels
    --Automatically set to 0 for planets with low atmosphere or extreme temperatures

    dist = 1,
    --Distance from the star in astronomical units, estimated from temperature and pressure

    pos = {x=1, y=1, z=1},
    --Position relative to the star, in astronomical units

    sun = {visible=true, scale=1},
    --Table used for core.set_sun while on the planet

    sky = function(timeofday, height),
    --Gets table used for core.set_sky while on the planet

    stars = function(height),
    --Gets table used for core.set_stars while on the planet

    fog_dist = 200,
    --Fog distance on the planet, correlated with pressure

    scale = 1,
    --Visual scale modifier of the planet, correlated with both pressure and the scale of the terrain
    --Ranges from 0.25 to 2

    gravity = 1,
    walk_speed = 1,
    --Player movement modifiers, calculated directly from scale
    --Range from 0.125 to ~2.83 and ~0.35 to 1 respectively

    caves = true,
    --Whether caves are present on the planet

    craters = true,
    --Whether craters are present on the planet

    crater_chance = 1,
    crater_max_radius = 10,
    --Chance of a crater per chunk and maximum radius of craters respectively
    --Only present for planets where craters == true

    mapgen_stone = "stl_core:stone1",
    c_stone = 10,
    param2_stone = 128,
    --Name, content ID, and param2 value of the node used as stone in terrain

    mapgen_filler = "stl_core:filler1",
    c_filler = 11,
    param2_filler = 156,
    --Name, content ID, and param2 value of the node used as filler, replacing the top layers of stone

    depth_filler = 2,
    --Thickness of filler layer, ranges from 0 to 3

    water_level = -30000,
    --Y level of sea level
    --Set to nil if there is no surface liquid

    lava_level = -30450,
    --Y level below which all air is replaced with liquid
    --Set to nil if there is no underground liquid

    sulfur = "stl_core:sulfur",
    --Node spawned in blobs deep underground

    snow_type2 = "stl_core:benzene_snow",
    --Name of node used as a dusting layer on top of terrain
    --May not be present

    ore_common = "copper",
    --Name of material used for the common ore (copper or titanium)

    crystal = "stl_core:uranium",
    --Name of node used for underground crystals
    --May not be present

    icon = "...",
    --A very long string of texture modifiers used to create the icon shown in the planet info screen and in the sky

    ----- Only present for planets where water_level ~= nil
    
    river_level = -30004,
    --Y level of riverbeds

    mapgen_water = "stl_core:water_source",
    c_water = 23,
    --Name and content ID of the node used as water, filling oceans and rivers

    water_name = "Water",
    --Display name of water node for planet info

    mapgen_seabed = "stl_core:filler2",
    c_seabed = 12,
    param2_seabed = 138,
    --Name, content ID, and param2 value of the node replacing filler underwater

    depth_seabed = 2,
    --Thickness of seabed layer, ranges from 0 to 2

    mapgen_beach = "stl_core:filler3",
    c_beach = 13,
    param2_beach = 66,
    --Name, content ID, and param2 value of the node replacing filler on coasts

    depth_beach = 2,
    --Thickness of seabed layer, ranges from 0 to 3

    mapgen_water_top = "stl_core:water_ice",
    c_water_top = 24,
    --Name and content ID of the node used as a surface layer on oceans and rivers
    --May not be present

    depth_water_top = 1,
    --Thickness of water surface layer, may be arbitrarily high
    --Only present if mapgen_water_top is present

    snow_type1 = "stl_core:water_ice_snow",
    --Name of node used as a dusting layer on top of terrain
    --May not be present

    quartz = "stl_core:quartz1",
    --Name of node used for underwater crystals
    --May not be present

    ----- Only present for planets where lava_level ~= nil
    
    mapgen_lava = "stl_core:lava_source",
    c_lava = 25,
    --Name and content ID of the node used as lava, filling deep caves
    --Note that all these liquids (lava, petroleum, sulfuric acid) can also occasionally appear on the surface as oceans

    lava_name = "Lava",
    --Display name of lava node for planet info

    ----- Only present for planets where life_stat > 0
    
    param2_grass = 42,
    --Param2 value of grass

    param2_trees = {[35]=194},
    --Map of param2 values of tree nodes, indexed by node content ID

    ----- Only present with the stl_weather mod enabled
    
    weathers = {},
    --List of weather types that occur

    ----- Only present with the stl_precursor mod enabled
    
    precursor_chance = 10,
    --Base chance of a precursor outpost spawning per chunk, larger numbers are lower chances
    --Ranges from 4 to 24
    --Values below 10 also cause occasional vigil turrets to spawn everywhere
}
```

Liquids
-------

Each planet may have one surface liquid in oceans and rivers, and/or one underground liquid found in caves. They may also have a snow node on the surface corresponding to the surface liquid and/or a snow node unrelated to it.

Liquids all have melting and boiling points. They will never generate in planets above their boiling point, and may generate below their melting point if they have a frozen form, in which case the layer's thickness depends on how far it is below their melting point. They will also freeze if placed in a temperature below their melting point, or if touching a colder liquid, and will evaporate and disappear if above their boiling point.

With the stl_weather mod enabled, planets with surface liquid will also have that liquid's rain. If the liquid is frozen, it will also have hail; and each type of snow that spawns will have the corresponding snowy weather.

* `stellua.registered_waters`
    * List of liquid `{name, defs}` tuples for mapgen.
    * `name` is the name of the source node but without `"_source"` on the end.
    * `defs` is the water definition.

* `stellua.register_water(name, defs)`
    * Registers a liquid for mapgen.
    * Also registers all necessary nodes with names `name.."_source"`, `name.."_flowing"`, possibly `name.."_frozen"`, and craftitem `name.."_bucket"`.
    * Does not register the nodes for the snow.

* `stellua.registered_snows`
    * List of snow tuples for mapgen, same format as `stellua.registered_waters`.

* `stellua.register_snow(name, defs)`
    * Registers a snow type for mapgen.
    * Also registers the node named `name` and item named `name.."_ball"`

A water definition is a table with the following fields:

```lua
{
    description = "Water",
    --Node description but stripped of suffixes like " Source", " Flowing" etc.
    --Also used (in lowercase) for planet info

    tiles = "default_water",
    --Name of textures, again stripped of suffixes

    animation_period = 1,
    --Length of tile animation for liquid nodes

    frozen_tiles = "default_ice.png",
    frozen_node = "stl_core:bitumen",
    --Name of textures for the frozen form, or node used as frozen form itself, respectively
    --If both are present, frozen_tiles is preferred
    --If neither are present, the liquid has no frozen form - not recommended, may be buggy
    --The node used for frozen_node will not melt into liquid, only form from liquid freezing, and will not generate on planets - recommended for non-renewable liquids

    bucket_image = "bucket_water.png",
    --Inventory image used for the bucket item

    snow = "stl_core:water_snow",
    --Name of node used as dust on terrain
    --If not present, the liquid has no snow form

    tint = {r=0, g=0, b=0, a=0},
    --The post_effect_color of the liquid nodes

    liquid_viscosity = 0,
    liquid_renewable = true,
    damage_per_second = 0,
    --Overrides certain properties of the liquid nodes

    melt_point = 100,
    boil_point = 500,
    --Melting point and boiling point of the liquid, in Kelvin
    --Remember that actual temperature can go up to 1000K (at the bottom of a very hot world) and down to 0K (in space) which must be accounted for

    temp = 300,
    --Default temperature of the liquid, determines which of two liquids freezes when in contact
    --Player temperature tends towards this when in the liquid nodes or its rain

    weight = 1
    --Modifies how likely it is to spawn on a planet given its conditions are met

    generate_as_lava = false
    --Whether liquid will generate underground
}
```

A snow definition is a table with the following fields:

```lua
{
    description = "Water Snow",
    --Node description

    tiles = "default_snow.png",
    --Name of textures

    actual_snow = true,
    --Whether to show the snowflake texture for the associated weather instead of the ash texture

    melt_point = 300,
    --Maximum temperature for the snow to generate, in Kelvin

    temp = 200,
    --Default temperature of the snow
    --Player temperature tends towards this when in the node or its weather

    weight = 1,
    --Modifies how likely it is to spawn on a planet given its conditions are met

    groups = {}
    --Table of groups for the snowball item (not the node)
}
```

Planet Info
-----------

The "Planets" tab of the inventory provides readouts on each planet's features. The `heat_stat` and `atmo_stat` numbers are given directly, while `life_stat` is only given in vague categories since the fine-grained detail doesn't matter so much. The only other builtin features are the surface liquid type and the common ore; all others use API functions which other mods can also use.

* `stellua.registered_planet_infos`
    * List of functions for getting planet info

* `stellua.register_planet_info(function(planet))`
    * Registers a function for getting planet info
    * The function must return a string to be added to the info, or `nil` to not add anything

* `stellua.registered_planet_warnings`
    * List of functions for getting planet warnings

* `stellua.register_planet_warning(function(planet))`
    * Registers a function for getting planet warnings, which are always shown after info
    * The function must return a warning string, or `nil` to not add anything
    * The string returned from it will be converted to uppercase and have `"WARNING: "` appended to the front

Misc
----

* `stellua.get_nearby_param2(rand, param2, dist)`
    * Returns a randomly chosen palette index nearby to the given `param2`, using a PcgRandom `rand` to supply randomness.
    * `dist`: how many pixels away to go in the palette, defaults to 4.

* `stellua.roman_numeral(n)`
    * Returns the Roman numeral representation of the given positive integer. Only supports up to 50.

* `stellua.generate_name(rand, type)`
    * Returns a randomly generated name of the given type, using a PcgRandom `rand` to supply randomness.
    * The only currently supported type is `"star"`.

* `stellua.make_treedef(rand)`
    * Returns an L-system tree definition for use by Luanti API functions, using a PcgRandom `rand` to supply randomness.

Other Stuff
===========

* `stellua.registered_color_crafts`
    * List of `{output, recipe}` tuples as given by `stellua.register_color_craft`.

* `stellua.register_color_craft(output, recipe)`
    * Registers a crafting recipe to have the color on the items preserved.
    * `output` and `recipe` are both item names.
    * Essentially it checks the crafting grid and if all instances of the `recipe` item are the same color then it makes the `output` that color too, otherwise it prevents crafting. (To get anything more complex, like dye color mixing, you'll have to make it yourself.)

* `stellua.remap(val, min_val, max_val, min_map, max_map)`
    * Maps `val` from being between `min_val` and `max_val` to being between `min_map` and `max_map`. Borrowed from the Luamap mod.

* `stellua.set_respawn(player, pos)`
    * Sets the spawn point of a player.

* `stellua.registered_dyed_nodes`
    * Map of dyed nodes, indexed by undyed node.

* `stellua.register_dyed_node(name, node, description)`
    * Registers a new node based on another node but dyed, which can be produced from the undyed node or itself using the dye item, either by right-clicking with it or by crafting.
    * Does not ensure that the texture is greyscale.
    * `name`: the name of the new node.
    * `node`: the name of the old node to copy definitions from.
    * `description`: the description of the new node.