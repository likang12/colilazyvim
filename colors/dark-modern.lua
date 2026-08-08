-- dark-modern：参考 VS Code「Dark Modern」主题的自定义配色方案
-- 色值来源：/usr/share/code/.../theme-defaults/themes/dark_modern.json
--           + include 链 dark_plus.json → dark_vs.json（语法 token 颜色）
-- 用法：:colorscheme dark-modern

vim.api.nvim_command("hi clear")
vim.api.nvim_command("syntax reset")
vim.g.colors_name = "dark-modern"
vim.opt.background = "dark"

-- ====================================================================
-- 调色板
-- ====================================================================
local c = {
  -- UI
  bg = "#1F1F1F", -- 编辑器背景 editor.background
  bg_dark = "#181818", -- 侧栏/状态栏/标签栏背景
  bg_float = "#202020", -- 浮动窗口/组件背景
  bg_input = "#313131", -- 输入框/下拉背景
  bg_quick = "#222222", -- 快速输入面板背景
  bg_hover = "#2B2B2B", -- 悬停/区块背景
  bg_line = "#262626", -- 当前行/列高亮
  border = "#2B2B2B", -- 常规边框
  border_strong = "#3C3C3C", -- 浮动窗边框（需可见）
  sel = "#264F78", -- 编辑器选区
  sel_list = "#04395E", -- 列表/菜单选中项
  fg = "#CCCCCC", -- 前景 editor.foreground
  fg_bright = "#FFFFFF", -- 高亮前景（激活标签）
  fg_muted = "#9D9D9D", -- 次要文本 descriptionForeground
  fg_faint = "#6E7681", -- 行号/弱化文本
  accent = "#0078D4", -- 强调蓝 focusBorder / button.background
  accent_hover = "#026EC1", -- 强调色悬停
  cursor = "#AEAFAD", -- 光标色

  -- 语法
  comment = "#6A9955",
  string = "#CE9178",
  number = "#B5CEA8",
  keyword = "#569CD6",
  keyword_control = "#C586C0",
  operator = "#D4D4D4",
  func = "#DCDCAA",
  type = "#4EC9B0",
  variable = "#9CDCFE",
  constant = "#4FC1FF",
  escape = "#D7BA7D",
  regexp = "#D16969",
  invalid = "#F44747",
  label = "#C8C8C8",
  tag_bracket = "#808080",
  link = "#4daafc",

  -- 状态
  error = "#F85149",
  warning = "#CCA700",
  info = "#3794FF",
  success = "#2EA043",
  git_add = "#2EA043",
  git_del = "#F85149",
  git_mod = "#0078D4",
}

-- 诊断虚拟文本的微调背景
local vt_bg = {
  error = "#2D2323",
  warn = "#2D2A20",
  info = "#1F2A33",
  hint = "#1F2A33",
  ok = "#1F2B24",
}

