local string_mt = getmetatable("")

string_mt.__index["trim"] =
    function(s) return (s:gsub("^%s*(.-)%s*$", "%1")) end

string_mt.__index["split"] = function(str, sep)
    sep = sep or "%s"
    local res = {}
    for s in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(res, s:trim())
    end
    return res
end

string_mt.__index["find_str"] = function(str, pattern)
    return select(3, str:find(pattern))
end
