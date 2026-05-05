---与 colors.lua 中 `RenderMarkdown` + 后缀一致，用少量内置 highlight 覆盖（不用 default，盖过插件的 default=true）
---@return nil
local function apply_simple_render_markdown_hl()
  local P = 'RenderMarkdown'
  -- 标题：链到 markdown treesitter 各级 heading（主题里多为蓝色/青色系）
  for lvl = 1, 6 do
    vim.api.nvim_set_hl(0, P .. 'H' .. lvl, {
      link = ('@markup.heading.%d.markdown'):format(lvl),
    })
  end
  ---@type table<string, string>
  local map = {
    H1Bg = 'Normal',
    H2Bg = 'Normal',
    H3Bg = 'Normal',
    H4Bg = 'Normal',
    H5Bg = 'Normal',
    H6Bg = 'Normal',
    -- 代码块
    Code = 'Folded',
    CodeInfo = 'Comment',
    CodeBorder = 'Folded',
    CodeFallback = 'Normal',
    CodeInline = 'Pmenu',
    -- 引用
    Quote = 'Comment',
    Quote1 = 'Comment',
    Quote2 = 'Comment',
    Quote3 = 'Comment',
    Quote4 = 'Comment',
    Quote5 = 'Comment',
    Quote6 = 'Comment',
    -- 通用
    InlineHighlight = 'Visual',
    Bullet = 'Normal',
    Dash = 'LineNr',
    Sign = 'SignColumn',
    Math = 'Special',
    Indent = 'Whitespace',
    HtmlComment = 'Comment',
    -- 链接
    Link = 'Underlined',
    LinkTitle = 'Special',
    WikiLink = 'Underlined',
    -- 任务列表
    Unchecked = 'LineNr',
    Checked = 'String',
    Todo = 'Comment',
    -- 表格
    TableHead = 'Title',
    TableRow = 'Normal',
    -- Callout 分类（信息类沿用 Title；若需与标题蓝区分可再改）
    Success = 'String',
    Info = 'Title',
    Hint = 'Directory',
    Warn = 'WarningMsg',
    Error = 'ErrorMsg',
  }
  for suffix, target in pairs(map) do
    vim.api.nvim_set_hl(0, P .. suffix, { link = target })
  end
end

