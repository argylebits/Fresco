# ArgyleBits Toolchain

Internal tools that should be dogfooded across all projects. When scaffolding a new project, consider which of these apply and integrate them from the start.

---

## Always use

| Tool | Description | Repo |
|---|---|---|
| **Kolache** | Project scaffolding. Generates Swift projects with composable templates (package, CLI, app, Hummingbird). The engine that merges base + platform templates into new projects. | [argylebits/Kolache](https://github.com/argylebits/Kolache) |
| **Fresco** | Daily AI-generated images. Generates a fresh image every day via Gemini and publishes to Cloudflare R2. Drop the stable URL into any README or site. | [argylebits/Fresco](https://github.com/argylebits/Fresco) |
| **RockyCLI** | Local CLI time tracker. Track time across projects with reports and dashboards. Planned: agent-driven timesheet tracking via a Claude Code skill. | [argylebits/RockyCLI](https://github.com/argylebits/RockyCLI) |

## Use when applicable

| Tool | Description | When to use | Repo |
|---|---|---|---|
| **swift-version-plugin** | SPM build plugin. Auto-generates version strings from git tags via `git describe`. | Any Swift project that has versioned releases (CLIs, apps, servers). | [argylebits/swift-version-plugin](https://github.com/argylebits/swift-version-plugin) |
| **RoadrunnerCLI** | Ephemeral Linux CI runners on macOS via Apple Containerization. No Docker required. | Private repos that need self-hosted Linux CI runners. | [argylebits/RoadrunnerCLI](https://github.com/argylebits/RoadrunnerCLI) |
| **Lederhosen** | Static site generator. Declare site structure in YAML, scaffold, build, and serve. | Projects that need a docs site or landing page. | argylebits/Lederhosen (private) |
