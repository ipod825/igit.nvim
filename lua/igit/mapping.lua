local M = {}
M.mapping_handles = {}

function M.mapfn(module, mappings)
    M.mapping_handles[module] = M.mapping_handles[module] or {}

    for key, fn in pairs(mappings) do
        key = key:upper()
        M.mapping_handles[module][key] = fn
        vim.api.nvim_buf_set_keymap(0, 'n', key, string.format(
                                        '<cmd>lua require("igit.mapping").mapping_handles.%s["%s"]()<cr>',
                                        module, key:gsub('^<', '<lt>')), {})
    end
end

return M
