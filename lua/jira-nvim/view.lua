local View = {}
View.__index = View

function View:new(opts)
	local this = {
		origin = opts.origin,
		lines = opts.lines,
		buff = opts.buff,
		type = opts.type,
	}
	setmetatable(this, self)
	return this
end

function View:LoadHighlights()

    vim.api.nvim_command([[syn match jiraToDo '\c.*\<\(To Do\).*']])
    vim.api.nvim_command([[syn match jiraInProgress '\c.*\<\(In Progress\).*']])
    vim.api.nvim_command([[syn match jiraPeerReview '\c.*\<\(Peer Review\).*']])
    vim.api.nvim_command([[syn match jiraAccTest '\c.*\<\(Acceptation Test\).*']])
    vim.api.nvim_command([[syn match jiraTrackTime '\c.*\<\(Track Time\).*']])
    vim.api.nvim_command([[syn match jiraDone '\c.*\<\(Done\).*']])

    vim.api.nvim_command([[hi! def link jiraToDo DiffDelete]])
    vim.api.nvim_command([[hi! def link jiraInProgress DiffText]])
    vim.api.nvim_command([[hi! def link jiraPeerReview DiffAdd]])
    vim.api.nvim_command([[hi! def link jiraAccTest DiffChange]])
    vim.api.nvim_command([[hi! def link jiraTrackTime DiffChange]])
    vim.api.nvim_command([[hi! def link jiraDone DiffChange]])

end

function View:create_jira_win()
	vim.cmd(self.type)
    self.win = vim.api.nvim_get_current_win()
    self.buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(self.win, self.buf)
	vim.api.nvim_win_set_height(self.win, 20)

	vim.api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(self.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(self.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(self.buf, "buflisted", false)
	vim.api.nvim_win_set_option(self.win, "spell", false)
	vim.api.nvim_win_set_option(self.win, "list", false)
	vim.api.nvim_win_set_option(self.win, "signcolumn", "no")
	vim.api.nvim_win_set_option(self.win, "fcs", "eob: ")
    vim.api.nvim_buf_set_option(self.buf, "filetype", "jira")
    vim.api.nvim_win_set_option(self.win, "wrap", false)

    View:LoadHighlights()

end

function View:create_descr_win()
	vim.cmd(self.type)
	self.win_descr = vim.api.nvim_get_current_win()
	self.buf_descr = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(self.win_descr, self.buf_descr)
	vim.api.nvim_win_set_height(self.win_descr, 20)

	vim.api.nvim_buf_set_option(self.buf_descr, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(self.buf_descr, "buftype", "nofile")
	vim.api.nvim_buf_set_option(self.buf_descr, "swapfile", false)
	vim.api.nvim_buf_set_option(self.buf_descr, "buflisted", false)
	vim.api.nvim_win_set_option(self.win_descr, "spell", false)
	vim.api.nvim_win_set_option(self.win_descr, "list", false)
	vim.api.nvim_win_set_option(self.win_descr, "signcolumn", "no")
	vim.api.nvim_win_set_option(self.win_descr, "fcs", "eob: ")
	vim.api.nvim_buf_set_option(self.buf_descr, "filetype", "jira")
	vim.api.nvim_win_set_option(self.win_descr, "wrap", true)
end

function View:fill(buf, win)
	vim.api.nvim_buf_set_lines(buf, 0, -1, 0, self.lines)
	vim.api.nvim_win_set_cursor(win, { 1, 1 })
end

function View:clear()
	local lines = {}
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, 0, lines)
end

return View
