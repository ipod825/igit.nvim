local Parser = require('igit.lib.argparse')

describe("add_argument", function()
    describe("type", function()
        it("Defaults to string type", function()
            local parser = Parser()
            parser:add_argument('a')
            local res = parser:parse('PROG 1')
            assert.are.same(res, {a = "1"})
        end)

        it("Converts types", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number'})
            local res = parser:parse('PROG 1')
            assert.are.same(res, {a = 1})
        end)
    end)

    describe("nargs", function()
        it("Defaults to 1", function()
            local parser = Parser()
            parser:add_argument('a')
            local res = parser:parse('PROG 1 2')
            assert.are.same(res, nil)
        end)

        it("Respects nargs", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number', nargs = 2})
            local res = parser:parse('PROG 1 2')
            assert.are.same(res, {a = {1, 2}})
        end)
    end)

    describe("flags", function()
        it("Defaults to not required", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number'})
            parser:add_argument('--flag')
            local res = parser:parse('PROG 1')
            assert.are.same(res, {a = 1})

            res = parser:parse('PROG --flag f 1')
            assert.are.same(res, {a = 1, flag = 'f'})
        end)

        it("Respect required", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number'})
            parser:add_argument('--flag', {required = true})
            local res = parser:parse('PROG 1')
            assert.are.same(res, nil)
        end)

        it("Respect nargs", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number'})
            parser:add_argument('--flag', {nargs = 2})
            local res = parser:parse('PROG --flag f1 f2 1')
            assert.are.same(res, {a = 1, flag = {'f1', 'f2'}})
        end)
    end)
end)

describe("add_subparser", function()
    it("Defaults to use 'sub_commands' as key", function()
        local parser = Parser()
        parser:add_subparser('sub')
        local res = parser:parse('PROG sub')
        assert.are.same(res, {sub_commands = {'sub'}})
    end)

    it("Respects sub_commands_key", function()
        local parser = Parser('prog', {sub_commands_key = 'subprocedure'})
        parser:add_subparser('sub')
        local res = parser:parse('PROG sub')
        assert.are.same(res, {subprocedure = {'sub'}})
    end)

    it("Takes multiple sub_parsers", function()
        local parser = Parser('prog')
        parser:add_subparser('sub1')
        parser:add_subparser('sub2')
        assert.are.same(parser:parse('PROG sub1'), {sub_commands = {'sub1'}})
        assert.are.same(parser:parse('PROG sub2'), {sub_commands = {'sub2'}})
    end)

    it("Takes recursive sub_parsers", function()
        local parser = Parser('prog')
        local sub_parser = parser:add_subparser('sub')
        sub_parser:add_subparser('subsub')
        assert.are.same(parser:parse('PROG sub subsub'),
                        {sub_commands = {'sub', 'subsub'}})
    end)

    it("Respects global options", function()
        local parser = Parser()
        parser:add_argument('a', {type = 'number'})
        parser:add_argument('--flag', {nargs = 2})
        local sub_parser = parser:add_subparser('sub')
        sub_parser:add_argument('sub_a', {type = 'number'})
        sub_parser:add_argument('--sub_flag', {nargs = 2})
        local res = parser:parse(
                        'PROG --flag f1 f2 1 sub --sub_flag subf1 subf2 2')
        assert.are.same(res, {
            a = 1,
            flag = {'f1', 'f2'},
            sub_commands = {'sub'},
            sub_a = 2,
            sub_flag = {'subf1', 'subf2'}
        })
    end)

end)

describe("get_completion_list", function()
    local parser = nil
    before_each(function()
        parser = Parser()
        parser:add_argument('a', {type = 'number'})
        parser:add_argument('--flag', {nargs = 2})
        parser:add_subparser('sub2')
        local sub_parser = parser:add_subparser('sub')
        sub_parser:add_argument('sub_a', {type = 'number'})
        sub_parser:add_argument('--sub_flag', {nargs = 2})
    end)

    it("Returns top flag and subcommands", function()
        assert.are.same(parser:get_completion_list('PROG'),
                        {flags = {'--flag'}, commands = {'sub', 'sub2'}})
    end)

    it("Returns sub-flags", function()
        assert.are.same(parser:get_completion_list('PROG sub'),
                        {flags = {'--sub_flag'}, commands = {}})
        assert.are.same(parser:get_completion_list('PROG sub2'),
                        {flags = {}, commands = {}})
    end)
end)
