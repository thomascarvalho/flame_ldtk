# Branch Protection Configuration

To ensure releases only happen when all checks pass, configure branch protection rules on GitHub.

## Setup Instructions

1. Go to: `https://github.com/thomascarvalho/flame_ldtk/settings/branches`
2. Click "Add rule" or edit the `main` branch rule
3. Configure the following:

### Required Settings

✅ **Require a pull request before merging**
- Required approvals: 0 (for solo projects) or 1+ (for teams)

✅ **Require status checks to pass before merging**
- Require branches to be up to date before merging: ✅
- Status checks that are required:
  - `Analyze & Lint`
  - `Test`

✅ **Do not allow bypassing the above settings**
- Include administrators: ✅ (recommended)

### Optional but Recommended

- Require conversation resolution before merging
- Require linear history

## How It Works

1. You push commits to `main`
2. **Release Please** creates a PR with version bump
3. **CI workflow** runs automatically on the PR:
   - ✅ Format check
   - ✅ Analyze & lint
   - ✅ Tests
   - ✅ pub.dev dry-run
4. **You cannot merge** until all checks pass ⚠️
5. Once merged → tag created → published to pub.dev

## Benefits

- ❌ Cannot publish broken code
- ✅ Maximum score on pub.dev
- ✅ All lints, tests, and analysis must pass
- ✅ Safe automated releases

## For Solo Projects

If you're the only maintainer and trust your workflow:
- Set required approvals to 0
- But keep status checks required

This allows you to merge Release Please PRs without waiting for another person, but still requires all tests to pass.
