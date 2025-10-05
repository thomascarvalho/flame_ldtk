# Release Guide

This project uses automated releases with **Release Please** and **GitHub Actions**.

## Initial Setup

### 1. Enable Git Hooks

Install the commit message validation hook:

```bash
git config core.hooksPath .githooks
```

This ensures all commits follow Conventional Commits format.

### 2. Configure pub.dev

Enable automated publishing with OIDC:

1. Sign in to [pub.dev](https://pub.dev)
2. Go to your profile → "Publishing" → "Automated publishing"
3. Click "Enable publishing via GitHub Actions"
4. Authorize your GitHub repository `thomascarvalho/flame_ldtk`

No secrets needed - OIDC handles authentication securely.

### 3. Configure Branch Protection

To ensure releases only happen when all checks pass:

1. Go to: `https://github.com/thomascarvalho/flame_ldtk/settings/branches`
2. Add rule for `main` branch:
   - ✅ **Require status checks to pass before merging**
   - Select: `Analyze & Lint` and `Test`
   - ✅ **Require branches to be up to date**

This prevents merging the Release PR (and creating tags) if CI fails.

### 4. (Optional) Configure Codecov

For code coverage tracking:

1. Go to [codecov.io](https://codecov.io)
2. Connect your repository
3. Add the token: GitHub Settings → Secrets → `CODECOV_TOKEN`

## How to Release

### 1. Write Conventional Commits

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```bash
# Patch release (0.2.0 → 0.2.1)
git commit -m "fix: correct level parsing bug"

# Minor release (0.2.0 → 0.3.0)
git commit -m "feat: add new JSON export support"

# Major release (0.2.0 → 1.0.0)
git commit -m "feat!: redesign API"
# or
git commit -m "feat: redesign API

BREAKING CHANGE: API has been completely redesigned"
```

**Commit types:**
- `feat:` - New feature → **minor** bump (0.x.0)
- `fix:` - Bug fix → **patch** bump (0.0.x)
- `feat!:` or `BREAKING CHANGE:` → **major** bump (x.0.0)
- `docs:`, `chore:`, `style:`, `refactor:`, `test:`, `perf:` → no version bump

### 2. Push to Main

```bash
git push origin main
```

### 3. Review Release PR

**Release Please** automatically creates a PR with:
- Updated `CHANGELOG.md`
- Bumped version in `pubspec.yaml`
- Updated `.release-please-manifest.json`
- Generated release notes

**Check the PR carefully** - this is your chance to review what will be released.

### 4. Merge the Release PR

When you merge:
1. A git tag (`vX.Y.Z`) is created automatically
2. The **CI workflow** runs (tests, lint, analysis)
3. The **Publish workflow** runs:
   - Publishes to pub.dev
   - Creates a GitHub Release with notes

## Workflows

### CI (every push/PR)
- Format verification (`dart format`)
- Static analysis (`flutter analyze`)
- Tests with coverage
- Publish dry-run

### Release Please (on push to main)
- Analyzes commits since last release
- Creates/updates release PR with version bump and CHANGELOG

### Publish (on tag v*)
- Runs all CI checks
- Publishes to pub.dev via OIDC
- Creates GitHub Release

## Examples

### Example 1: Bug fix release

```bash
git commit -m "fix: resolve intgrid parsing error"
git push origin main
# → Release Please creates PR: 0.2.0 → 0.2.1
# → Merge PR → Published automatically
```

### Example 2: New feature

```bash
git commit -m "feat: add tileset layer support"
git push origin main
# → Release Please creates PR: 0.2.0 → 0.3.0
```

### Example 3: Breaking change

```bash
git commit -m "feat!: change level component API

BREAKING CHANGE: LdtkLevelComponent now requires a gameRef parameter"
git push origin main
# → Release Please creates PR: 0.2.0 → 1.0.0
```

### Example 4: Multiple commits

```bash
git commit -m "feat: add entity pooling"
git commit -m "fix: memory leak in parser"
git commit -m "docs: update README examples"
git push origin main
# → Release Please creates PR: 0.2.0 → 0.3.0
# (combines all changes in one release)
```

## Troubleshooting

### Release Please PR not created

- Check your commits follow conventional format
- Ensure you pushed to `main` branch
- Commits like `docs:`, `chore:` don't trigger version bumps

### Publish workflow failed

1. **Tests failing**: Fix the tests and push to the release PR branch
2. **pub.dev authentication**: Verify OIDC is enabled on pub.dev
3. **Version conflict**: Package version may already exist on pub.dev

### Need to cancel a release

**Before merging the Release PR:**
- Just close the PR. Release Please will update it on next push.

**After merging (tag created):**
```bash
# Delete the tag
git tag -d vX.Y.Z
git push --delete origin vX.Y.Z
```

**Note**: Cannot unpublish from pub.dev, only mark as "discontinued".

## Manual Version Bump (emergency only)

If Release Please is unavailable:

```bash
# 1. Update version in pubspec.yaml
# 2. Update .release-please-manifest.json to match
# 3. Update CHANGELOG.md
# 4. Commit all changes
git add pubspec.yaml .release-please-manifest.json CHANGELOG.md
git commit -m "chore: release vX.Y.Z"
git tag vX.Y.Z
git push origin main --tags
```

This bypasses Release Please and publishes directly.
