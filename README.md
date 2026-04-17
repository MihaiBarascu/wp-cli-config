# wp-cli-config

Minimal reusable config for LocalWP projects.

Main goal: force safe WP-CLI usage via `./wp.sh`.

## Files
- `wp.sh` - LocalWP socket-aware WP-CLI wrapper
- `AGENTS.md` - agent rules (WP-CLI-first)
- `install.sh` - copies config files into a target project
- `tools/media-import.sh` - optional helper: import image and set featured image

## Usage
```bash
./install.sh "/path/to/project" "Project Name"
```

## Validate in target project
```bash
./wp.sh option get home
./wp.sh core is-installed
./wp.sh plugin list --status=active --field=name
```

## Optional tool: media import
Run in target project root:
```bash
./tools/media-import.sh "/path/to/image.jpg" 542 "Product cover image"
```
Arguments:
- `image_path` (required)
- `post_id` (required)
- `title` (optional)

## Publish to GitHub
```bash
git init
git add .
git commit -m "init wp-cli-config"
git branch -M main
git remote add origin git@github.com:USERNAME/wp-cli-config.git
git push -u origin main
```
