
-- Useful resources!
-- https://github.com/nanotee/nvim-lua-guide
-- https://dev.to/lornasw93/jira-api-with-jql-4ae6
-- https://developer.atlassian.com/server/jira/platform/jira-rest-api-examples/
-- Floating window:
-- https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua

-- Async examples:
-- https://github.com/smolck/nvim-todoist.lua/blob/2389aedf9831351433ab3806142b1e7e5dbddd22/lua/nvim-todoist/api.lua

local Jira = {}
local api = require('jira-nvim.api')
local util = require('jira-nvim.util')

Issues = {}
function Jira.open()

    -- Retrieving issues from JIra ApI
    local body = api.getSprintIssues()
    Issues = body.issues

    -- This will fill the global FlatIssues, a table of all issues
    -- flattened out for easy searching
    -- This also returns lines to be displayed in the preview window
    Jira.createIssueLists(Issues)

    Jira.render_window(Lines)
    Jira.set_mappings()

end

FlatIssues = {}
Lines = {}
function Jira.createIssueLists(Issues)

    for _, issue in ipairs(Issues) do
        local line = Jira.parseIssue(issue)

        line =
            Jira.create_line_string(issue.key, FlatIssues[issue.key], 'issue')
        table.insert(Lines, line)

        if next(issue.fields.subtasks) ~= vim.NIL then
            for i, subtask in ipairs(issue.fields.subtasks) do
                if i == table.maxn(issue.fields.subtasks) then
                    Jira.parseIssue(subtask)
                    line = Jira.create_line_string(subtask.key,
                                                   FlatIssues[subtask.key],
                                                   'last_subtask')
                else
                    Jira.parseIssue(subtask)
                    line = Jira.create_line_string(subtask.key,
                                                   FlatIssues[subtask.key],
                                                   'subtask')
                end

                table.insert(Lines, line)
            end
        end
    end
end

-- This loops through a single issue
function Jira.parseIssue(issue)

    -- Pick up necessary fields
    local key = issue.key
    local id = issue.id

    local summary = issue.fields.summary
    if issue.fields.summary == nil then summary = '' end

    local description = issue.fields.description
    if description == vim.NIL then description = "No description" end

    local assignee = ""
    if issue.fields.assignee == nil or issue.fields.assignee == vim.NIL then
        assignee = ""
    else
        assignee = issue.fields.assignee.displayName
    end

    local status = issue.fields.status.name

    local comments = ""
    if util.TableHasKey(issue.fields, 'comment') then
        comments = Jira.parseComments(issue.fields.comment.comments)
    end

    local reporter = ""
    if issue.fields.reporter == nil or issue.fields.reporter == vim.NIL then
        reporter = ""
    else
        reporter = "Reporter: " .. issue.fields.reporter.displayName
    end

    -- Populate dictionary
    FlatIssues[key] = {
        id = id,
        summary = summary,
        description = vim.fn.split(description, '\n'),
        assignee = assignee,
        status = status,
        comments = comments,
        reporter = reporter
    }

end

function Jira.parseComments(comments)

    local list = {}
    table.insert(list, "")
    table.insert(list, "=======Comments=======")
    for _, comment in ipairs(comments) do
        local body = vim.fn.split(comment.body, '\n')
        list = util.TableConcat(list, body)

        table.insert(list, comment.author.displayName .. " | " .. comment.created)
        table.insert(list, "-----------------")
        table.insert(list, "")
    end

    return list
end

function Jira.create_line_string(key, issue, type)

    -- Create line string
    local str = ''
    if type == 'issue' then
        str = key .. " - " .. issue.summary
        vim.cmd("let spaces = repeat(' ', " .. 90 - vim.fn.len(str) .. ")")
        str = str .. vim.g.spaces .. issue.status
        vim.cmd("let spaces = repeat(' ', " .. 110 - vim.fn.len(str) .. ")")
        str = str .. vim.g.spaces .. issue.assignee
    elseif type == 'subtask' then
        str = " │ " .. key .. " - " .. issue.summary
        vim.cmd("let spaces = repeat(' ', " .. 92 - vim.fn.len(str) .. ")")
        str = str .. vim.g.spaces .. issue.status
        vim.cmd("let spaces = repeat(' ', " .. 112 - vim.fn.len(str) .. ")")
        str = str .. vim.g.spaces .. issue.assignee
    elseif type == 'last_subtask' then
        str = " └ " .. key .. " - " .. issue.summary
        vim.cmd("let spaces = repeat(' ', " .. 92 - vim.fn.len(str) .. ")")
        str = str .. vim.g.spaces .. issue.status
        vim.cmd("let spaces = repeat(' ', " .. 112 - vim.fn.len(str) .. ")")
        str = str .. vim.g.spaces .. issue.assignee
    end

    return str
end

function Jira.render_window(lines)

    vim.cmd([[
        pclose
        keepalt new +setlocal\ previewwindow|setlocal\ buftype=nofile|setlocal\ noswapfile|setlocal\ wrap [Jira]
        setl bufhidden=wipe
        setl buftype=nofile
        setl noswapfile
        setl nobuflisted
        setl nowrap
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

function Jira.get_more_info(key)

    local issue = api.getIssue(key)
    Jira.parseIssue(issue)

end

function Jira.get_description()

    local line = vim.fn.getline('.')
    local split = vim.fn.split(line, ' ')[1]

    if split == "└" then
        split = vim.fn.split(line, " ")[2]
    elseif split == "│" then
        split = vim.fn.split(line, " ")[2]
    end

    Jira.get_more_info(split)

    local descr = {}
    for key, value in pairs(FlatIssues) do
        if key == split then
            descr = value.description
            table.insert(descr, '-----------------')
            table.insert(descr, value.reporter)

            descr = util.TableConcat(descr, value.comments)
        end
    end

    local buf = vim.api.nvim_create_buf(false, true)
    vim.cmd('vsplit')
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_buf_set_lines(buf, 0, 0, false, descr)
    vim.api.nvim_win_set_cursor(win, {1, 0})
    vim.wo.wrap = true
    vim.cmd [[set syntax=markdown]]
    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':lua vim.api.nvim_win_close(' ..
                                    win .. ', true)<cr> | :wincmd P <cr>',
                                {nowait = true, noremap = true, silent = true})

end

function Jira.close_window() vim.cmd('pclose') end

function Jira.get_issue_under_cursor()

    local line = vim.fn.getline('.')
    local split = vim.fn.split(line, ' ')[1]

    if split == "└" or split == '│' then
        split = vim.fn.split(line, " ")[2]
    end

    for key, _ in pairs(FlatIssues) do
        if key == split then return key, FlatIssues[key] end
    end
end

function Jira.create_or_switch_git_branch()

    local key, issue = Jira.get_issue_under_cursor()

    local branch = key .. '-' ..
                       vim.fn.substitute(issue['summary'], ' ', '-', 'g')

    -- Check if branch name exists already. If it does, switch to it. Else, create it.
    vim.fn.jobstart(string.format('git rev-parse --verify ' .. branch), {
        stdout_buffered = true,
        on_stdout = function(_, data, _)
            -- print(vim.inspect(data))

            if data[1] == "" then
                vim.cmd('Git checkout -B ' .. branch)
                vim.cmd('Git push --set-upstream origin ' .. branch)
            else
                vim.cmd('Git checkout ' .. branch)
            end
        end
    })
end

function Jira.set_mappings()
    local mappings = {
        ['<cr>'] = 'get_description()',
        o = 'get_description()',
        q = 'close_window()',
        gb = 'create_or_switch_git_branch()'
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

return Jira

