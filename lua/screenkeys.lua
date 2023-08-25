M = {}
--local M = {}

function M.create_buf()
	M.buf = vim.api.nvim_create_buf(false, true)
end

function M.open_win()
	if M.win ~= nil and vim.api.nvim_win_is_valid(M.win) then
		return
	end
	if(M.buf == nil) then
		M:create_buf()
	end
	-- listed = false, scratch = true
	local options = {
		style = "minimal",
		relative = "editor",
		anchor = "NE",
		zindex = 300,
		row = 0,
		col = vim.o.columns,
		width = 40,
		height = 5,
	}
	M.win = vim.api.nvim_open_win(M.buf, false, options)
end

function M.close_win()
	if M.win ~= nil and vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_win_close(M.win, false)
	end
end

function M.buf_last_line()
	return vim.api.nvim_buf_line_count(M.buf) - 1;
end

function M.buf_last_col()
	return vim.api.nvim_buf_get_lines(M.buf, -2, -1, 0)[1].len() - 1
end

function M.append_buf(text)
	--vim.api.nvim_buf_get_lines(13, -2, -1, 0)
	local last_line = M.buf_last_line();
	local last_col = M.buf_last_col();
	vim.api.nvim_buf_set_text(M.buf,
		last_line, last_col, last_line, last_col,
		{ text }
		)
end

function M.clear_buf()
	local last_line = M.buf_last_line();
	local last_col = M.buf_last_col();
	vim.api.nvim_buf_set_text(M.buf,
		0, 0, last_line, last_col,
		""
		)
end

function M.format_key(key)
	local text = key;
	return text
end

function M.add_key(key)
	M.open_win()
	M.append_buf(M.format_key(key))
end

function M.add_keylogger()
	vim.on_key(M.add_key)
end

return M
