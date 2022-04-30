fun! Jira()
    lua for k in pairs(package.loaded) do if k:match("^jira%-nvim") then package.loaded[k] = nil end end
    lua require("jira-nvim").LoadSprint()
endfun

fun! JiraBacklog()
    lua for k in pairs(package.loaded) do if k:match("^jira%-nvim") then package.loaded[k] = nil end end
    lua require("jira-nvim").LoadBacklog()
endfun

map <leader>js :call Jira()<CR>
map <leader>jb :call JiraBacklog()<CR>

augroup Jira
    autocmd!
augroup END
