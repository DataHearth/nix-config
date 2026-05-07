-- Add blink.cmp capabilities + ufo folding to all LSP servers
local capabilities = require("blink.cmp").get_lsp_capabilities()
capabilities.textDocument.foldingRange = {
	dynamicRegistration = false,
	lineFoldingOnly = true,
}
vim.lsp.config("*", { capabilities = capabilities })

-- Diagnostics UI: full message below current line, signs always, short
-- virtual_text on non-current lines. Prevents overlap with gitsigns blame.
vim.diagnostic.config({
	virtual_lines = { current_line = true },
	virtual_text = {
		current_line = false,
		severity = { min = vim.diagnostic.severity.WARN },
		prefix = "● ",
		spacing = 2,
		source = "if_many",
	},
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.INFO] = " ",
			[vim.diagnostic.severity.HINT] = " ",
		},
	},
	severity_sort = true,
	underline = true,
	update_in_insert = false,
	float = {
		border = "rounded",
		source = "if_many",
		header = "",
		prefix = function(diag)
			local icons = {
				[vim.diagnostic.severity.ERROR] = " ",
				[vim.diagnostic.severity.WARN] = " ",
				[vim.diagnostic.severity.INFO] = " ",
				[vim.diagnostic.severity.HINT] = " ",
			}
			local hls = {
				[vim.diagnostic.severity.ERROR] = "DiagnosticError",
				[vim.diagnostic.severity.WARN] = "DiagnosticWarn",
				[vim.diagnostic.severity.INFO] = "DiagnosticInfo",
				[vim.diagnostic.severity.HINT] = "DiagnosticHint",
			}
			return icons[diag.severity] or "● ", hls[diag.severity]
		end,
	},
})

-- Enable LSP servers
vim.lsp.enable({
	"bashls",
	"biome",
	"dockerls",
	"gopls",
	"html",
	"htmx",
	"jsonls",
	"lua_ls",
	"nixd",
	"pyright",
	"ruff",
	"rust_analyzer",
	"svelte",
	"tailwindcss",
	"taplo",
	"ts_ls",
	"yamlls",
})

-- LSP keymaps on attach
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = desc })
		end

		map("n", "K", function()
			vim.lsp.buf.hover({ border = "rounded" })
		end, "Hover")
		map("n", "<leader>a", vim.lsp.buf.code_action, "Code action")
		map("n", "<leader>r", vim.lsp.buf.rename, "Rename")
		map("n", "<leader>gd", vim.lsp.buf.definition, "Goto definition")
		map("n", "<leader>gr", vim.lsp.buf.references, "References")

		-- Only bind declaration if the server supports it (gopls does not).
		if client and client:supports_method("textDocument/declaration") then
			map("n", "<leader>gD", vim.lsp.buf.declaration, "Goto declaration")
		end
	end,
})
