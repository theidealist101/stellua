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