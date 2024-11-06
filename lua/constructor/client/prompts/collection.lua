---@type table<string, PromptTemplate>
local M = {}
local PromptTemplate = require('constructor.client.prompts.template')

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

M.write_tests = PromptTemplate.new{
    name = 'Write tests',
    description = 'Write tests for the selected function',
    template = [[You're a skilled {bfiletype} software engineer specialized in testing and quality assurance.

        Analyze the function and write comprehensive unit tests that cover:
        - Core functionality and expected outputs
        - Edge cases, including boundary values and uncommon inputs
        - Error handling for invalid inputs or data types
        {input}
        

        Provide clear test names and use assertions to validate the expected outcomes.]],
    hook_wrappers = {
       input = on_non_empty("- Performance scenarios for %s (e.g., handling large datasets, high-frequency calls)")
    }
}

M.generate_docstring = PromptTemplate.new{
    name = 'Generate docstring',
    description = 'Generate the docstring for the next function',
    template = [[Document the next piece of code, using the {bfiletype} docstring format,

        - Do not use comments
        - Only use the appropriate Docstring for the language
        - Use types when can be inferred
        - Try to explain the main functionality of the function, not tying to the underlying logic
        - Try to infer the types as maximum as you can.

        Code:]]
}

M.write_function_based_on_context = PromptTemplate.new{
    name = 'Write function based on context',
    template = [[You're a {bfiletype} Software Engineer that excels at writing good code. 
        Based on the provided and context, write a function that attends to the user demand.

        {context}

        When writing a function, you:
        - Handle edge cases and throw errors
        - Write readable code
        - Avoid nested code
        - Avoid unecessary comments 
        - Try to use the standard library from the language instead of rewriting
        - Write only the demanded function
        - Type hint the function

        {input}
        ]],
    hook_wrappers = {
        context = on_non_empty("Context: \n %s"),
        input = on_non_empty("Demand: \n %s")
    }
}

return M
