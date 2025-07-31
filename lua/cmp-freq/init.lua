local cmp = require("cmp")
local M = {}

local default_config = {
	default_lang = { "en" },
	max_items = 10,
	case_sensitive = false,
	lists_dir = vim.fn.stdpath("config") .. "/wordlists",
	mapping = {
		enable = true,
		key = "<leader>fl", -- override language
	},
}
local user_config = {}
local wordlists_cache = {}

-- 2) Helpers

-- Merge the list of languages from buffer override, spelllang, or default
local function get_active_langs(bufnr)
	-- buf override
	if vim.b[bufnr].cmp_wordlist_lang then
		return { vim.b[bufnr].cmp_wordlist_lang }
	end

	-- from spelllang
	local sl = vim.opt_local.spelllang:get() or {}
	local codes = {}
	for _, lang in ipairs(sl) do
		local code = lang:match("^([^_%,]+)")
		if code then
			table.insert(codes, code)
		end
	end
	if #codes > 0 then
		return codes
	end

	-- fallback
	return user_config.default_lang
end

-- Load one .bin list for a given code (cached)
local function load_one(lang)
	if wordlists_cache[lang] then
		return wordlists_cache[lang]
	end

	local paths = {
		vim.fn.getcwd() .. "/lists/" .. lang .. ".bin",
		user_config.lists_dir .. "/" .. lang .. ".bin",
	}
	for _, p in ipairs(paths) do
		if vim.fn.filereadable(p) == 1 then
			wordlists_cache[lang] = vim.fn.readfile(p)
			return wordlists_cache[lang]
		end
	end

	-- missing file → empty
	wordlists_cache[lang] = {}
	return wordlists_cache[lang]
end

-- Merge multiple language lists into one (preserving order)
local function load_wordlist(langs)
	local merged = {}
	for _, lang in ipairs(langs) do
		for _, w in ipairs(load_one(lang)) do
			table.insert(merged, w)
		end
	end
	return merged
end

-- Prefix matcher
local function complete_prefix(wordlist, input, max_items, case_sensitive)
	local results = {}
	local norm_in = case_sensitive and input or input:lower()

	for _, w in ipairs(wordlist) do
		local cand = case_sensitive and w or w:lower()
		if cand:sub(1, #norm_in) == norm_in then
			table.insert(results, {
				label = w,
				kind = cmp.lsp.CompletionItemKind.Text,
			})
			if #results >= max_items then
				break
			end
		end
	end

	return results
end

local function setup_commands()
	-- User command :FreqLang <lang>
	vim.api.nvim_create_user_command("FreqLang", function(opts)
		vim.b[vim.api.nvim_get_current_buf()].cmp_wordlist_lang = opts.args
		print("Frequency source language set to: " .. opts.args)
	end, {
		nargs = 1,
		complete = function(ArgLead)
			-- complete available .bin files in lists_dir
			local files = vim.fn.globpath(user_config.lists_dir, "*.bin", false, true)
			local langs = {}
			for _, f in ipairs(files) do
				langs[#langs + 1] = vim.fn.fnamemodify(f, ":t:r")
			end
			return vim.tbl_filter(function(lang)
				return lang:match("^" .. ArgLead)
			end, langs)
		end,
		desc = "Set frequency source language for current buffer",
	})

	if user_config.mapping.enable then
		vim.keymap.set(
			"n",
			user_config.mapping.key,
			":FreqLang ",
			{ noremap = true, silent = false, desc = "Set wordlist language" }
		)
	end
end

-- 8) Source API
M.setup = function(opts)
	user_config = vim.tbl_deep_extend("force", default_config, opts or {})
	setup_commands()
end
M.new = function()
	return setmetatable({}, { __index = M })
end

function M:is_available()
	local ft = vim.bo.filetype
	return ft == "markdown" or ft == "org" or ft == "text" or ft == "plain"
end

function M:complete(params, callback)
	local bufnr = params.bufnr
	local langs = get_active_langs(bufnr)
	local wordlist = load_wordlist(langs)
	local before = params.context.cursor_before_line
	local input = before:match("%S+$") or ""

	if input == "" or #wordlist == 0 then
		return callback({ items = {} })
	end

	local matches = complete_prefix(wordlist, input, user_config.max_items, user_config.case_sensitive)

	callback({ items = matches })
end

-- 4) Register
cmp.register_source("cmp-freq", M.new())

return M
