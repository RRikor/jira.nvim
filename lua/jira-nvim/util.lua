
local util = {}

function util.TableHasKey(table, key) return table[key] ~= nil end

function util.TableConcat(table1, table2)

    local result = {}
    if table1 ~= nil then
        for _, row1 in ipairs(table1) do table.insert(result, row1) end
    end

    if table2 ~= nil then
        for _, row2 in ipairs(table2) do table.insert(result, row2) end
    end
    return result
end

return util
