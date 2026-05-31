return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    init = function()
      local function blend(fg, bg, alpha)
        local function channel(color, shift)
          return math.floor(color / shift) % 256
        end

        local r = channel(fg, 0x10000) * alpha + channel(bg, 0x10000) * (1 - alpha)
        local g = channel(fg, 0x100) * alpha + channel(bg, 0x100) * (1 - alpha)
        local b = channel(fg, 1) * alpha + channel(bg, 1) * (1 - alpha)

        return math.floor(r + 0.5) * 0x10000 + math.floor(g + 0.5) * 0x100 + math.floor(b + 0.5)
      end

      local function set_inline_code_bg()
        local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
        local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false })
        local normal_float = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false })
        local color_column = vim.api.nvim_get_hl(0, { name = "ColorColumn", link = false })
        local bg = cursorline.bg or normal_float.bg or color_column.bg

        if bg then
          bg = normal.bg and blend(bg, normal.bg, 0.45) or bg
          vim.api.nvim_set_hl(0, "RenderMarkdownInlineCodeBg", { bg = bg })
        end
      end

      set_inline_code_bg()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_inline_code_bg,
      })
    end,
    opts = {
      heading = {
        icons = { "󰼏 ", "󰎨 ", "󰎫 ", "󰎮 ", "󰎱 ", "󰎴 " },
        backgrounds = {
          "RenderMarkdownH2Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH2Bg",
          "RenderMarkdownH2Bg",
        },
        foregrounds = {
          "RenderMarkdownH2",
          "RenderMarkdownH2",
          "RenderMarkdownH2",
          "RenderMarkdownH2",
          "RenderMarkdownH2",
          "RenderMarkdownH2",
        },
        width = "block",
        border = false,
      },
      code = {
        language = false,
        language_icon = false,
        language_name = false,
        language_info = false,
        border = "thin",
        highlight_inline = "RenderMarkdownInlineCodeBg",
      },
      link = {
        enabled = true,
        render_modes = false,
        footnote = {
          enabled = true,
          superscript = true,
          prefix = "",
          suffix = "",
        },
        image = "󰥶 ",
        email = "󰀓 ",
        hyperlink = "󰌹 ",
        highlight = "RenderMarkdownLink",
        wiki = {
          icon = "󱗖 ",
          body = function()
            return nil
          end,
          highlight = "RenderMarkdownWikiLink",
        },
        custom = {
          web = { pattern = "^http", icon = "󰖟 " },
          github = { pattern = "github%.com", icon = "󰊤 " },
          gitlab = { pattern = "gitlab%.com", icon = "󰮠 " },
          stackoverflow = { pattern = "stackoverflow%.com", icon = "󰓌 " },
          wikipedia = { pattern = "wikipedia%.org", icon = "󰖬 " },
          youtube = { pattern = "youtube%.com", icon = "󰗃 " },
        },
      },
      callout = {
        note = { raw = "[!NOTE]", rendered = "󰋽 Note", highlight = "RenderMarkdownInfo" },
        tip = { raw = "[!TIP]", rendered = "󰌶 Tip", highlight = "RenderMarkdownSuccess" },
        important = { raw = "[!IMPORTANT]", rendered = "󰅾 Important", highlight = "RenderMarkdownHint" },
        warning = { raw = "[!WARNING]", rendered = "󰀪 Warning", highlight = "RenderMarkdownWarn" },
        caution = { raw = "[!CAUTION]", rendered = "󰳦 Caution", highlight = "RenderMarkdownError" },
        abstract = { raw = "[!ABSTRACT]", rendered = "󰨸 Abstract", highlight = "RenderMarkdownInfo" },
        summary = { raw = "[!SUMMARY]", rendered = "󰨸 Summary", highlight = "RenderMarkdownInfo" },
        tldr = { raw = "[!TLDR]", rendered = "󰨸 Tldr", highlight = "RenderMarkdownInfo" },
        info = { raw = "[!INFO]", rendered = "󰋽 Info", highlight = "RenderMarkdownInfo" },
        todo = { raw = "[!TODO]", rendered = "󰗡 Todo", highlight = "RenderMarkdownInfo" },
        hint = { raw = "[!HINT]", rendered = "󰌶 Hint", highlight = "RenderMarkdownSuccess" },
        success = { raw = "[!SUCCESS]", rendered = "󰄬 Success", highlight = "RenderMarkdownSuccess" },
        check = { raw = "[!CHECK]", rendered = "󰄬 Check", highlight = "RenderMarkdownSuccess" },
        done = { raw = "[!DONE]", rendered = "󰄬 Done", highlight = "RenderMarkdownSuccess" },
        question = { raw = "[!QUESTION]", rendered = "󰘥 Question", highlight = "RenderMarkdownWarn" },
        help = { raw = "[!HELP]", rendered = "󰘥 Help", highlight = "RenderMarkdownWarn" },
        faq = { raw = "[!FAQ]", rendered = "󰘥 Faq", highlight = "RenderMarkdownWarn" },
        attention = { raw = "[!ATTENTION]", rendered = "󰀪 Attention", highlight = "RenderMarkdownWarn" },
        failure = { raw = "[!FAILURE]", rendered = "󰅖 Failure", highlight = "RenderMarkdownError" },
        fail = { raw = "[!FAIL]", rendered = "󰅖 Fail", highlight = "RenderMarkdownError" },
        missing = { raw = "[!MISSING]", rendered = "󰅖 Missing", highlight = "RenderMarkdownError" },
        danger = { raw = "[!DANGER]", rendered = "󱐌 Danger", highlight = "RenderMarkdownError" },
        error = { raw = "[!ERROR]", rendered = "󱐌 Error", highlight = "RenderMarkdownError" },
        bug = { raw = "[!BUG]", rendered = "󰨰 Bug", highlight = "RenderMarkdownError" },
        example = { raw = "[!EXAMPLE]", rendered = "󰉹 Example", highlight = "RenderMarkdownHint" },
        quote = { raw = "[!QUOTE]", rendered = "󱆨 Quote", highlight = "RenderMarkdownQuote" },
        cite = { raw = "[!CITE]", rendered = "󱆨 Cite", highlight = "RenderMarkdownQuote" },
      },
      checkbox = {
        enabled = true,
        render_modes = false,
        bullet = false,
        right_pad = 1,
        unchecked = {
          icon = "󰄱 ",
          highlight = "RenderMarkdownUnchecked",
          scope_highlight = nil,
        },
        checked = {
          icon = "󰱒 ",
          highlight = "RenderMarkdownChecked",
          scope_highlight = nil,
        },
        custom = {
          todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo", scope_highlight = nil },
        },
      },
      bullet = {
        enabled = true,
        render_modes = false,
        icons = { "●", "○", "◆", "◇" },
        ordered_icons = function(ctx)
          local value = vim.trim(ctx.value)
          local index = tonumber(value:sub(1, #value - 1))
          return ("%d."):format(index > 1 and index or ctx.index)
        end,
        left_pad = function(ctx)
          return ctx.level * vim.bo.tabstop
        end,
        right_pad = 0,
        highlight = "RenderMarkdownBullet",
        scope_highlight = {},
      },
      quote = { icon = "▋" },
      anti_conceal = {
        enabled = true,
        ignore = {
          code_background = true,
          sign = true,
        },
        above = 0,
        below = 0,
      },
    },
  },
}

