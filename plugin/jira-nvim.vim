fun! Jira()
    lua for k in pairs(package.loaded) do if k:match("^jira%-nvim") then package.loaded[k] = nil end end
    lua require("jira-nvim").open()
endfun

map <leader>ji :call Jira()<CR>

augroup Jira
    autocmd!
augroup END
