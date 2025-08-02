local cmp = require("cmp")
local M = {}

local default_config = {
	default_lang = { "en" },
	max_items = 5,
	case_sensitive = true,
	lists_dir = vim.fn.stdpath("config") .. "/wordlists",
}
local user_config = {}
local wordlists_cache = {}
local function capitalize(word)
	return word:sub(1, 1):upper() .. word:sub(2)
end


local function get_active_langs()

	local sl = vim.opt_local.spelllang:get() or {}
	local codes = {}
	for _, lang in ipairs(sl) do
		local code = lang:sub(1, 2)
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
		merged[lang] = load_one(lang)

	end
	return merged
end


local function complete_prefix(wordlist, input, max_items, case_sensitive)
	local results = {}
	local input_lowered = input:lower()

	for _, w in ipairs(wordlist) do
		w_lowered = w:lower()
		
		if w_lowered:sub(1, #input_lowered) == input_lowered then
			if input ~= input_lowered and case_sensitive then
					table.insert(results, {
						label = capitalize(w),
						kind = cmp.lsp.CompletionItemKind.Text,
					})
			else
			table.insert(results, {
					label = w,
					kind = cmp.lsp.CompletionItemKind.Text,
				})
			end


			if #results >= max_items then
				break
			end
		end
	end

	return results
end

M.setup = function(opts)
	user_config = {}
	user_config.default_lang = opts.default_lang or default_config.default_lang
	user_config.max_items = opts.max_items or default_config.max_items
	if opts.case_sensitive == nil then
		user_config.case_sensitive == default_config.case_sensitive
	else
		user_config.case_sensitive = opts.case_sensitive
	end
	user_config.lists_dir = opts.lists_dir or default_config.lists_dir
	  vim.schedule(function()
	  print(vim.inspect(user_config.case_sensitive))
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
	
	local langs = get_active_langs()
	local count = #langs
	local wordlist = load_wordlist(langs)
	local before = params.context.cursor_before_line
	local input = before:match("%S+$") or ""
	if input == "" or wordlist == {} then
		return callback({ items = {} })
	end
	
	if count == 1 then
		local matches = complete_prefix(wordlist[langs[1]], input, user_config.max_items, user_config.case_sensitive)
		return callback({ items = matches, isIncomplete = true,})
	end
	
	local output = {}
	local res = ""
	for _, words in pairs(wordlist) do
		print(vim.inspect("here"))
		local matches = complete_prefix(words, input, user_config.max_items, user_config.case_sensitive)
		for _, match in ipairs(matches) do
			table.insert(output, match)
		end
	end
	
	return callback({items = output, isIncomplete = true,})
end

return M
