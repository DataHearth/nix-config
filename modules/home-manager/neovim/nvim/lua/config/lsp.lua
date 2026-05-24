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

-- :LspRestart [name ...] — stop and relaunch LSP clients (all attached by
-- default, or only the named ones). We use the native vim.lsp API (no
-- nvim-lspconfig), so this replicates its command: stop the clients, wait for
-- the processes to exit, then re-fire FileType so vim.lsp.enable() relaunches
-- them. Config edits live in lsp/*.lua and are read at startup, so this
-- restarts servers with the *running* config (good for crashes/re-analysis);
-- applying config changes still needs a rebuild + fresh nvim.
vim.api.nvim_create_user_command("LspRestart", function(opts)
	local clients = vim.lsp.get_clients()
	if #opts.fargs > 0 then
		clients = vim.tbl_filter(function(c)
			return vim.tbl_contains(opts.fargs, c.name)
		end, clients)
	end
	if #clients == 0 then
		vim.notify("LspRestart: no matching clients", vim.log.levels.WARN)
		return
	end

	local buffers = {}
	for _, client in ipairs(clients) do
		for buf in pairs(client.attached_buffers) do
			buffers[buf] = true
		end
	end

	vim.lsp.stop_client(clients)

	-- stop_client is async; poll until every client has exited before
	-- re-attaching, otherwise vim.lsp.start may reuse a half-stopped client.
	local timer = assert(vim.uv.new_timer())
	timer:start(100, 100, vim.schedule_wrap(function()
		for _, client in ipairs(clients) do
			if not client:is_stopped() then
				return
			end
		end
		timer:stop()
		timer:close()
		for buf in pairs(buffers) do
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_exec_autocmds("FileType", { buffer = buf })
			end
		end
	end))
end, {
	nargs = "*",
	desc = "Restart LSP client(s)",
	complete = function()
		return vim.tbl_map(function(c)
			return c.name
		end, vim.lsp.get_clients())
	end,
})
