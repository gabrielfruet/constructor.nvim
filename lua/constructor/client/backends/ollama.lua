local Message = require('constructor.client.messages')

local OllamaClient = {}
OllamaClient.__index = OllamaClient

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

-- Initialize the Ollama client
function OllamaClient.new(model_name)
    local instance = setmetatable({}, OllamaClient)
    instance.base_url = "http://localhost:11434/api" -- Default Ollama API endpoint
    instance.default_model = model_name or "llama2" -- Default model for Ollama
    return instance
end

function OllamaClient:_make_request(method, endpoint, body, on_done)
    local headers = {
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
function OllamaClient:create_chat_completion(messages, options, on_done)
    options = options or {}
    local model = options.model or self.default_model
    local temperature = options.temperature or 0.7
    local max_tokens = options.max_tokens or 1024

    -- Ollama's chat completion request format
    local request_body = {
        model = model,
        messages = messages,
        options = {
            temperature = temperature,
            num_predict = max_tokens
        },
        stream=false,
    }

    local function handle_response(response)
        if response == nil or response.message == nil then
            error('error when calling chat')
        end

        local msgs = Message.new({
            content = response.message.content,
            role = response.message.role,
        })

        on_done(msgs)
    end

    self:_make_request("POST", "/chat", request_body, handle_response)
end

-- List available models (Ollama-specific endpoint)
function OllamaClient:list_models(on_done)
    self:_make_request("GET", "/tags", nil, function(response)
        if response == nil or response.models == nil then
            error('error when listing models')
        end
        on_done(response.models)
    end)
end

return OllamaClient
