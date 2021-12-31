local curl = require('plenary.curl')

-- Useful resources!
-- https://github.com/nanotee/nvim-lua-guide
-- https://dev.to/lornasw93/jira-api-with-jql-4ae6
-- https://developer.atlassian.com/server/jira/platform/jira-rest-api-examples/

M = {}

function M.getSprintIssues()

    local jql = {
        jql = "project = SEE and Sprint in openSprints()",
        fields = {"summary","description","assignee","status"}
    }

    local resp = curl.request {
        auth = string.format("%s:%s", vim.env.JIRA_API_USER, vim.env.JIRA_API_TOKEN),
        url = "https://octodevelopment.atlassian.net/rest/api/3/search",
        method = "post",
        headers = {
          content_type = "application/json",
            accept = "application/json",
        },
        body = vim.fn.json_encode(jql),
        dry_run = false
    }

    return vim.fn.json_decode(resp.body)

end


function M.printResults()

    local body = M.getSprintIssues()
    local issues = {}

    for _, data in ipairs(body.issues) do

        local bla = M.setIssue(data)

        table.insert(issues,bla)

    end

    print(vim.inspect(issues[5]))
end

local Issue = {}
Issue.__index = Issue

function Issue:new(vars)
    local this = {
        key = vars.key,
        id = vars.id,
        summary = vars.summary,
        description = vars.description,
        assignee = vars.assignee,
        status = vars.status

    }
    setmetatable(this, self)
    return this
end

function M.setIssue(data)

    local key = data.key
    local id = data.id
    local summary = data.fields.summary

    local description = data.fields.description
    if description == vim.NIL then
        description = "None"
    end

    local assignee = ""
    if data.assignee == nil then
        assignee = 'None'
    else
        assignee = data.assignee.displayName
    end
    local status = data.fields.status.name

    return Issue:new{
        key = key,
        id = id,
        summary = summary,
        description = description,
        assignee = assignee,
        status = status
    }

end

return M


