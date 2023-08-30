local M = { }
local config = {
	width = 29,
	height = 1,
	winblend = 0,
	special_keys = true,
	start_on_setup = false,
	carret_notation = false,
	keys = {
		["<tab>"] = "↔",
		["<cr>"] = "⏎",
		["<space>"] = "␣",
		["<bs>"] = "⌫",
		["<up>"] = "↑",
		["<down>"] = "↓",
		["<right>"] = "→",
		["<left>"] = "←",
	}
}
local namespace
local augroup
local buf
local win
local last_keys = {}

local function create_buf()
	buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "filetype", "screenkeys")
end
local function open_win()
	if win ~= nil and vim.api.nvim_win_is_valid(win) then
		return
	end
	if(buf == nil) then
		create_buf()
	end
	-- listed = false, scratch = true
	local win_config = {
		style = "minimal",
		focusable = false,
		relative = "editor",
		anchor = "SE",
		zindex = 300,
		row = 0,
		col = vim.o.columns + 1e9,
		width = config.width,
		height = config.height,
	}
	win = vim.api.nvim_open_win(buf, false, win_config)
	vim.api.nvim_win_set_option(win,  "winhighlight", "NormalFloat:ScreenKeys")
	vim.api.nvim_win_set_option(win,  "winblend", config.winblend)
	-- nivm_win_set_hl_ns(win, {ns_id})
end
local function close_win()
	if win ~= nil and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, false)
	end
end

local function lpad(str, len, char)
	local strlen = vim.api.nvim_strwidth(str)
	local res = string.rep(char or " ", len - strlen) .. str
	return res
end

local transkey = {
	["<nl>"] = "<c-j>",
}
local function format_key(key)
	local key = vim.fn.keytrans(key)
	if #key > 1 then
		key = key:lower()
	end
	key = transkey[key] or key
	if config.special_keys then
		key = config.keys[key] or key
	end
	return key
end

local function add_key(key) 
	key = format_key(key)
	table.insert(last_keys, key)
	if(#last_keys > 20) then
		table.remove(last_keys, 1)
	end
end

local function render()
	local separator = " "
	local line = table.concat(last_keys, separator)
	while vim.api.nvim_strwidth(line) > config.width do
		table.remove(last_keys, 1)
		line = table.concat(last_keys, separator)
	end
	line = lpad(line, config.width)
	vim.api.nvim_buf_set_lines(buf, 0, 1, false, { line })
	open_win()
end

local function callback(key)
	add_key(key)
	render()
end

function M.start()
	if buf == nil or not vim.api.nvim_buf_is_valid(buf) then
		create_buf()
	end
	vim.on_key(callback, namespace)
	augroup = vim.api.nvim_create_augroup('ScreenKeys', {
		clear = true,
	})
	vim.api.nvim_set_hl(0, 'ScreenKeys', { link = "SpecialKey" })
	vim.api.nvim_create_autocmd({'CursorHold', 'CursorHoldI'}, {
		group = augroup,
		pattern = {'*'},
		callback = function(ev)
			last_keys = { }
			close_win()
		end
		})
	vim.api.nvim_create_autocmd({'TabLeave'}, {
		group = augroup,
		pattern = {'*'},
		callback = function(ev)
			close_win()
		end
		})
	vim.api.nvim_create_autocmd({'TabEnter'}, {
		group = augroup,
		pattern = {'*'},
		callback = function(ev)
			open_win()
		end
		})
end

function M.stop()
	vim.on_key(nil, namespace)
	vim.api.nvim_del_augroup_by_id(augroup)
	last_keys = { }
	close_win()
end

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})
	namespace = vim.api.nvim_create_namespace('ScreenKeys')
	vim.api.nvim_create_user_command("KeyStart", "lua require('screenkeys').start()", { })
	vim.api.nvim_create_user_command("KeyStop", "lua require('screenkeys').stop()", { })
	if config.start_on_setup then
		M.start()
	end
end

return M
