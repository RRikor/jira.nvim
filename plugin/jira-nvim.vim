fun! Jira()
    lua for k in pairs(package.loaded) do if k:match("^jira%-nvim") then package.loaded[k] = nil end end
    lua require("jira-nvim").printResults()
endfun

map <leader>ji :call Jira()<CR>


fun! DB()
    lua for k in pairs(package.loaded) do if k:match("^DB") then package.loaded[k] = nil end end
    lua require("DB").DB()
endfun

map <leader>pf :call DB()<CR>


augroup Jira
    autocmd!
augroup END
