floater = {}
floater.utils = {}

--Make sure we have the environment for writing files to our own models folder
local env = minetest.request_insecure_environment()
if not env then
    error("Floater API needs to be trusted in order to load nodeboxes correctly")
end

local folder = minetest.get_modpath("floater").."/models/"

--Get file object by name, only in our own models folder for security purposes; has to be in init.lua
function floater.utils.get_nodebox_file(name)
    return env.io.open(folder..name, "w+")
end

--Load up the rest of the API
local path = minetest.get_modpath("floater").."/"
dofile(path.."utils.lua")
dofile(path.."api.lua")
dofile(path.."nodebox.lua")
dofile(path.."tests.lua")