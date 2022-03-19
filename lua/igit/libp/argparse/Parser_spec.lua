local Parser = require('igit.libp.argparse.Parser')

describe("add_argument", function()
    describe("type", function()
        it("Defaults to string type", function()
            local parser = Parser()
            parser:add_argument('a')
            local res = parser:parse('1')
            assert.are.same(res, {a = "1"})
        end)

        it("Converts types", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number'})
            local res = parser:parse('1')
            assert.are.same(res, {a = 1})
        end)
    end)

    describe("nargs", function()
        it("Defaults to 1", function()
            local parser = Parser()
            parser:add_argument('a')
            local res = parser:parse('1 2')
            assert.are.same(res, nil)
        end)

        it("Respects nargs", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number', nargs = 2})
            local res = parser:parse('1 2')
            assert.are.same(res, {a = {1, 2}})
        end)
    end)

    describe("flags", function()
        it("Defaults to not required", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number'})
            parser:add_argument('--flag')
            local res = parser:parse('1')
            assert.are.same(res, {a = 1})

            res = parser:parse('--flag f 1')
            assert.are.same(res, {a = 1, flag = 'f'})
        end)

        it("Respect required", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number'})
            parser:add_argument('--flag', {required = true})
            local res = parser:parse('1')
            assert.are.same(res, nil)
        end)

        it("Respect nargs", function()
            local parser = Parser()
            parser:add_argument('a', {type = 'number'})
            parser:add_argument('--flag', {nargs = 2})
            local res = parser:parse('--flag f1 f2 1')
            assert.are.same(res, {a = 1, flag = {'f1', 'f2'}})
        end)
    end)
end)

describe("add_subparser", function()
    it("Defaults to use 'argparse_commands' as key", function()
        local parser = Parser()
        parser:add_subparser('sub')
        local res = parser:parse('sub')
        assert.are.same(res, {argparse_commands = {'sub'}})
    end)

    it("Respects commands_key", function()
        local parser = Parser('prog', {commands_key = 'subprocedure'})
        parser:add_subparser('sub')
        local res = parser:parse('sub')
        assert.are.same(res, {subprocedure = {'sub'}})
    end)

    it("Takes a parser instance", function()
        local parser = Parser('prog')
        local sub_parser = Parser('sub')
        parser:add_subparser(sub_parser)
        assert.are.same(parser:parse('sub'), {argparse_commands = {'sub'}})
    end)

    it("Takes multiple sub_parsers", function()
        local parser = Parser('prog')
        parser:add_subparser('sub1')
        parser:add_subparser('sub2')
        assert.are.same(parser:parse('sub1'), {argparse_commands = {'sub1'}})
        assert.are.same(parser:parse('sub2'), {argparse_commands = {'sub2'}})
    end)

    it("Takes recursive sub_parsers", function()
        local parser = Parser('prog')
        local sub_parser = parser:add_subparser('sub')
        sub_parser:add_subparser('subsub')
        assert.are.same(parser:parse('sub subsub'),
                        {argparse_commands = {'sub', 'subsub'}})
    end)

    it("Respects global options", function()
        local parser = Parser()
        parser:add_argument('a', {type = 'number'})
        parser:add_argument('--flag', {nargs = 2})
        local sub_parser = parser:add_subparser('sub')
        sub_parser:add_argument('sub_a', {type = 'number'})
        sub_parser:add_argument('--sub_flag', {nargs = 2})
        local res = parser:parse('--flag f1 f2 1 sub --sub_flag subf1 subf2 2')
        assert.are.same(res, {
            a = 1,
            flag = {'f1', 'f2'},
            argparse_commands = {'sub'},
            sub_a = 2,
            sub_flag = {'subf1', 'subf2'}
        })
    end)

    it("Returns hierarchical result", function()
        local parser = Parser('prog')
        local sub_parser = parser:add_subparser('sub')
        sub_parser:add_subparser('subsub')
        assert.are.same(parser:parse('sub subsub', true),
                        {{'prog', {}}, {'sub', {}}, {'subsub', {}}})
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
        assert.are.same(parser:get_completion_list('PROG'), {
            flags = {'--flag'},
            argparse_commands = {'sub', 'sub2'}
        })
    end)

    it("Returns sub-flags", function()
        assert.are.same(parser:get_completion_list('sub'),
                        {flags = {'--sub_flag'}, argparse_commands = {}})
        assert.are.same(parser:get_completion_list('sub2'),
                        {flags = {}, argparse_commands = {}})
    end)
end)
