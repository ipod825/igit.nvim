local M = require 'igit.libp.argparse.Parser'()

function M:parse(str, return_hierarchical_result)
    vim.validate({str = {str, 'string'}})
    return self:parse_internal(str:split(), return_hierarchical_result)
end

function M:parse_internal(args, return_hierarchical_result)
    if return_hierarchical_result then return {{self.prog, args}} end
    return args
end

return M
