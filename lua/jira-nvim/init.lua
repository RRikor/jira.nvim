local curl = require('plenary.curl')

-- Useful resources!
-- https://dev.to/lornasw93/jira-api-with-jql-4ae6
-- https://developer.atlassian.com/server/jira/platform/jira-rest-api-examples/

local function printSprintIssues()

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
    print(vim.inspect(resp))

end

return {printSprintIssues = printSprintIssues}
