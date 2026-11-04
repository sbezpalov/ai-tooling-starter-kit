# https://editorconfig.org — matches .gitattributes: UTF-8, LF, final newline.
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

[*.{yml,yaml,json,toml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[{Makefile,*.mk}]
indent_style = tab

[*.{bat,cmd}]
end_of_line = crlf

# Initialized by init-repo-bootstrap __VERSION__ (__DATE__).
