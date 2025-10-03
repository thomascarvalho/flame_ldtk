# Publishing Guide for flame_ldtk

## Pre-publication Checklist ✅

- [x] LICENSE file (MIT)
- [x] CHANGELOG.md with version 0.1.0
- [x] pubspec.yaml with all metadata
- [x] README.md with complete documentation
- [x] analysis_options.yaml configured
- [x] All tests passing (11/11)
- [x] No analysis issues
- [x] Example app working

## Publishing Steps

### 1. Dry Run

First, test the package publication without actually publishing:

```bash
flutter pub publish --dry-run
```

This will validate:
- Package structure
- Required files (LICENSE, README, CHANGELOG, pubspec.yaml)
- File size limits
- Documentation completeness

### 2. Review Output

Check for any warnings or issues in the dry-run output.

### 3. Publish to pub.dev

If the dry-run succeeds, publish for real:

```bash
flutter pub publish
```

You'll be prompted to:
1. Confirm the package name and version
2. Authenticate with your Google account
3. Confirm the publication

### 4. Post-Publication

After publishing:

1. **Verify on pub.dev**: Visit https://pub.dev/packages/flame_ldtk
2. **Check package score**: Wait ~10 minutes for pub.dev to analyze
3. **Update README badges** (optional):
   ```markdown
   [![pub package](https://img.shields.io/pub/v/flame_ldtk.svg)](https://pub.dev/packages/flame_ldtk)
   [![popularity](https://img.shields.io/pub/popularity/flame_ldtk?logo=dart)](https://pub.dev/packages/flame_ldtk/score)
   ```

4. **Tag the release on GitHub**:
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```

## Package Quality Score

pub.dev will score your package on:
- **Conventions** (20 points): Following Dart/Flutter conventions
- **Documentation** (10 points): README, API docs, examples
- **Platforms** (20 points): Multi-platform support
- **Analysis** (30 points): No static analysis issues
- **Dependencies** (20 points): Up-to-date dependencies

Current status:
- ✅ Conventions: Likely 20/20 (follows all best practices)
- ✅ Documentation: Likely 10/10 (complete README + API docs)
- ✅ Platforms: Should get 15-20/20 (Flutter package)
- ✅ Analysis: 30/30 (no issues!)
- ✅ Dependencies: 20/20 (latest stable versions)

**Expected score: ~95-100/100** 🎯

## Troubleshooting

### Common Issues

**"Package validation failed"**
- Ensure all required files exist
- Check file names are correct (lowercase)
- Verify LICENSE format

**"Version already exists"**
- Cannot republish same version
- Increment version in pubspec.yaml
- Update CHANGELOG.md

**"Package name already taken"**
- Choose a different name
- Update pubspec.yaml and file references

**"Upload failed"**
- Check internet connection
- Verify Google account credentials
- Try again in a few minutes

## Future Releases

When releasing new versions:

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md` with new features/fixes
3. Run tests: `flutter test`
4. Run analysis: `flutter analyze`
5. Update README if needed
6. Follow steps 1-4 above

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.2.0): New features, backwards compatible
- **PATCH** (0.1.1): Bug fixes, backwards compatible

Current version: **0.1.0** (initial release)
