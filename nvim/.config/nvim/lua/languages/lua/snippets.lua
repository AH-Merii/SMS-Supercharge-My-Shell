local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("lua", {
	s("mod", {
		t("local M = {\n    "),
		i(1, "plugin"),
		t("\n}\n\nfunction M.config()\n    "),
		i(2, "plugin configuration"),
		t("\nend\n\nreturn M"),
	}),
})
