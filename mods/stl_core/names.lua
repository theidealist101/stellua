--Generate random goofy Latin-esque names for things
--Based on my original formulation in Python

--Choose a random item from a list
local function choice(rand, t)
    return t[rand:next(1, #t)]
end

--Test chance
local function test(rand)
    return 0.001*rand:next(0, 999)
end

--Lots of constants defining stuff
HIATUS_CHANCE = 0.2
GEMINATE_CHANCE = 0.3
SIGMATISE_CHANCE = 0.3
TAUISE_CHANCE = 0.3
LABIALISE_CHANCE = 0.6
NASALISE_CHANCE = 0.6
LATERAL_CHANCE = 0.4
PRELIQUIDATE_CHANCE = 0.4
LIGMATISE_CHANCE = 0.6
SIBILANT_CHANCE = 0.6
RARE_CHANCE = 0.1
COMMON_CHANCE = 0.7

CONSONANTS = {"b", "d", "f", "g", "m", "cw"}
COMMON_CONSONANTS = {"c", "l", "n", "p", "r", "s", "t"}
RARE_CONSONANTS = {"h", "j", "v", "z", "p'", "t'", "c'"}
NON_GEMINATE = {"h", "j", "v", "z", "cw"}
SIGMATISE = {"p", "b", "c", "g", "h", "p'", "c'"}
STOPS = {"p", "b", "t", "d", "c", "g", "p'", "t'", "c'"}
VOICELESS_STOPS = {"p", "t", "c", "p'", "t'", "k'"}
LABIALISE = {"c", "g"}
LIQUIDATE = table.insert_all({"s", "f"}, STOPS)

VOWELS = {"a", "e", "i", "o", "u"}
RARE_VOWELS = {"ae", "ae", "au", "au", "oe", "y"}
NON_HIATUS = {"oe", "y"}

PREFIXES = {"ad", "ex", "in", "per", "pro", "re", "con"}

REPLACEMENTS = {
    {"bs", "ps"},
    {"p's", "ps"},
    {"cs", "x"},
    {"gs", "x"},
    {"c's", "x"},
    {"hs", "x"},
    {"bt", "pt"},
    {"gt", "ct"},
    {"ht", "ct"},
    {"ij", "i"},
    {"ji", "i"},
    {"aej", "ae"},
    {"oej", "oe"},
    {"wu", "u"},
    {"wy", "wi"},
    {"sw", "su"},
    {"gw", "gu"},
    {"cw", "qu"},
    {"w", "v"},
    {"jy", "ju"},
    {"ee", "e"},
    {"oo", "o"},
    {"'", "h"}
}

--Generate a name
function stellua.generate_name(rand, type)
    --choose parameters based on type
    local suffix, length, prefix, prefix_chance
    if type == "star" then
        suffix = choice(rand, {"us", "a", "um", "us", "a", "um", "is", "o", "i", "ae", "es"})
        length = choice(rand, {1, 1, 1, 2, 2, 3})
        prefix_chance = 0.3
    else
        error("invalid type for name generation")
    end
    if length > 1 and test(rand) < prefix_chance then
        --length = length-1
        prefix = choice(rand, PREFIXES)
    end

    --choose syllable structure
    local length_points = {}
    for _ = 1, rand:next(1, 2) do
        length_points[rand:next(1, length+1)] = true
    end
    local outl = {}
    for i = 1, length+1 do
        if i <= length and (i <= 0 or outl[i-1] ~= "") and test(rand) < HIATUS_CHANCE then
            table.insert(outl, "")
        else

            --choose base consonant
            local new
            local tested = test(rand)
            if tested < RARE_CHANCE then new = choice(rand, RARE_CONSONANTS)
            elseif tested < RARE_CHANCE+COMMON_CHANCE then new = choice(rand, COMMON_CONSONANTS)
            else new = choice(rand, CONSONANTS) end

            --do gemination and a few funny G things
            if length_points[i] then
                if new == "g" and test(rand) < LIGMATISE_CHANCE then
                    new = new..(i > 1 and test(rand) > 0.5 and "m" or "n")
                elseif i > 1 and table.indexof(NON_GEMINATE, string.sub(new, 1, 1)) <= 0 and test(rand) < GEMINATE_CHANCE then
                    new = string.sub(new, 1, 1)..new
                else

                    --stick extra S and T on things
                    local sigmatised, sibilant
                    if table.indexof(VOICELESS_STOPS, new) > 0 and test(rand) < SIBILANT_CHANCE then
                        new = "s"..new
                        sibilant = true
                    elseif table.indexof(SIGMATISE, new) > 0 then
                        local tested2 = test(rand)
                        if tested2 < SIGMATISE_CHANCE then
                            new = new.."s"
                            sigmatised = true
                        elseif tested2 < SIGMATISE_CHANCE+TAUISE_CHANCE then
                            new = new..(string.sub(new, -1) == "'" and "t'" or "t")
                            sigmatised = true
                        end
                    end

                    --now for some liquids
                    if table.indexof(LABIALISE, string.sub(new, -1)) > 0 and test(rand) > LABIALISE_CHANCE then
                        new = new.."w"
                    end
                    local postliquidate = table.indexof(LIQUIDATE, string.sub(new, -1)) > 0 and not sigmatised
                    local preliquidate = i > 1 and table.indexof(LIQUIDATE, string.sub(new, 1, 1)) > 0 and not sibilant
                    if preliquidate or postliquidate then
                        local pre = preliquidate and test(rand) < PRELIQUIDATE_CHANCE or not postliquidate
                        local liquid
                        if test(rand) < LATERAL_CHANCE and (pre or string.sub(new, -1) ~= "t" and string.sub(new, -1) ~= "d" and string.sub(new, -2) ~= "t'") then
                            liquid = "l"
                        elseif string.sub(new, -1) ~= "s" then
                            liquid = "r"
                        end
                        if liquid then
                            if pre then new = liquid..new
                            else new = new..liquid end
                        end
                    end
                    if table.indexof(STOPS, string.sub(new, 1, 1)) > 0 and i > 1 and (test(rand) < NASALISE_CHANCE or new == "gw") then
                        new = (table.indexof({"p", "b"}, string.sub(new, 1, 1)) > 0 and "m" or "n")..new
                    end
                end
            end

            --add the finished product to the list
            table.insert(outl, new)
        end
    end

    --stick it all together with some vowels between
    local out = table.remove(outl, 1)
    for i = 1, length do
        if test(rand) < RARE_CHANCE then
            local new
            repeat
                new = choice(rand, RARE_VOWELS)
            until string.len(out) <= 0 or string.sub(out, -1) ~= string.sub(new, 1, 1) and not (table.indexof(NON_HIATUS, new) > 0 and (table.indexof(VOWELS, string.sub(out, -1)) > 0 or table.indexof(RARE_VOWELS, string.sub(out, -1)) > 0))
            out = out..new
        else
            out = out..choice(rand, VOWELS)
        end
        out = out..table.remove(outl, 1)
    end

    --add affixes
    out = out..suffix --prefixes todo (already done in python)

    --extra replacements so it makes sense
    for _, val in ipairs(REPLACEMENTS) do
        out = string.gsub(out, val[1], val[2])
    end

    --return finished name
    return string.upper(string.sub(out, 1, 1))..string.sub(out, 2)
end