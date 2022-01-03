local curl = require('plenary.curl')

-- Useful resources!
-- https://github.com/nanotee/nvim-lua-guide
-- https://dev.to/lornasw93/jira-api-with-jql-4ae6
-- https://developer.atlassian.com/server/jira/platform/jira-rest-api-examples/
-- Floating window:
-- https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua

M = {}

function M.getSprintIssues()

    local jql = {
        jql = "project = SEE and Sprint in openSprints()",
        fields = {"summary", "description", "assignee", "status", "subtasks"}
    }

    local resp = curl.request {
        auth = string.format("%s:%s", vim.env.JIRA_API_USER,
                             vim.env.JIRA_API_TOKEN),
        url = "https://octodevelopment.atlassian.net/rest/api/2/search",
        method = "post",
        headers = {
            content_type = "application/json",
            accept = "application/json"
        },
        body = vim.fn.json_encode(jql),
        dry_run = false
    }

    return vim.fn.json_decode(resp.body)

end

Issues = {}
function M.printResults()

    -- Retrieving issues from JIra ApI
    local body = M.getSprintIssues()
    Issues = body.issues

    -- This will fill the global FlatIssues, a table of all issues
    -- flattened out for easy searching
    -- This also returns lines to be displayed in the preview window
    M.createIssueLists(Issues)

    M.open_window(Lines)
    M.set_mappings()

end

FlatIssues = {}
Lines = {}
function M.createIssueLists(Issues)

    for _, task in ipairs(Issues) do
        local line = M.loopThroughIssues(task, 'task')
        table.insert(Lines, line)

        if next(task.fields.subtasks) ~= vim.NIL then
            for _, subtask in ipairs(task.fields.subtasks) do
                line = M.loopThroughIssues(subtask, 'subtask')
                table.insert(Lines, line)
            end
        end
    end
end

function M.loopThroughIssues(task, type)

    -- Pick up necessary fields
    local key = task.key
    local id = task.id

    local summary = task.fields.summary
    if task.fields.summary == nil then
        summary = ''
    end

    -- TODO: In subtasks, the description field in the api is empty, but there
    -- is still a description filled in? Example: SEE-446
    -- How to retrieve description of a subtask?
    local description = task.fields.description
    if description == vim.NIL then description = "None" end

    local assignee = ""
    if task.fields.assignee == nil or task.fields.assignee == vim.NIL then
        assignee = ""
    else
        assignee = task.fields.assignee.displayName
    end

    local status = task.fields.status.name

    -- Create line string
    local str = ''
    if type == 'task' then
        str = key .. " - " .. summary .. "(" .. assignee .. ")"
        local endstr = vim.fn.len(str)
        vim.cmd("let spaces = repeat(' ', " .. 90 - endstr .. ")")
        str = str .. vim.g.spaces .. status
    elseif type == 'subtask' then
        str = " └  " .. key .. " - " .. summary
        local endstr = vim.fn.len(str)
        vim.cmd("let spaces = repeat(' ', " .. 92 - endstr .. ")")
        str = str .. vim.g.spaces .. status
    end

    -- Populate dictionary
    FlatIssues[key] = {
        id = id,
        summary = summary,
        description = description,
        assignee = assignee,
        status = status
    }

    return str
end

function M.open_window(lines)

    vim.cmd([[
        pclose
        keepalt new +setlocal\ previewwindow|setlocal\ buftype=nofile|setlocal\ noswapfile|setlocal\ wrap [Jira]
        setl bufhidden=wipe
        setl buftype=nofile
        setl noswapfile
        setl nobuflisted
        setl nospell
        exe 'setl filetype=text'
        setl conceallevel=0
        setl nofoldenable
      ]])
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, lines)

    vim.cmd('exe "normal! z" .' .. #lines .. '. "\\<cr>"')
    vim.cmd([[
        exe "normal! gg"
        wincmd P
        res 15
      ]])
    -- vim.cmd('sort')

end

function M.open_description()

    local line = vim.fn.getline('.')
    local split = vim.fn.split(line, ' ')[1]

    if split == "└" then
        split = vim.fn.split(line, " ")[3]
        print(vim.inspect(split))
    end

    local descr = ""
    for key, value in pairs(FlatIssues) do
        if key == split then
            descr = value.description
        end
    end

    local splits = vim.fn.split(descr, '\n')

    local buf = vim.api.nvim_create_buf(false, true)
    vim.cmd('vsplit')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, splits)
    vim.api.nvim_win_set_cursor(win, {1, 0})
    vim.wo.wrap = true
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua vim.api.nvim_win_close(' ..
                                    win .. ', true)<cr> | :wincmd P <cr>',
                                {nowait = true, noremap = true, silent = true})

end

function M.close_window() vim.cmd('pclose') end

function M.set_mappings()
    local mappings = {
        ['<cr>'] = 'open_description()',
        o = 'open_description()',
        q = 'close_window()'
    }

    for k, v in pairs(mappings) do
        vim.api.nvim_buf_set_keymap(0, 'n', k,
                                    ':lua require("jira-nvim").' .. v .. '<cr>',
                                    {
            nowait = true,
            noremap = true,
            silent = true
        })
    end
end

return M

