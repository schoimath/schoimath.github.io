# Hugo homepage for GitHub Pages

This repository contains a Hugo-based academic homepage migrated from the original static `index.html`.

## Structure

- `content/_index.md`: homepage content entry
- `layouts/index.html`: custom homepage layout
- `layouts/partials/legacy-home-content.html`: imported body content from the original page
- `static/`: legacy assets, photos, PDFs, and CSS
- `.github/workflows/hugo.yml`: GitHub Pages deployment workflow

## Deploy on GitHub Pages

1. Push this repository to GitHub.
2. In the repository settings, enable GitHub Pages and set the source to GitHub Actions.
3. Keep the default branch as `main` or update the workflow if you use a different branch.

## Local preview

Install Hugo Extended, then run:

```bash
hugo server
```
