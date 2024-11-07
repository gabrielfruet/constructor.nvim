---@type RoutineTemplate[]
local RoutineCollection = {}
local RoutineTemplate = require'constructor.routines.template'
local RoutineKind = require'constructor.routines.kinds'

local function on_non_empty(formatstr)
    return function (cb)
        return function (value)
            if type(value) == 'string' and #value > 0 then
                return cb(formatstr:format(value))
            else
                return cb(value)
            end
        end
    end
end

local function ensure_non_empty()
    return function (cb)
        return function (value)
            if type(value) == 'string' and #value > 0 then
                return cb(value)
            else
                return nil
            end
        end
    end
end

table.insert(RoutineCollection, RoutineTemplate.new{
    name = 'Write tests',
    description = 'Write tests for the selected function',
    kind = RoutineKind.kinds.CODE,
    template = [[You're a skilled {bfiletype} software engineer specialized in testing and quality assurance.

        Analyze the function and write comprehensive unit tests that cover:
        - Core functionality and expected outputs
        - Edge cases, including boundary values and uncommon inputs
        - Error handling for invalid inputs or data types
        - The code should be surrounded by backticks
        {input}
        

        Provide clear test names and use assertions to validate the expected outcomes.]],
    hook_wrappers = {
       input = on_non_empty("- Performance scenarios for %s (e.g., handling large datasets, high-frequency calls)")
    },

})

table.insert(RoutineCollection, RoutineTemplate.new{
    name = 'Generate docstring',
    description = 'Generate the docstring for the next function',
    kind = RoutineKind.kinds.CODE,
    template = [[Document the next piece of code, using the {bfiletype} docstring format,

        - Do not use comments
        - Only use the appropriate Docstring for the language
        - Use types when can be inferred
        - Try to explain the main functionality of the function, not tying to the underlying logic
        - Try to infer the types as maximum as you can.
        - The code should be surrounded by backticks

        Code:{selection}]]
})

table.insert(RoutineCollection, RoutineTemplate.new{
    name = 'Write function based on context',
    kind = RoutineKind.kinds.CODE,
    template = [[You're a {bfiletype} Software Engineer that excels at writing readable code. 
        Based on the provided context, write a function that attends to the user demand.

        {context}

        When writing a function, you:
        - Write readable code
        - Avoid nested code
        - Avoid comments 
        - Try to use the standard library from the language instead of rewriting
        - Write only the demanded function
        - Type hint the function
        - The code should be surrounded by backticks

        {input}
        ]],
    hook_wrappers = {
        context = on_non_empty("Context: \n %s"),
        input = on_non_empty("Demand: \n %s")
    }
})

table.insert(RoutineCollection, RoutineTemplate.new{
    name = 'Write regex',
    kind = RoutineKind.kinds.CODE,
    template = [[You're a {bfiletype} regex Software Engineer that excels at writting good regexes. 
        Given the constraints and rules for the regex, write a regex that satifies it.

        When writing the regex, you should:

        - Provide only the regex pattern assigned to a variable of the {bfiletype} language
        - The code should be surrounded by backticks

        Rules and constraints:
        {input}
        ]],
    hook_wrappers = {
        input = ensure_non_empty()
    }
})

return RoutineCollection
