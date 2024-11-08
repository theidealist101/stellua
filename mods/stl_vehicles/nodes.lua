--The seat, which is the central node of a spaceship or any other vehicle
minetest.register_node("stl_vehicles:seat", {
    description = "Vehicle Seat",
    drawtype = "nodebox",
    tiles = {"wool_black.png"},
    node_box = {type="fixed", fixed={
        {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5},
        {-0.5, -0.25, 0, 0.5, 0.375, 0.5},
        {-0.5, -0.25, -0.5, -0.25, 0.125, 0},
        {0.25, -0.25, -0.5, 0.5, 0.125, 0}
    }},
    collision_box = {type="fixed", fixed={-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}},
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "facedir", --lvae doesn't like 4dir
    groups = {cracky=1, spaceship=1, seat=1}
})

--The fuel tank, required to power the thrusters or engines of a vehicle
minetest.register_node("stl_vehicles:tank", {
    description = "Fuel Tank",
    groups = {cracky=2, spaceship=1}
})

--The rocket engine, for launching spaceships
minetest.register_node("stl_vehicles:rocket", {
    description = "Rocket Engine",
    drawtype = "nodebox",
    node_box = {type="fixed", fixed={
        {-0.25, -0.5, -0.25, 0.25, 0, 0.25},
        {-0.5, 0, -0.5, 0.5, 0.5, 0.5}
    }},
    paramtype = "light",
    sunlight_propagates = true,
    paramtype2 = "wallmounted",
    groups = {cracky=2, spaceship=1}
})