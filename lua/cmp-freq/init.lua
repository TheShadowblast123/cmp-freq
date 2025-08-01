local cmp = require("cmp")
local M = {}

local default_config = {
	default_lang = { "en" },
	max_items = 5,
	case_sensitive = false,
	lists_dir = vim.fn.stdpath("config") .. "/wordlists",
}
local user_config = {}
local wordlists_cache = {}

local function get_active_langs(bufnr)

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
	return user_config.default_lang
end

local function load_one(lang)
	if wordlists_cache[lang] then
		return wordlists_cache[lang]
	end
	local paths = {
	debug.getinfo(1, "S").source:sub(2):sub(1, -10).. "/lists/" .. lang .. ".bin",
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

local function load_wordlist(langs)
	local merged = {}
	for _, lang in ipairs(langs) do
		for _, w in ipairs(load_one(lang)) do
			table.insert(merged, w)
		end
	end
	return merged
end


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

M.setup = function(opts)
	user_config = default_config or opts
	  vim.schedule(function()
    require("cmp").register_source("cmp-freq", M.new())
  end)
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

	callback({ items = matches, isIncomplete = true,})
end

return M