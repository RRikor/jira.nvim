local curl = require('plenary.curl')

local api = {}

local auth = string.format("%s:%s", vim.env.JIRA_API_USER, vim.env.JIRA_API_TOKEN)
local base = "https://octodevelopment.atlassian.net/rest/api/2/"
local headers = { content_type = "application/json", accept = "application/json" }

function api.getSprintIssues()

    local jql = {
        jql = "project = INS and Sprint in openSprints()",
        fields = {"summary", "description", "assignee", "status", "subtasks"}
    }

    local resp = curl.request {
        url = base .. "/search",
        method = "post",
        auth = auth,
        headers = headers,
        body = vim.fn.json_encode(jql),
        dry_run = false
    }

    return vim.fn.json_decode(resp.body)

end

function api.getBacklog()

    local jql = {
        jql = "project = INS",
        fields = {"summary", "description", "assignee", "status", "subtasks"}
    }

    local resp = curl.request {
        url = base .. "/search",
        method = "post",
        auth = auth,
        headers = headers,
        body = vim.fn.json_encode(jql),
        dry_run = false
    }

    return vim.fn.json_decode(resp.body)
end

function api.getIssue(key)

    local resp = curl.request{
        url = base .. "/issue/" .. key,
        method = "get",
        auth = auth,
        headers =  headers,
        dry_run = false
    }

    return vim.fn.json_decode(resp.body)

end

return api


