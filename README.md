# cmp-freq
a neovim completion source based on word frequency that supports multiple languages and "custom" languages"
<img width="1140" height="611" alt="image" src="https://github.com/user-attachments/assets/65602440-ec8d-4722-aa9e-41bc5b70f8a6" />
Based on several word frequency lists, this source gives the results of these lists as desired, based the spell settings
the packaged word frequency lists come from this project: https://github.com/hermitdave/FrequencyWords and are under the CC-by-sa-4.0 license 
## ⇁ Install
- [neovim](https://github.com/neovim/neovim) 0.8.0+ required 
- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) required
- [lazy.nvim](https://github.com/folke/lazy.nvim)
```lua
{
"TheShadowblast123/cmp-freq",
dependencies = { "hrsh7th/nvim-cmp" },
 config = function()
	  require("cmp-freq").setup()
	end,
},
{
'hrsh7th/nvim-cmp', 
	sources = {
		{ name = 'cmp-freq' },
	}
}
```
## ⇁ Configuration
### ⇁ Default:
``` lua
local default_config = {
	default_lang = { "en" },
	max_items = 5,
	case_sensitive = false,
	lists_dir = vim.fn.stdpath("config") .. "/wordlists",
}
```
- default_lang => the lang that cmp-freq will default to, though it mainly will use whatever the spell lang is
- max_items => the maximum amount of suggested results
- case_sensitive => NOT IMPLEMENTED, will upper case first letter if the first letter is already uppercased.
- lists_dir => a directory for custom .bin word lists
