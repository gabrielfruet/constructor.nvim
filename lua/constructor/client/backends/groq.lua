local Message = require('constructor.client.messages')

local GroqClient = {}
GroqClient.__index = GroqClient

-- Utility function to execute curl commands and return the response
local function curl_request(url, method, headers, body)
    -- Create temporary files for the response and headers
    local temp_response = os.tmpname()
    local temp_headers = os.tmpname()

    -- Build the curl command
    local curl_cmd = string.format(
        'curl -s -w "\\n%%{http_code}" -X %s "%s" -o "%s" -D "%s"',
        method,
        url,
        temp_response,
        temp_headers
    )

    -- Add headers
    for key, value in pairs(headers) do
        curl_cmd = curl_cmd .. string.format(' -H "%s: %s"', key, value)
    end

    local temp_body = os.tmpname()

    -- Add body if present
    if body then
        local f = io.open(temp_body, "w")
        f:write(body)
        f:close()
        curl_cmd = curl_cmd .. string.format(' -d "@%s"', temp_body)
    end

    -- Execute curl command
    local handle = io.popen(curl_cmd)
    local result = handle:read("*a")
    handle:close()

    -- Read response body
    local f = io.open(temp_response, "r")
    local response_body = f:read("*a")
    f:close()

    -- Clean up temporary files
    os.remove(temp_response)
    os.remove(temp_headers)
    if body then
        os.remove(temp_body)
    end

    -- Parse status code from curl output
    local status_code = tonumber(result:match("(%d+)[\n]*$"))

    return response_body, status_code
end

-- Initialize the Groq client with API key
function GroqClient.new(api_key)
    if not api_key then
        error("API key is required")
    end
    local self = setmetatable({}, GroqClient)
    self.api_key = api_key
    self.base_url = "https://api.groq.com/openai/v1"
    --self.default_model = "llama-3.2-11b-text-preview"
    --self.default_model = "mixtral-8x7b-32768"
    --self.default_model = "llama-3.2-90b-text-preview"
    return self
end

-- Helper function to make HTTP requests
function GroqClient:_make_request(method, endpoint, body)
    local headers = {
        ["Authorization"] = "Bearer " .. self.api_key,
        ["Content-Type"] = "application/json"
    }

    local body_str = nil
    if body then
        body_str = vim.fn.json_encode(body)
    end

    local response_body, status_code = curl_request(
        self.base_url .. endpoint,
        method,
        headers,
        body_str
    )

    if status_code < 200 or status_code >= 300 then
        error(string.format("HTTP request failed with status code %d: %s", status_code, response_body))
    end

    local ok, decoded = pcall(vim.fn.json_decode, response_body)
    if not ok then
        error("Failed to decode JSON response: " .. decoded)
    end

    return decoded
end

-- Create a chat completion
function GroqClient:create_chat_completion(messages, options)
    options = options or {}
    local model = options.model or self.default_model
    local temperature = options.temperature or 0.7
    local max_tokens = options.max_tokens or 1024

    local request_body = {
        model = model,
        messages = messages,
        temperature = temperature,
        max_tokens = max_tokens
    }

    local response =  self:_make_request("POST", "/chat/completions", request_body)

    if response == nil or response.choices == nil then
        error('error when calling chat')
    end

    return Message:new({
        content=response.choices[1].message.content,
        role=response.choices[1].message.role,
    })
end

-- Create a completion
function GroqClient:create_completion(prompt, options)
    options = options or {}
    local model = options.model or self.default_model
    local temperature = options.temperature or 0.7
    local max_tokens = options.max_tokens or 1024

    local request_body = {
        model = model,
        prompt = prompt,
        temperature = temperature,
        max_tokens = max_tokens
    }

    return self:_make_request("POST", "/completions", request_body)
end

-- List available models
function GroqClient:list_models()
    return self:_make_request("GET", "/models")
end

return GroqClient
