local M = {
	width = 20,
	height = 2,

}
local config = {
	widht = 20,
	height = 2,
}

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
		focusable = false,
		relative = "editor",
		anchor = "NE",
		zindex = 300,
		row = 0,
		col = vim.o.columns,
		width = M.width,
		height = M.height,
	}
	M.win = vim.api.nvim_open_win(M.buf, false, options)
	-- nivm_win_set_hl_ns(M.win, {ns_id})
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
	local first_line = vim.api.nvim_buf_get_lines(M.buf, -2, -1, 0)[1]
	if type(first_line) ~= "string" then
		return -1
	else
		return string.len(first_line) - 1
	end
end

function M.append_buf(text)
	--vim.api.nvim_buf_get_lines(13, -2, -1, 0)
	local last_line = M.buf_last_line();
	local last_col = M.buf_last_col();
	vim.api.nvim_buf_set_text(M.buf,
		last_line, last_col + 1, last_line, last_col + 1,
		{ text }
		)
	-- last character is not visible
	if vim.fn.screenpos(M.win, 1, 1000).row == 0 then
		-- delete first visual line from buffer
		local last_vcol = vim.fn.virtcol2col(M.win, 1, M.width) - 1
		vim.api.nvim_buf_set_text(M.buf,
			0, 0, 0, last_vcol + 1,
			{ "" }
			)
	end
end
function M.clear_buf()
	vim.api.nvim_buf_set_lines(M.buf,
		0, -1, true,
		{ "" }
		)
end

-- SpecialKey
M.cazan = {
	["\n"] = "^J",
	["\t"] = "^I",
	["\x0d"] = "<cr>",
	["scl"] = "s",
	["\x80kb"] = "<bs>",
	["\x80ku"] = "<up>",
	["\x80kd"] = "<down>",
	["\x80kr"] = "<right>",
	["\x80kl"] = "<left>",
}
M.cazan2 = {
	["\n"] = "^J",
	["\t"] = "↔",
	["\x0d"] = "⏎",
	["scl"] = "s",
	["\x80kb"] = "⌫",
	["\x80ku"] = "↑",
	["\x80kd"] = "↓",
	["\x80kr"] = "→",
	["\x80kl"] = "←",
}
function M.format_key(key)
	local text = M.cazan2[key]
	if text == nil then
		text = key
	end
	return text
end

function M.add_key(key)
	M.open_win()
	M.append_buf(M.format_key(key))
end

function M.setup(_)
	M.namespace = vim.api.nvim_create_namespace('ScreenKeys')
	vim.on_key(M.add_key, M.namespace)
	local M.augroup = vim.api.nvim_create_augroup('ScreenKeys', {
		clear = true,
	})
	vim.api.nvim_create_autocmd({'CursorHold', 'CursorHoldI'}, {
		group = M.augroup,
		pattern = {'*'},
		callback = function(ev)
			M.clear_buf()
			M.close_win()
		end
		})
	vim.api.nvim_create_autocmd({'TabLeave'}, {
		group = M.augroup,
		pattern = {'*'},
		callback = function(ev)
			M.close_win()
		end
		})
	vim.api.nvim_create_autocmd({'TabEnter'}, {
		group = M.augroup,
		pattern = {'*'},
		callback = function(ev)
			M.open_win()
		end
		})
end

function M.stop()
	-- TODO clear on_key function callback from namespace M.namespace
	vim.api.nvim_del_augroup_by_id(M.augroup)
end
end

return M