-- 设置高亮组（group = { fg/bg/style } 或 { link = "目标" }）
local function H(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- 诊断虚拟文本：fg + 微调 bg
for _, kind in ipairs({ "Error", "Warn", "Info", "Hint", "Ok" }) do
  local key = kind:lower()
  local fg = (kind == "Error" and c.error) or (kind == "Warn" and c.warning) or (kind == "Ok" and c.success) or c.info
  H("DiagnosticVirtualText" .. kind, { fg = fg, bg = vt_bg[key] })
  H("DiagnosticUnderline" .. kind, { sp = fg, undercurl = true })
end

-- ====================================================================
-- 1. 基础 UI
-- ====================================================================
H("Normal", { fg = c.fg, bg = c.bg })
H("NormalFloat", { fg = c.fg, bg = c.bg_float })
H("NormalNC", { fg = c.fg, bg = c.bg })
H("NormalSB", { fg = c.fg, bg = c.bg_dark })
H("Cursor", { bg = c.cursor })
H("CursorLine", { bg = c.bg_line })
H("CursorLineNr", { fg = c.fg })
H("CursorColumn", { bg = c.bg_line })
H("ColorColumn", { bg = c.bg_line })
H("LineNr", { fg = c.fg_faint })
H("LineNrAbove", { fg = c.fg_faint })
H("LineNrBelow", { fg = c.fg_faint })
H("SignColumn", { fg = c.fg_faint, bg = c.bg })
H("FoldColumn", { fg = c.fg_faint, bg = c.bg })
H("Folded", { fg = c.fg_muted, bg = c.bg_line })
H("Visual", { fg = c.fg_bright, bg = c.sel })
H("VisualNOS", { fg = c.fg_bright, bg = c.sel })
H("MatchParen", { fg = c.fg_bright, bg = c.sel_list })
H("Search", { fg = c.fg_bright, bg = "#9E6A03" })
H("IncSearch", { fg = c.bg, bg = c.escape, bold = true })
H("CurSearch", { fg = c.bg, bg = c.escape, bold = true })
H("Pmenu", { fg = c.fg, bg = c.bg_input })
H("PmenuSel", { fg = c.fg_bright, bg = c.sel_list, bold = true })
H("PmenuSbar", { bg = c.bg_input })
H("PmenuThumb", { bg = "#616161" })
H("WildMenu", { fg = c.fg_bright, bg = c.sel_list })
H("Title", { fg = c.fg_bright, bold = true })
H("MoreMsg", { fg = c.success })
H("ModeMsg", { fg = c.fg })
H("Question", { fg = c.info })
H("ErrorMsg", { fg = c.error })
H("WarningMsg", { fg = c.warning })
H("VertSplit", { fg = c.border })
H("WinSeparator", { fg = "#2F2F2F" })
H("StatusLine", { fg = c.fg, bg = c.bg_dark })
H("StatusLineNC", { fg = c.fg_muted, bg = c.bg_dark })
H("TabLineFill", { bg = c.bg_dark })
H("TabLine", { fg = c.fg_muted, bg = c.bg_dark })
H("TabLineSel", { fg = c.fg_bright, bg = c.bg, bold = true })
H("WinBar", { fg = c.fg, bg = c.bg_dark })
H("WinBarNC", { fg = c.fg_muted, bg = c.bg_dark })
H("Directory", { fg = c.type })
H("NonText", { fg = c.fg_faint })
H("EndOfBuffer", { fg = c.bg })
H("Whitespace", { fg = "#2F2F2F" })
H("SpecialKey", { fg = c.fg_faint })
H("Conceal", { fg = c.fg_faint })
H("FloatBorder", { fg = c.border_strong, bg = c.bg_float })
H("FloatTitle", { fg = c.fg, bg = c.bg_float })
H("FloatFooter", { fg = c.fg_muted, bg = c.bg_float })

-- 拼写
H("SpellBad", { sp = c.error, undercurl = true })
H("SpellCap", { sp = c.warning, undercurl = true })
H("SpellRare", { sp = c.constant, undercurl = true })
H("SpellLocal", { sp = c.variable, undercurl = true })

-- 诊断
H("DiagnosticError", { fg = c.error })
H("DiagnosticWarn", { fg = c.warning })
H("DiagnosticInfo", { fg = c.info })
H("DiagnosticHint", { fg = c.info })
H("DiagnosticOk", { fg = c.success })
H("DiagnosticUnnecessary", { fg = c.fg_muted })
H("DiagnosticDeprecated", { fg = c.fg_muted, strikethrough = true })

-- ====================================================================
-- 2. 基础语法组
-- ====================================================================
H("Comment", { fg = c.comment })
H("Constant", { fg = c.constant })
H("String", { fg = c.string })
H("Character", { fg = c.string })
H("Number", { fg = c.number })
H("Boolean", { fg = c.keyword })
H("Float", { fg = c.number })
H("Identifier", { fg = c.variable })
H("Function", { fg = c.func })
H("Statement", { fg = c.keyword_control })
H("Conditional", { fg = c.keyword_control })
H("Repeat", { fg = c.keyword_control })
H("Label", { fg = c.label })
H("Operator", { fg = c.operator })
H("Keyword", { fg = c.keyword })
H("Exception", { fg = c.keyword_control })
H("PreProc", { fg = c.keyword })
H("Include", { fg = c.keyword })
H("Define", { fg = c.keyword })
H("Macro", { fg = c.constant })
H("PreCondit", { fg = c.keyword })
H("Type", { fg = c.type })
H("StorageClass", { fg = c.keyword })
H("Structure", { fg = c.keyword })
H("Typedef", { fg = c.type })
H("Special", { fg = c.operator })
H("SpecialChar", { fg = c.escape })
H("Tag", { fg = c.keyword })
H("Delimiter", { fg = c.operator })
H("SpecialComment", { fg = c.comment, italic = true })
H("Debug", { fg = c.escape })
H("Underlined", { fg = c.link, underline = true })
H("Ignore", { fg = c.fg_faint })
H("Error", { fg = c.error })
H("Todo", { fg = c.bg, bg = "#9E6A03", bold = true })

-- ====================================================================
-- 3. Treesitter @ 组
-- ====================================================================
-- 注释
H("@comment", { fg = c.comment })
H("@comment.todo", { fg = c.fg, bg = "#9E6A03", bold = true })
H("@comment.error", { fg = c.error })
H("@comment.warning", { fg = c.warning })
H("@comment.note", { fg = c.info })

-- 字符串 / 数字
H("@string", { fg = c.string })
H("@string.escape", { fg = c.escape })
H("@string.special", { fg = c.string })
H("@string.regexp", { fg = c.regexp })
H("@string.special.url", { fg = c.link, underline = true })
H("@character", { fg = c.string })
H("@number", { fg = c.number })
H("@float", { fg = c.number })

-- 常量 / 变量
H("@boolean", { fg = c.keyword })
H("@constant", { fg = c.constant })
H("@constant.builtin", { fg = c.keyword })
H("@constant.macro", { fg = c.constant })
H("@variable", { fg = c.variable })
H("@variable.builtin", { fg = c.keyword })
H("@variable.parameter", { fg = c.variable })
H("@variable.member", { fg = c.variable })
H("@property", { fg = c.variable })
H("@field", { fg = c.variable })
H("@parameter", { fg = c.variable })

-- 函数 / 方法 / 类型
H("@function", { fg = c.func })
H("@function.builtin", { fg = c.func })
H("@function.call", { fg = c.func })
H("@function.macro", { fg = c.func })
H("@method", { fg = c.func })
H("@method.call", { fg = c.func })
H("@constructor", { fg = c.type })
H("@type", { fg = c.type })
H("@type.builtin", { fg = c.type })
H("@type.qualifier", { fg = c.keyword })
H("@type.definition", { fg = c.type })
H("@namespace", { fg = c.type })

-- 关键字 / 运算符
H("@keyword", { fg = c.keyword })
H("@keyword.control", { fg = c.keyword_control })
H("@keyword.conditional", { fg = c.keyword_control })
H("@keyword.repeat", { fg = c.keyword_control })
H("@keyword.return", { fg = c.keyword_control })
H("@keyword.exception", { fg = c.keyword_control })
H("@keyword.function", { fg = c.keyword })
H("@keyword.import", { fg = c.keyword })
H("@keyword.storage", { fg = c.keyword })
H("@keyword.operator", { fg = c.operator })
H("@storageclass", { fg = c.keyword })
H("@structure", { fg = c.keyword })
H("@operator", { fg = c.operator })
H("@exception", { fg = c.keyword_control })
H("@include", { fg = c.keyword })
H("@attribute", { fg = c.type })

-- 标点
H("@punctuation.delimiter", { fg = c.operator })
H("@punctuation.bracket", { fg = c.operator })
H("@punctuation.special", { fg = c.operator })

-- 标签 / 其他
H("@tag", { fg = c.keyword })
H("@tag.attribute", { fg = c.variable })
H("@tag.delimiter", { fg = c.tag_bracket })
H("@label", { fg = c.label })
H("@preproc", { fg = c.keyword })
H("@macro", { fg = c.constant })

-- markdown / markup
H("@markup.heading", { fg = c.keyword, bold = true })
H("@markup.strong", { fg = c.fg, bold = true })
H("@markup.italic", { fg = c.fg, italic = true })
H("@markup.link", { fg = c.link, underline = true })
H("@markup.link.label", { fg = c.link })
H("@markup.raw", { fg = c.string })
H("@markup.code", { fg = c.string })
H("@markup.inline", { fg = c.string })
H("@markup.quote", { fg = c.comment })
H("@markup.list", { fg = c.fg })
H("@markup.list.checked", { fg = c.success })
H("@markup.list.unchecked", { fg = c.fg_muted })
H("@markup.strikethrough", { strikethrough = true })
H("@markup.underline", { underline = true })
H("@markup.math", { fg = c.constant, italic = true })

-- 文本 / 其他
H("@text", { fg = c.fg })
H("@text.reference", { fg = c.variable })
H("@text.title", { fg = c.keyword, bold = true })
H("@text.uri", { fg = c.link, underline = true })
H("@text.todo", { fg = c.fg, bg = "#9E6A03", bold = true })
H("@text.diff.add", { fg = c.number })
H("@text.diff.delete", { fg = c.string })
H("@diff.plus", { fg = c.number })
H("@diff.minus", { fg = c.string })
H("@diff.delta", { fg = c.keyword })

-- ====================================================================
-- 4. LSP 语义 token + 引用
-- ====================================================================
H("@lsp.type.namespace", { link = "@namespace" })
H("@lsp.type.class", { link = "@type" })
H("@lsp.type.struct", { link = "@type" })
H("@lsp.type.enum", { link = "@type" })
H("@lsp.type.interface", { link = "@type" })
H("@lsp.type.typeParameter", { link = "@type" })
H("@lsp.type.type", { link = "@type" })
H("@lsp.type.builtinType", { link = "@type.builtin" })
H("@lsp.type.parameter", { link = "@variable.parameter" })
H("@lsp.type.variable", { link = "@variable" })
H("@lsp.type.property", { link = "@property" })
H("@lsp.type.function", { link = "@function" })
H("@lsp.type.method", { link = "@method" })
H("@lsp.type.keyword", { link = "@keyword" })
H("@lsp.type.number", { link = "@number" })
H("@lsp.type.string", { link = "@string" })
H("@lsp.type.boolean", { link = "@boolean" })
H("@lsp.type.enumMember", { link = "@constant" })
H("@lsp.type.macro", { link = "@constant.macro" })
H("@lsp.type.decorator", { link = "@attribute" })
H("@lsp.typemod.variable.constant", { link = "@constant" })
H("@lsp.typemod.variable.defaultLibrary", { link = "@variable.builtin" })
H("@lsp.typemod.variable.static", { link = "@constant" })
H("@lsp.typemod.class.defaultLibrary", { link = "@type.builtin" })
H("@lsp.typemod.function.defaultLibrary", { link = "@function.builtin" })
H("@lsp.typemod.function.readonly", { link = "@function" })
H("@lsp.typemod.keyword.control", { link = "@keyword.control" })
H("@lsp.typemod.type.defaultLibrary", { link = "@type.builtin" })

H("LspInlayHint", { fg = c.fg_muted, bg = c.bg_line, italic = true })
H("LspCodeLens", { fg = c.fg_faint })
H("LspSignatureActiveParameter", { fg = c.func, bold = true, underline = true })
H("LspReferenceText", { bg = c.bg_line })
H("LspReferenceRead", { bg = c.bg_line })
H("LspReferenceWrite", { bg = c.bg_line })

-- ====================================================================
-- 5. 插件组
-- ====================================================================

-- 5.1 blink.cmp 补全菜单
H("BlinkCmpMenu", { fg = c.fg, bg = c.bg_quick })
H("BlinkCmpMenuBorder", { fg = c.border_strong })
H("BlinkCmpMenuSelection", { fg = c.fg_bright, bg = c.sel_list, bold = true })
H("BlinkCmpLabel", { fg = c.fg })
H("BlinkCmpLabelMatch", { fg = c.fg_bright, bold = true })
H("BlinkCmpLabelDetail", { fg = c.fg_muted })
H("BlinkCmpLabelDescription", { fg = c.fg_muted })
H("BlinkCmpLabelDeprecated", { fg = "#616161", strikethrough = true })
H("BlinkCmpDoc", { fg = c.fg, bg = c.bg_float })
H("BlinkCmpDocBorder", { fg = c.border_strong })
H("BlinkCmpDocSeparator", { fg = c.border_strong })
H("BlinkCmpSignatureHelp", { fg = c.fg, bg = c.bg_float })
H("BlinkCmpSignatureHelpActiveParameter", { fg = c.func, bold = true, underline = true })
H("BlinkCmpGhostText", { fg = c.fg_faint })
H("BlinkCmpScrollBarThumb", { bg = "#616161" })
-- 补全项类型图标颜色
H("BlinkCmpKindKeyword", { fg = c.keyword })
H("BlinkCmpKindFunction", { fg = c.func })
H("BlinkCmpKindMethod", { fg = c.func })
H("BlinkCmpKindStaticMethod", { fg = c.func })
H("BlinkCmpKindType", { fg = c.type })
H("BlinkCmpKindClass", { fg = c.type })
H("BlinkCmpKindInterface", { fg = c.type })
H("BlinkCmpKindStruct", { fg = c.type })
H("BlinkCmpKindEnum", { fg = c.type })
H("BlinkCmpKindEnumMember", { fg = c.constant })
H("BlinkCmpKindTypeParameter", { fg = c.type })
H("BlinkCmpKindVariable", { fg = c.variable })
H("BlinkCmpKindField", { fg = c.variable })
H("BlinkCmpKindProperty", { fg = c.variable })
H("BlinkCmpKindModule", { fg = c.type })
H("BlinkCmpKindNamespace", { fg = c.type })
H("BlinkCmpKindPackage", { fg = c.type })
H("BlinkCmpKindConstant", { fg = c.constant })
H("BlinkCmpKindConstructor", { fg = c.type })
H("BlinkCmpKindText", { fg = c.fg })
H("BlinkCmpKindValue", { fg = c.constant })
H("BlinkCmpKindSnippet", { fg = c.string })
H("BlinkCmpKindString", { fg = c.string })
H("BlinkCmpKindNumber", { fg = c.number })
H("BlinkCmpKindBoolean", { fg = c.keyword })
H("BlinkCmpKindUnit", { fg = c.number })
H("BlinkCmpKindColor", { fg = c.string })
H("BlinkCmpKindFile", { fg = c.variable })
H("BlinkCmpKindFolder", { fg = c.variable })
H("BlinkCmpKindEvent", { fg = c.warning })
H("BlinkCmpKindOperator", { fg = c.operator })
H("BlinkCmpKindReference", { fg = c.constant })
H("BlinkCmpKindKey", { fg = c.func })
H("BlinkCmpKindArray", { fg = c.warning })
H("BlinkCmpKindObject", { fg = c.warning })
H("BlinkCmpKindNull", { fg = c.keyword })
H("BlinkCmpKindMacro", { fg = c.constant })
H("BlinkCmpKindSnip", { fg = c.string })

-- 5.2 neo-tree 侧栏文件树
H("NeoTreeNormal", { fg = c.fg, bg = c.bg_dark })
H("NeoTreeNormalNC", { fg = c.fg_muted, bg = c.bg_dark })
H("NeoTreeCursorLine", { fg = c.fg_bright, bg = c.sel_list })
H("NeoTreeDirectoryIcon", { fg = c.variable })
H("NeoTreeDirectoryName", { fg = c.variable })
H("NeoTreeFileIcon", { fg = c.fg_muted })
H("NeoTreeFileName", { fg = c.fg })
H("NeoTreeFileNameOpened", { fg = c.fg_bright })
H("NeoTreeRootName", { fg = c.func, bold = true })
H("NeoTreeDimText", { fg = c.fg_faint })
H("NeoTreeDotfile", { fg = c.fg_faint })
H("NeoTreeHiddenByName", { fg = c.fg_faint })
H("NeoTreeIndentMarker", { fg = "#2F2F2F" })
H("NeoTreeWinSeparator", { fg = "#2F2F2F", bg = c.bg_dark })
H("NeoTreeSignColumn", { bg = c.bg_dark })
H("NeoTreeGitAdded", { fg = c.git_add })
H("NeoTreeGitDeleted", { fg = c.git_del })
H("NeoTreeGitModified", { fg = c.git_mod })
H("NeoTreeGitStaged", { fg = c.git_add })
H("NeoTreeGitUnstaged", { fg = c.warning })
H("NeoTreeGitConflict", { fg = c.warning })
H("NeoTreeGitRenamed", { fg = c.info })
H("NeoTreeGitUntracked", { fg = c.fg_muted })
H("NeoTreeGitIgnored", { fg = c.fg_faint })
H("NeoTreeFloatBorder", { fg = c.border_strong, bg = c.bg_float })
H("NeoTreeFloatTitle", { fg = c.fg, bg = c.bg_float })
H("NeoTreeTitleBar", { fg = c.fg, bg = c.bg_float })
H("NeoTreeFileStats", { fg = c.fg_muted })
H("NeoTreeFileStatsHeader", { fg = c.fg_faint, bold = true })
H("NeoTreeSymbolicLinkTarget", { fg = c.info, bold = true })
H("NeoTreeModified", { fg = c.git_mod })

-- 5.3 bufferline 标签栏
H("BufferLineFill", { bg = c.bg_dark })
H("BufferLineBackground", { fg = c.fg_muted, bg = c.bg_dark })
H("BufferLineBuffer", { fg = c.fg_muted, bg = c.bg_dark })
H("BufferLineBufferVisible", { fg = c.fg_muted, bg = c.bg })
H("BufferLineBufferSelected", { fg = c.fg_bright, bg = c.bg })
H("BufferLineSeparator", { fg = c.border, bg = c.bg_dark })
H("BufferLineSeparatorSelected", { fg = c.border, bg = c.bg })
H("BufferLineIndicatorSelected", { fg = c.accent })
H("BufferLineModified", { fg = c.git_mod })
H("BufferLineModifiedVisible", { fg = c.git_mod })
H("BufferLineModifiedSelected", { fg = c.git_mod })
H("BufferLineError", { fg = c.error })
H("BufferLineErrorVisible", { fg = c.error })
H("BufferLineErrorSelected", { fg = c.error })
H("BufferLineWarning", { fg = c.warning })
H("BufferLineWarningVisible", { fg = c.warning })
H("BufferLineWarningSelected", { fg = c.warning })
H("BufferLineInfo", { fg = c.info })
H("BufferLineInfoVisible", { fg = c.info })
H("BufferLineInfoSelected", { fg = c.info })
H("BufferLineHint", { fg = c.info })
H("BufferLineHintVisible", { fg = c.info })
H("BufferLineHintSelected", { fg = c.info })
H("BufferLineDuplicate", { fg = c.fg_faint })
H("BufferLineDuplicateVisible", { fg = c.fg_faint })
H("BufferLineDuplicateSelected", { fg = c.fg_muted })
H("BufferLineTab", { fg = c.fg_muted, bg = c.bg_dark })
H("BufferLineTabSelected", { fg = c.fg_bright, bg = c.bg })
H("BufferLineTabClose", { fg = c.error })
H("BufferLineCloseButton", { fg = c.fg_faint })
H("BufferLineCloseButtonVisible", { fg = c.fg_faint })
H("BufferLineCloseButtonSelected", { fg = c.fg_muted })
H("BufferLineDiagnostic", { fg = c.info })
H("BufferLineDiagnosticVisible", { fg = c.info })
H("BufferLineDiagnosticSelected", { fg = c.info })
H("BufferLineGroupNormal", { fg = c.accent, bg = c.bg_dark })
H("BufferLineOffsetSeparator", { fg = c.border, bg = c.bg_dark })
H("BufferLineNumbers", { fg = c.fg_faint })
H("BufferLineNumbersVisible", { fg = c.fg_faint })
H("BufferLineNumbersSelected", { fg = c.fg })

-- 5.4 noice 通知/命令行
H("NoiceCmdline", { fg = c.fg, bg = c.bg_float })
H("NoiceCmdlinePopup", { fg = c.fg, bg = c.bg_float })
H("NoiceCmdlinePopupBorder", { fg = c.border_strong })
H("NoiceCmdlinePopupTitle", { fg = c.accent })
H("NoiceCmdlinePrompt", { fg = c.variable, bold = true })
H("NoiceCmdlineIcon", { fg = c.accent })
H("NoicePopup", { fg = c.fg, bg = c.bg_float })
H("NoicePopupBorder", { fg = c.border_strong })
H("NoicePopupmenu", { fg = c.fg, bg = c.bg_quick })
H("NoicePopupmenuBorder", { fg = c.border_strong })
H("NoicePopupmenuSelected", { fg = c.fg_bright, bg = c.sel_list })
H("NoicePopupmenuMatch", { fg = c.func, bold = true })
H("NoicePopupmenuItemKind", { fg = c.variable })
H("NoiceConfirm", { fg = c.fg, bg = c.bg_float })
H("NoiceConfirmBorder", { fg = c.border_strong })
H("NoiceFormatTitle", { fg = c.fg, bold = true })
H("NoiceFormatConfirm", { fg = c.success, bold = true })
H("NoiceFormatDate", { fg = c.fg_faint })
H("NoiceFormatLevelError", { fg = c.error })
H("NoiceFormatLevelWarn", { fg = c.warning })
H("NoiceFormatLevelInfo", { fg = c.info })
H("NoiceFormatLevelDebug", { fg = c.fg_faint })
H("NoiceLspProgressClient", { fg = c.variable })
H("NoiceLspProgressTitle", { fg = c.fg_bright })
H("NoiceMini", { fg = c.fg, bg = c.bg_float })
H("NoiceCompletionItemWord", { fg = c.fg })
H("NoiceCompletionItemKindDefault", { fg = c.variable })
H("NoiceCompletionItemMenu", { fg = c.fg_muted })

-- 5.5 snacks picker 选择器
H("SnacksPickerList", { fg = c.fg, bg = c.bg_quick })
H("SnacksPickerListCursorLine", { fg = c.fg_bright, bg = c.sel_list })
H("SnacksPickerInput", { fg = c.fg, bg = c.bg })
H("SnacksPickerSearch", { fg = c.func })
H("SnacksPickerPrompt", { fg = c.variable })
H("SnacksPickerTitle", { fg = c.accent, bold = true })
H("SnacksPickerHeader", { fg = c.fg_muted })
H("SnacksPickerPreview", { bg = c.bg })
H("SnacksPickerPreviewCursorLine", { bg = c.bg_line })
H("SnacksPickerFile", { fg = c.fg })
H("SnacksPickerDirectory", { fg = c.variable })
H("SnacksPickerDir", { fg = c.variable })
H("SnacksPickerIcon", { fg = c.fg_muted })
H("SnacksPickerLabel", { fg = c.variable })
H("SnacksPickerDesc", { fg = c.fg_muted })
H("SnacksPickerDimmed", { fg = c.fg_faint })
H("SnacksPickerBox", { fg = c.fg_muted })
H("SnacksPickerBold", { bold = true })
H("SnacksPickerItalic", { italic = true })
H("SnacksPickerCode", { fg = c.string })
H("SnacksPickerGitStatusAdded", { fg = c.git_add })
H("SnacksPickerGitStatusModified", { fg = c.git_mod })
H("SnacksPickerGitStatusDeleted", { fg = c.git_del })
H("SnacksPickerGitStatusStaged", { fg = c.git_add })
H("SnacksPickerGitStatusUntracked", { fg = c.fg_faint })
H("SnacksPickerBufNr", { fg = c.fg_faint })
H("SnacksPickerCol", { fg = c.fg_faint })
H("SnacksPickerIdx", { fg = c.fg_faint })
H("SnacksPickerKeymapLhs", { fg = c.func })
H("SnacksPickerKeymapRhs", { fg = c.variable })
H("SnacksPickerCmd", { fg = c.variable })
H("SnacksPickerFileType", { fg = c.type })
H("SnacksPickerComment", { fg = c.comment })
H("SnacksPickerDelim", { fg = c.fg_faint })

-- 5.6 snacks dashboard（LazyVim 启动页）
H("SnacksDashboardHeader", { fg = c.accent, bold = true })
H("SnacksDashboardFooter", { fg = c.fg_faint })
H("SnacksDashboardDesc", { fg = c.variable })
H("SnacksDashboardKey", { fg = c.func, bold = true })
H("SnacksDashboardIcon", { fg = c.accent })

-- 5.7 which-key
H("WhichKey", { fg = c.variable })
H("WhichKeyDesc", { fg = c.fg })
H("WhichKeyGroup", { fg = c.type })
H("WhichKeySeparator", { fg = c.fg_faint })
H("WhichKeyValue", { fg = c.func })
H("WhichKeyBorder", { fg = c.border_strong, bg = c.bg_float })
H("WhichKeyTitle", { fg = c.fg_bright, bold = true })
H("WhichKeyIcon", { fg = c.accent })
H("WhichKeyNormal", { fg = c.fg, bg = c.bg_float })

-- 5.8 flash 跳转
H("FlashLabel", { fg = c.bg, bg = c.escape, bold = true })
H("FlashMatch", { fg = c.fg_bright, bg = "#9E6A03" })
H("FlashCurrent", { fg = c.bg, bg = c.escape, bold = true })
H("FlashBackdrop", { fg = c.fg_faint })

-- 5.9 gitsigns 行号栏
H("GitSignsAdd", { fg = c.git_add })
H("GitSignsChange", { fg = c.git_mod })
H("GitSignsDelete", { fg = c.git_del })
H("GitSignsAddNr", { fg = c.git_add })
H("GitSignsChangeNr", { fg = c.git_mod })
H("GitSignsDeleteNr", { fg = c.git_del })
H("GitSignsAddLn", { fg = c.git_add })
H("GitSignsChangeLn", { fg = c.git_mod })
H("GitSignsDeleteLn", { fg = c.git_del })
H("GitSignsCurrentLineBlame", { fg = c.fg_faint, italic = true })

-- 5.10 render-markdown
for i = 1, 6 do
  H("RenderMarkdownH" .. i, { fg = c.keyword, bold = true })
  H("RenderMarkdownH" .. i .. "Bg", { fg = c.keyword, bold = true })
end
H("RenderMarkdownBullet", { fg = c.variable })
H("RenderMarkdownChecked", { fg = c.success })
H("RenderMarkdownUnchecked", { fg = c.fg_muted })
H("RenderMarkdownTodo", { fg = c.warning })
H("RenderMarkdownCode", { fg = "#D0D0D0", bg = c.bg_hover })
H("RenderMarkdownCodeBorder", { fg = c.border_strong })
H("RenderMarkdownCodeInfo", { fg = c.variable })
H("RenderMarkdownCodeInline", { fg = "#D0D0D0", bg = c.border_strong })
H("RenderMarkdownQuote", { fg = c.comment })
for i = 1, 6 do
  H("RenderMarkdownQuote" .. i, { fg = c.comment })
end
H("RenderMarkdownLink", { fg = c.link, underline = true })
H("RenderMarkdownLinkTitle", { fg = c.link })
H("RenderMarkdownWikiLink", { fg = c.link, underline = true })
H("RenderMarkdownTableHead", { fg = c.func, bold = true })
H("RenderMarkdownTableRow", { fg = c.fg })
H("RenderMarkdownMath", { fg = c.constant, italic = true })
H("RenderMarkdownStrike", { fg = c.fg_faint, strikethrough = true })
H("RenderMarkdownEmphasis", { italic = true })
H("RenderMarkdownStrong", { bold = true })
H("RenderMarkdownSign", { fg = c.info })
H("RenderMarkdownSuccess", { fg = c.success })
H("RenderMarkdownError", { fg = c.error })
H("RenderMarkdownHint", { fg = c.info })
H("RenderMarkdownWarn", { fg = c.warning })
H("RenderMarkdownDash", { fg = c.fg_faint })
H("RenderMarkdownIndent", { fg = "#2F2F2F" })

-- 5.11 markdown 基础组（render-markdown 未激活时兜底）
for i = 1, 6 do
  H("markdownH" .. i, { fg = c.keyword, bold = true })
end
H("markdownHeadingDelimiter", { fg = c.keyword })
H("markdownCodeBlock", { fg = c.string })
H("markdownCode", { fg = c.string })
H("markdownInlineCode", { fg = c.string })
H("markdownLinkText", { fg = c.link })
H("markdownLinkDelimiter", { fg = c.fg_faint })
H("markdownListMarker", { fg = c.variable })
H("markdownBlockquote", { fg = c.comment })
H("markdownBold", { bold = true })
H("markdownItalic", { italic = true })

-- 5.12 lazy / mason 安装界面
H("LazyNormal", { fg = c.fg, bg = c.bg })
H("LazyButton", { fg = c.fg, bg = c.bg_hover })
H("LazyButtonActive", { fg = c.fg_bright, bg = c.accent })
H("LazyTitle", { fg = c.accent, bold = true })
H("LazyDir", { fg = c.type })
H("LazyUrl", { fg = c.link, underline = true })
H("LazyReasonPlugin", { fg = c.keyword })
H("LazyReasonStart", { fg = c.success })
H("LazyReasonImport", { fg = c.variable })
H("LazyReasonKeys", { fg = c.warning })
H("LazyReasonEvent", { fg = c.constant })
H("LazyReasonCmd", { fg = c.type })
H("LazyReasonFt", { fg = c.variable })
H("LazyReasonSource", { fg = c.info })
H("LazyReasonConfig", { fg = c.fg_muted })
H("MasonNormal", { fg = c.fg, bg = c.bg })
H("MasonHeader", { fg = c.fg_bright, bg = c.accent, bold = true })
H("MasonHighlight", { fg = c.variable })
H("MasonHighlightBlock", { fg = c.fg, bg = c.bg_hover })
H("MasonHighlightSecondary", { fg = c.comment })
H("MasonMuted", { fg = c.fg_faint })
H("MasonError", { fg = c.error })
H("MasonLink", { fg = c.link, underline = true })

-- 5.13 telescope 兜底（未启用也定义，避免插件默认色不搭）
H("TelescopeNormal", { fg = c.fg, bg = c.bg_quick })
H("TelescopeBorder", { fg = c.border_strong })
H("TelescopePromptNormal", { fg = c.fg, bg = c.bg })
H("TelescopePromptBorder", { fg = c.border_strong })
H("TelescopeSelection", { fg = c.fg_bright, bg = c.sel_list })
H("TelescopeSelectionCaret", { fg = c.accent })
H("TelescopeMultiSelection", { fg = c.variable })
H("TelescopePreviewNormal", { fg = c.fg, bg = c.bg })
H("TelescopeMatching", { fg = c.func, bold = true })
H("TelescopeTitle", { fg = c.fg, bg = c.sel_list })
