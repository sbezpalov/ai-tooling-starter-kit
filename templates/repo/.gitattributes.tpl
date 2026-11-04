# Normalize line endings in the repository: LF everywhere (see .editorconfig).
* text=auto eol=lf

# Windows batch files need CRLF to run.
*.bat text eol=crlf
*.cmd text eol=crlf

# Binary files: no line-ending conversion, no textual diff.
*.png binary
*.jpg binary
*.jpeg binary
*.gif binary
*.ico binary
*.pdf binary
*.zip binary
*.gz binary

# Initialized by init-repo-bootstrap __VERSION__ (__DATE__).
