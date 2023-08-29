M = {
	width = 29,
	height = 1,
}

function M.create_buf()
	M.buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(M.buf, "filetype", "screenkeys")
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
		anchor = "SE",
		zindex = 300,
		row = 0,
		col = vim.o.columns + 1e9,
		width = M.width,
		height = M.height,
	}
	M.win = vim.api.nvim_open_win(M.buf, false, options)
	vim.api.nvim_win_set_option(M.win,  "winhighlight", "NormalFloat:ScreenKeys")
	-- nivm_win_set_hl_ns(M.win, {ns_id})
end
function M.close_win()
	if M.win ~= nil and vim.api.nvim_win_is_valid(M.win) then
		vim.api.nvim_win_close(M.win, false)
	end
end


M.cazan = {
	["<nl>"] = "<c-j>",
	["<tab>"] = "↔",
	["<cr>"] = "⏎",
	["<space>"] = "␣",
	["scl"] = "s",
	["<bs>"] = "⌫",
	["<up>"] = "↑",
	["<down>"] = "↓",
	["<right>"] = "→",
	["<left>"] = "←",
}
local function lpad(str, len, char)
	local strlen = vim.api.nvim_strwidth(str)
	local res = string.rep(char or " ", len - strlen) .. str
	return res
end
function M.format_key(key)
	local key = vim.fn.keytrans(key)
	if #key > 1 then
		key = string.lower(key)
	end
	key = M.cazan[key] or key
	--key = pad(key, 5)
	return key
end

M.last_keys = {}
function M.add_key(key) 
	key = M.format_key(key)
	table.insert(M.last_keys, key)
	if(#M.last_keys > 20) then
		table.remove(M.last_keys, 1)
	end
end

function M.render()
	local separator = " "
	local line = table.concat(M.last_keys, separator)
	while vim.api.nvim_strwidth(line) > M.width do
		table.remove(M.last_keys, 1)
		line = table.concat(M.last_keys, separator)
	end
	line = lpad(line, M.width)
	vim.api.nvim_buf_set_lines(M.buf, 0, 1, false, { line })
	M.open_win()
end

function M.callback(key)
	M.add_key(key)
	M.render()
end

function M.setup(_)
	if M.buf == nil or not vim.api.nvim_buf_is_valid(M.buf) then
		M.create_buf()
	end
	M.namespace = vim.api.nvim_create_namespace('ScreenKeys')
	vim.on_key(M.callback, M.namespace)
	M.augroup = vim.api.nvim_create_augroup('ScreenKeys', {
		clear = true,
	})
	vim.api.nvim_set_hl(0, 'ScreenKeys', { link = "SpecialKey" })
	vim.api.nvim_create_autocmd({'CursorHold', 'CursorHoldI'}, {
		group = M.augroup,
		pattern = {'*'},
		callback = function(ev)
			M.last_keys = { }
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

return M
