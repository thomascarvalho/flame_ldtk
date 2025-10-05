# Git Hooks

## Installation

Run this command once to enable the hooks:

```bash
git config core.hooksPath .githooks
```

## Available Hooks

### pre-commit

Runs before each commit to ensure code quality:
- **Code formatting**: Checks with `dart format`
- **Static analysis**: Runs `flutter analyze --fatal-infos --fatal-warnings`

If any check fails, the commit is aborted.

### commit-msg

Validates that commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) format.

**Format:** `type(scope?): subject`

**Valid types:**
- `feat` - New feature (minor version bump)
- `fix` - Bug fix (patch version bump)
- `feat!` or `fix!` - Breaking change (major version bump)
- `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build` - No version bump

**Examples:**
```bash
git commit -m "feat: add new feature"
git commit -m "fix: correct bug in parser"
git commit -m "feat(parser): add JSON support"
git commit -m "feat!: breaking API change"
```

## Bypass Hook (not recommended)

If you absolutely need to bypass the hook:

```bash
git commit --no-verify -m "your message"
```

**Warning:** Bypassing the hook may cause Release Please to skip your changes.
