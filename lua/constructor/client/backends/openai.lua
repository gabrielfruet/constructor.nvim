local Message = require('constructor.client.messages')

local OpenAIClient = {}
OpenAIClient.__index = OpenAIClient

local function curl_request(url, method, headers, body, on_stream, on_done)
    local curl_cmd = {'curl', '-s', '-N', '-w', '\n%{http_code}', '-X', method, url}

    for key, value in pairs(headers) do
        table.insert(curl_cmd, '-H')
        table.insert(curl_cmd, string.format('%s: %s', key, value))
    end

    if body then
        table.insert(curl_cmd, '-d')
        table.insert(curl_cmd, body)
    end

    local response_body = {}
    local buffer = ""
    local status_code = 404

    local job_id = vim.fn.jobstart(curl_cmd, {
        on_stdout = function(_, data, _)
            for _, line in ipairs(data) do
                if line ~= '' then
                    local ok, num = pcall(tonumber, line)
                    if ok and type(num) == "number" then
                        status_code = num
                    elseif line:sub(1, 6) == 'data: ' then
                        local json_str = line:sub(7) -- Remove "data: " prefix

                        -- Handle the [DONE] marker
                        if json_str == '[DONE]' then
                            -- Stream is complete, but wait for the status code
                            return
                        end

                        -- Append the JSON string to the buffer
                        buffer = buffer .. json_str

                        -- Try to parse the buffer as JSON
                        local ok, decoded = pcall(vim.fn.json_decode, buffer)
                        if ok and decoded then
                            -- Successfully parsed a complete JSON object
                            on_stream(decoded)
                            buffer = "" -- Clear the buffer
                        else
                            -- JSON is incomplete, keep buffering
                            -- Do nothing, wait for the next chunk
                        end
                    end
                end
            end
        end,
        on_exit = function(_, exit_code, _)
            if exit_code == 0 then
                on_done(status_code)
            else
                on_done(status_code, 'Curl command failed with exit code: ' .. exit_code)
            end
        end,
    })

    -- Return the job ID in case the caller wants to control the job
    return job_id
end

-- Initialize the Groq client with API key
function OpenAIClient.new(api_key, model_name, endpoint)
    if not api_key then
        error("API key is required")
    end
    local instance = setmetatable({}, OpenAIClient)
    instance.api_key = api_key
    -- instance.base_url = "https://api.groq.com/openai/v1"
    instance.base_url = endpoint or "http://localhost:11434/v1"
    -- instance.model_name = model_name or "mixtral-8x7b-32768"
    instance.model_name = model_name or "qwen2.5-coder:latest"
    return instance
end

function OpenAIClient:_make_request(method, endpoint, body, on_stream, on_done)
    local headers = {
        ["Authorization"] = "Bearer " .. self.api_key,
        ["Content-Type"] = "application/json"
    }

    local body_str = nil
    if body then
        body_str = vim.fn.json_encode(body)
    end

    curl_request(
        self.base_url .. endpoint,
        method,
        headers,
        body_str,
        on_stream,
        function(status_code, err)
            if err then
                vim.print("Error:", err)
                on_done(false)
                return
            end

            if status_code < 200 or status_code >= 300 then
                vim.print(string.format("HTTP request failed with status code %d", status_code))
                on_done(false)
                return
            end

            on_done(true)
        end
    )
end

function OpenAIClient:create_chat_completion(messages, options, on_stream, on_done)
    options = options or {}
    local model = options.model or self.model_name
    local temperature = options.temperature or 0.7
    local max_tokens = options.max_tokens or 1024

    local request_body = {
        model = model,
        messages = messages,
        temperature = temperature,
        max_tokens = max_tokens,
        stream = true
    }

    local function on_done_cb(success)
        if not success then
            vim.print('error when calling chat')
            on_done(false)
            return
        end

        on_done(true)
    end

    local function on_stream_cb(body)
        local content = body.choices[1].delta.content

        if content == nil then
            return
        end

        local msg = Message.new({
            content = content,
            role = 'Assistant',
        })

        on_stream(msg)
    end

    self:_make_request("POST", "/chat/completions", request_body, on_stream_cb, on_done_cb)
end

function OpenAIClient:list_models(on_done)
    local function handle_response(response)
        local models = {}
        for _,v in pairs(response.data) do
            table.insert(models, v.id)
        end
        on_done(models)
    end
    self:_make_request("GET", "/models", nil, handle_response)
end

return OpenAIClient
