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

    bla = body.issues[4]
    -- for i, data in ipairs(bla) do
    --     print(i)
        -- print(vim.inspect(bla))
        table.insert(bla, M.setIssue(data))
    -- end

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

    local assignee = ""
    print(vim.inspect(data.fields.assignee))
    if data.fields.assignee == vim.NIL then
        print("yes")
        assignee = ""
    else
        assignee = data.fields.assignee.displayName
    end

    return Issue:new{
        key = data.key,
        id = data.id,
        summary = data.fields.summary,
        description = data.fields.description,
        assignee = assignee,
        status = data.fields.status.name,
    }

end

return M


