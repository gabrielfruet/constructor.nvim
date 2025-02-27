local Message = require('constructor.client.messages')

local GroqClient = {}
GroqClient.__index = GroqClient

local function curl_request(url, method, headers, body, on_done)
    local curl_cmd = {'curl', '-s', '-w', '\n%{http_code}', '-X', method, url}

    for key, value in pairs(headers) do
        table.insert(curl_cmd, '-H')
        table.insert(curl_cmd, string.format('%s: %s', key, value))
    end

    if body then
        table.insert(curl_cmd, '-d')
        table.insert(curl_cmd, body)
    end

    local response_body = {}
    local status_code = nil

    local job_id = vim.fn.jobstart(curl_cmd, {
        on_stdout = function(_, data, _)
            for _, line in ipairs(data) do
                table.insert(response_body, line)
            end
        end,
        on_exit = function(_, exit_code, _)
            if exit_code == 0 then
                local full_response = table.concat(response_body, '\n')

                status_code = tonumber(full_response:match('(%d+)\n$'))

                local extracted_body = full_response:gsub('(%d+)\n$', '')

                on_done(extracted_body, status_code)
            else
                -- Handle non-zero exit codes
                on_done(nil, nil, 'Curl command failed with exit code: ' .. exit_code)
            end
        end,
    })

    -- Return the job ID in case the caller wants to control the job
    return job_id
end
-- Initialize the Groq client with API key
function GroqClient.new(api_key)
    if not api_key then
        error("API key is required")
    end
    local instance = setmetatable({}, GroqClient)
    instance.api_key = api_key
    instance.base_url = "https://api.groq.com/openai/v1"
    instance.default_model = "mixtral-8x7b-32768"
    return instance
end

function GroqClient:_make_request(method, endpoint, body, on_done)
    local headers = {
        ["Authorization"] = "Bearer " .. self.api_key,
        ["Content-Type"] = "application/json"
    }

    local body_str = nil
    if body then
        body_str = vim.fn.json_encode(body)
    end

    local function curl_cb(response_body, status_code)
        if status_code == nil then
            vim.print("HTTP request failed")
        end
        if status_code < 200 or status_code >= 300 then
            error(string.format("HTTP request failed with status code %d: %s", status_code, response_body))
        end

        local ok, decoded = pcall(vim.fn.json_decode, response_body)
        if not ok then
            error("Failed to decode JSON response: " .. decoded)
        end
        on_done(decoded)
    end

    curl_request(
        self.base_url .. endpoint,
        method,
        headers,
        body_str,
        curl_cb
    )

end

-- Create a chat completion
function GroqClient:create_chat_completion(messages, options, on_done)
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
    local function handle_response(response)
        if response == nil or response.choices == nil then
            error('error when calling chat')
        end

        local msgs = Message.new({
            content=response.choices[1].message.content,
            role=response.choices[1].message.role,
        })

        on_done(msgs)
    end

    self:_make_request("POST", "/chat/completions", request_body, handle_response)

end

function GroqClient:list_models(on_done)
    self:_make_request("GET", "/models", on_done)
end

return GroqClient
