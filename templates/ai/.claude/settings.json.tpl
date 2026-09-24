{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "//": "Team Claude Code settings for __NAME_JSON__. Personal overrides — settings.local.json (do not commit). Deny rules are guardrails, not a sandbox: see .claude/README.md.",
  "permissions": {
    "allow": ["Read", "Edit"],
    "deny": [
      "Read(.env)",
      "Read(.env.*)",
      "Read(**.pem)",
      "Read(**.key)",
      "Read(**/.ssh/**)",
      "Read(**/.aws/**)",
      "Read(**/.kube/**)",
      "Bash(rm -rf:*)",
      "Bash(rm -fr:*)",
      "Bash(git push --force:*)",
      "Bash(git push -f:*)"
    ]
  }
}
