local String = getmetatable("").__index

function String:trim() return (self:gsub("^%s*(.-)%s*$", "%1")) end

function String:split(sep)
    sep = sep or "%s"
    local res = {}
    for s in string.gmatch(self, "([^" .. sep .. "]+)") do
        table.insert(res, s:trim())
    end
    return res
end

function String:find_str(pattern) return select(3, self:find(pattern)) end

function String:endswith(s) return self:sub(-#s, -1) == s end
function String:startswith(s) return self:sub(1, #s) == s end
