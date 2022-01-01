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
        fields = {"summary", "description", "assignee", "status"}
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

    local body = M.getSprintIssues()

    for _, data in ipairs(body.issues) do

        local bla = M.setIssue(data)
        table.insert(Issues, bla)

    end
    -- print(vim.inspect(issues[5]))

    local lines = {}
    for _, v in pairs(Issues) do
        for key, data in pairs(v) do

            local str = key .. " - " .. data.summary
            table.insert(lines, str)
        end
    end

    M.open_window(lines)
    M.set_mappings()

end

function M.setIssue(data)

    local key = data.key
    local id = data.id
    local summary = data.fields.summary

    local description = data.fields.description
    if description == vim.NIL then description = "None" end

    local assignee = ""
    if data.assignee == nil then
        assignee = 'None'
    else
        assignee = data.assignee.displayName
    end
    local status = data.fields.status.name

    local issue = {}
    issue[key] = {
        id = id,
        summary = summary,
        description = description,
        assignee = assignee,
        status = status
    }

    return issue

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
      ]])
    vim.cmd('sort')

end

function M.open_description()

    local line = vim.fn.getline('.')
    local split = vim.fn.split(line, ' ')[1]

    for _, v in pairs(Issues) do
        for key, data in pairs(v) do
            if key == split then

                local splits = vim.fn.split(data.description, '\n')

                local buf = vim.api.nvim_create_buf(false, true)
                vim.cmd('vsplit')
                local win = vim.api.nvim_get_current_win()
                vim.api.nvim_win_set_buf(win, buf)
                vim.api.nvim_buf_set_lines(buf, 0, 0, false, splits)
                vim.api.nvim_win_set_cursor(win, {1, 0})
                vim.api.nvim_buf_set_keymap(0, 'n', 'q',
                                            ':lua vim.api.nvim_win_close(' ..
                                                win ..
                                                ', true)<cr> | :wincmd P <cr>',
                                            {
                    nowait = true,
                    noremap = true,
                    silent = true
                })

            end
        end
    end

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

