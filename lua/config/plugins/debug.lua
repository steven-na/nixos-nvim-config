return {
	{
		"nvim-dap",
		keys = {
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "[D]ebug: Toggle [B]reakpoint" },
			{ "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "[D]ebug: Conditional [B]reakpoint" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "[D]ebug: [C]ontinue" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "[D]ebug: Step [I]nto" },
			{ "<leader>do", function() require("dap").step_over() end, desc = "[D]ebug: Step [O]ver" },
			{ "<leader>dO", function() require("dap").step_out() end, desc = "[D]ebug: Step [O]ut" },
			{ "<leader>dr", function() require("dap").repl.open() end, desc = "[D]ebug: [R]EPL" },
			{ "<leader>dl", function() require("dap").run_last() end, desc = "[D]ebug: Run [L]ast" },
			{ "<leader>dt", function() require("dap").terminate() end, desc = "[D]ebug: [T]erminate" },
		},
		after = function(_)
			local dap = require("dap")

			-- codelldb adapter
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = {
					command = vim.fn.exepath("codelldb"),
					args = { "--port", "${port}" },
				},
			}

			-- Debug configurations for C/C++/Rust
			local configs = {
				{
					name = "Launch executable",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					args = function()
						local input = vim.fn.input("Arguments: ")
						return vim.split(input, " ", { trimempty = true })
					end,
					cwd = "${workspaceFolder}",
				},
				{
					name = "Attach to process",
					type = "codelldb",
					request = "attach",
					pid = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
				},
			}

			dap.configurations.c = configs
			dap.configurations.cpp = configs
			dap.configurations.rust = configs

			-- Custom breakpoint signs
			vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
			vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DiagnosticInfo" })
			vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "DapStoppedLine" })
			vim.fn.sign_define("DapBreakpointRejected", { text = "○", texthl = "DiagnosticHint" })
		end,
	},
	{
		"nvim-dap-ui",
		on_plugin = { "nvim-dap" },
		keys = {
			{ "<leader>du", function() require("dapui").toggle() end, desc = "[D]ebug: Toggle [U]I" },
			{ "<leader>de", function() require("dapui").eval() end, desc = "[D]ebug: [E]val Expression", mode = { "n", "v" } },
		},
		after = function(_)
			local dapui = require("dapui")
			dapui.setup()

			local dap = require("dap")
			dap.listeners.after.event_initialized["dapui_config"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_config"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_config"] = function()
				dapui.close()
			end
		end,
	},
	{
		"nvim-dap-virtual-text",
		on_plugin = { "nvim-dap" },
		after = function(_)
			require("nvim-dap-virtual-text").setup()
		end,
	},
}
