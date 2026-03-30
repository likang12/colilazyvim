-- lazy.nvim
return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "ravitemer/codecompanion-history.nvim",
    {
      "MeanderingProgrammer/render-markdown.nvim",
      ft = { "markdown", "codecompanion" },
      opts = {
        file_types = { "markdown", "codecompanion" },
      },
    },
  },
  opts = {
    -- NOTE: The log_level is in `opts.opts`
    opts = {
      log_level = "DEBUG", -- or "TRACE"
    },
    display = {
      chat = {
        window = {
          layout = "vertical", -- 侧边窗口
          width = 0.33, -- 当前编辑区宽度的 1/3
        },
      },
    },
  },
  keys = {
    { "<leader>aa", "<cmd>CodeCompanionChat<cr>", desc = "Open CodeCompanion Chat" },
    {
      "<leader>ag",
      "<cmd>CodeCompanionChat adapter=cursor_cli command=default<cr>",
      desc = "Cursor Agent Mode",
    },
    {
      "<leader>ap",
      "<cmd>CodeCompanionChat adapter=cursor_cli command=plan<cr>",
      desc = "Cursor Plan Mode",
    },
    {
      "<leader>aq",
      "<cmd>CodeCompanionChat adapter=cursor_cli command=ask<cr>",
      desc = "Cursor Ask Mode",
    },
    {
      "<leader>as",
      "<cmd>CodeCompanionChat adapter=deepseek<cr>",
      desc = "CodeCompanion Tools Chat (HTTP)",
    },
    { "<leader>am", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Preview Render" },
    { "<leader>at", "<cmd>CodeCompanionChat Toggle<cr>", desc = "Toggle CodeCompanion Chat" },
    { "<leader>ah", "<cmd>CodeCompanionHistory<cr>", desc = "Open CodeCompanion History" },
    -- 内联编辑（选中代码后使用）
    { "<leader>ai", "<cmd>CodeCompanion<cr>", desc = "CodeCompanion Inline Edit" },
    -- 添加代码到聊天上下文
    { "<leader>ac", "<cmd>CodeCompanionChat Add<cr>", desc = "Add to CodeCompanion Chat" },
    -- 在 Visual 模式下保留选区范围（使用 : 而非 <cmd>）
    { "<leader>ai", ":CodeCompanion<cr>", mode = "v", desc = "CodeCompanion Inline Edit" },
    -- 在 Visual 模式下添加选中内容到聊天（避免占用常见的 ga/gc）
    { "<leader>ac", ":CodeCompanionChat Add<cr>", mode = "v", desc = "Add Selection to Chat" },
  },
  config = function(_, opts)
    -- Chat (ACP): switch model with /command, no env vars required.
    local acp = require("codecompanion.adapters.acp")
    local http = require("codecompanion.adapters.http")
    local default_chat_model = "gpt-5.3-codex-high"
    -- ACP model IDs differ from CLI --model names.
    -- CLI uses e.g. "gpt-5.3-codex-high", but ACP exposes
    -- "gpt-5.3-codex[reasoning=medium,fast=false]" with no high/low variants.
    local acp_model_map = {
      ["gpt-5.3-codex"] = "gpt-5.3-codex",
      ["gpt-5.4"] = "gpt-5.4",
      ["claude-sonnet-4-6"] = "claude-sonnet-4-6",
      ["claude-opus-4-6"] = "claude-opus-4-6",
      ["composer-2"] = "composer-2",
    }
    local function normalize_acp_model(model)
      if type(model) ~= "string" or model == "" then
        return acp_model_map["gpt-5.3-codex"] or "gpt-5.3-codex"
      end
      for prefix, acp_id in pairs(acp_model_map) do
        if model:find("^" .. prefix:gsub("%-", "%%-"):gsub("%.", "%%."), 1, false) then
          return acp_id
        end
      end
      return model
    end
    local function acp_model_from_selected_command(adapter)
      local selected = adapter
        and adapter.commands
        and (adapter.commands.selected or adapter.commands.default)
      if type(selected) ~= "table" then
        return normalize_acp_model(default_chat_model)
      end
      for i = 1, #selected - 1 do
        if selected[i] == "--model" and type(selected[i + 1]) == "string" and selected[i + 1] ~= "" then
          return normalize_acp_model(selected[i + 1])
        end
      end
      return normalize_acp_model(default_chat_model)
    end
    local cursor_adapter = acp.extend("cursor_cli", {
      commands = {
        default = {
          "agent",
          "--model",
          default_chat_model,
          "acp",
        },
        plan = {
          "agent",
          "--mode",
          "plan",
          "--model",
          default_chat_model,
          "acp",
        },
        ask = {
          "agent",
          "--mode",
          "ask",
          "--model",
          default_chat_model,
          "acp",
        },
        debug = {
          "agent",
          "--model",
          default_chat_model,
          "acp",
        },
        codex53 = {
          "agent",
          "--model",
          "gpt-5.3-codex",
          "acp",
        },
        gpt54 = {
          "agent",
          "--model",
          "gpt-5.4-medium",
          "acp",
        },
        sonnet46 = {
          "agent",
          "--model",
          "claude-sonnet-4-6",
          "acp",
        },
        composer2 = {
          "agent",
          "--model",
          "composer-2",
          "acp",
        },
      },
      defaults = {
        timeout = 60000,
        model = function(adapter)
          return acp_model_from_selected_command(adapter)
        end,
      },
    })
    local deepseek_adapter = http.extend("openai_compatible", {
      name = "deepseek",
      formatted_name = "DeepSeek",
      env = {
        api_key = "DEEPSEEK_API_KEY",
        url = "https://api.deepseek.com",
      },
      schema = {
        model = {
          default = "deepseek-chat",
        },
      },
    })
    local inline_adapter_name = vim.env.CODECOMPANION_INLINE_ADAPTER or "deepseek"
    local inline_adapter = deepseek_adapter
    if inline_adapter_name ~= "deepseek" then
      inline_adapter = {
        name = inline_adapter_name,
        model = vim.env.CODECOMPANION_INLINE_MODEL,
      }
    end

    local plugin_opts = vim.tbl_deep_extend("force", opts or {}, {
      adapters = {
        acp = {
          cursor_cli = cursor_adapter,
        },
        http = {
          deepseek = deepseek_adapter,
        },
      },
      interactions = {
        chat = {
          adapter = "cursor_cli",
        },
        inline = {
          -- Inline only supports HTTP adapters.
          adapter = inline_adapter,
        },
      },
      extensions = {
        history = {
          enabled = true,
          opts = {
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion_chats.json",
            -- History title generation does not support ACP adapters
            -- (e.g. cursor_cli), so force an HTTP adapter here.
            title_generation_opts = {
              adapter = "deepseek",
              model = "deepseek-chat",
            },
          },
        },
      },
    })
    require("codecompanion").setup(plugin_opts)
  end,
  --- Other package managers
  --- config = function(_, opts)
  ---   require("illuminate").setup(opts)
  --- end,
}
