local M = {}

local PromptTemplate = require('constructor.client.prompts.template')
local Hooks = require('constructor.client.prompts.hooks.init')

M.write_tests = PromptTemplate:new{
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
       input = function (cb)
            return function (variable, value)
                local text = "- Performance scenarios for %s (e.g., handling large datasets, high-frequency calls)"
                return cb(variable, text:format(value))
            end
       end
    }
}

M.generate_docstring = PromptTemplate:new{
    name = 'Generate docstring',
    description = 'Generate the docstring for the next function',
    template = [[Document the next piece of code, using the {bfiletype} docstring format,

        - Do not use comments
        - Only use the appropriate Docstring for the language
        - Use types when can be inferred
        - Try to explain the main functionality of the function, not tying to the underlying logic
        - Try to infer the types as maximum as you can.

        Code: %s]]
}

return M