return {
  'MeanderingProgrammer/render-markdown.nvim',
  -- 与 preset.lazy 的 file_types 对齐；未用 Avante 可从列表去掉
  ft = { 'markdown', 'norg', 'rmd', 'org', 'codecompanion', 'Avante' },
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' },
  config = function()
    apply_simple_render_markdown_hl()
    vim.api.nvim_create_autocmd('ColorScheme', {
      group = vim.api.nvim_create_augroup('RenderMarkdownSimpleHl', { clear = true }),
      pattern = '*',
      callback = function()
        vim.schedule(apply_simple_render_markdown_hl)
      end,
    })
  end,
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {
    -- 文档：默认 true；preset.lazy 会合并进最终配置
    enabled = true,
    preset = 'lazy',
    -- 不要用 `true`：Insert 里也会 conceal，不方便改 `#` 等
    render_modes = { 'n', 'c', 't' },
    debounce = 100,
    max_file_size = 10.0,
    nested = true,
    restart_highlighter = false,
    change_events = {},

    injections = {
      gitcommit = {
        enabled = true,
        query = [[
            ((message) @injection.content
                (#set! injection.combined)
                (#set! injection.include-children)
                (#set! injection.language "markdown"))
        ]],
      },
    },

    patterns = {
      markdown = {
        disable = true,
        directives = {
          { id = 17, name = 'conceal_lines' },
          { id = 18, name = 'conceal_lines' },
        },
      },
    },

    anti_conceal = {
      enabled = true,
      disabled_modes = false,
      above = 0,
      below = 0,
      -- Wiki 默认：这些元素不受光标行 anti_conceal 影响
      ignore = {
        code_background = true,
        indent = true,
        sign = true,
        virtual_lines = true,
      },
    },

    padding = {
      highlight = 'Normal',
    },

    -- 插件默认：`concealcursor.rendered = ''`，渲染窗口下 Normal 也会 conceal `#` 等（美化视图）。
    -- 先前设为 `nvic` 会在 n/v/i/c 模式整窗取消 conceal，导致 Normal 下仍看到 `#`；若不希望显示原文，保持空字符串即可。
    win_options = {
      conceallevel = { default = vim.o.conceallevel, rendered = 3 },
      concealcursor = { default = vim.o.concealcursor, rendered = '' },
    },

    overrides = {
      buflisted = {},
      buftype = {
        nofile = {
          render_modes = true,
          padding = { highlight = 'NormalFloat' },
          sign = { enabled = false },
        },
      },
      filetype = {},
      preview = {
        render_modes = true,
      },
    },

    document = {
      enabled = true,
      render_modes = false,
      conceal = {
        char_patterns = {},
        line_patterns = {},
      },
    },

    paragraph = {
      enabled = true,
      render_modes = false,
      left_margin = 0,
      indent = 0,
      min_width = 0,
    },

    heading = {
      width = 'block',
      border = false,
      backgrounds = {
        'Normal',
        'Normal',
        'Normal',
        'Normal',
        'Normal',
        'Normal',
      },
      -- 与 RenderMarkdownH1–H6 及 @markup.heading.* 对齐，Normal 下标题为各主题常为蓝色的 heading 色
      foregrounds = {
        'RenderMarkdownH1',
        'RenderMarkdownH2',
        'RenderMarkdownH3',
        'RenderMarkdownH4',
        'RenderMarkdownH5',
        'RenderMarkdownH6',
      },
    },

    code = {
      style = 'normal',
      language_icon = false,
      border = 'none',
      -- 结构上与 plugin 默认一致，仅关闭 sign（preset.lazy 已关）
      sign = false,
    },

    bullet = {
      enabled = true,
      render_modes = false,
      highlight = 'Normal',
      scope_highlight = {},
    },

    dash = {
      enabled = true,
      render_modes = false,
      highlight = 'Comment',
    },

    quote = {
      enabled = true,
      render_modes = false,
      highlight = {
        'Comment',
        'Comment',
        'Comment',
        'Comment',
        'Comment',
        'Comment',
      },
    },

    pipe_table = {
      enabled = true,
      render_modes = false,
      preset = 'none',
      cell = 'padded',
      border_enabled = true,
      style = 'full',
    },

    -- preset.lazy 默认 false；按文档「渲染任务列表」打开
    checkbox = {
      enabled = true,
      render_modes = false,
      bullet = false,
      left_pad = 0,
      right_pad = 1,
      unchecked = {
        icon = '󰄱 ',
        highlight = 'RenderMarkdownUnchecked',
        scope_highlight = nil,
      },
      checked = {
        icon = '󰱒 ',
        highlight = 'RenderMarkdownChecked',
        scope_highlight = nil,
      },
    },

    -- link、callout 等沿用插件内置默认；配色由文件顶部 RenderMarkdown* → 内置组的映射统一负责

    inline_highlight = {
      enabled = true,
      render_modes = false,
      highlight = 'RenderMarkdownInlineHighlight',
    },

    latex = {
      enabled = true,
      render_modes = false,
      converter = { 'utftex', 'latex2text' },
      highlight = 'RenderMarkdownMath',
      position = 'center',
      top_pad = 0,
      bottom_pad = 0,
    },

    html = {
      enabled = true,
      render_modes = false,
      comment = {
        conceal = true,
        text = nil,
        highlight = 'RenderMarkdownHtmlComment',
      },
      tag = {},
    },

    yaml = {
      enabled = true,
      render_modes = false,
    },

    sign = {
      enabled = true,
      highlight = 'RenderMarkdownSign',
    },

    indent = {
      enabled = false,
      render_modes = false,
      per_level = 2,
      skip_level = 1,
      skip_heading = false,
      icon = '▎',
      priority = 0,
      highlight = 'RenderMarkdownIndent',
    },

    completions = {
      blink = { enabled = true },
    },
  },
}
