# __PROJECT_NAME__ - WP-CLI Rules

## Priority #1
Always use `./wp.sh` for WordPress CLI commands.
Never run plain `wp` directly.

## Quick checks
```bash
./wp.sh option get home
./wp.sh core is-installed
./wp.sh plugin list --status=active --field=name
```

## Safe workflow
1. Run connection checks first.
2. Export DB before major changes.
3. Apply changes in small steps.
4. Re-check site state after each step.

## Common commands
```bash
./wp.sh db export "backup-$(date +%F-%H%M%S).sql"
./wp.sh post list --post_type=page --fields=ID,post_title,post_status --format=table
./wp.sh term list product_cat --fields=term_id,name,slug,count --format=table
./wp.sh menu list --fields=term_id,name,slug,count --format=table
./wp.sh cache flush
./wp.sh rewrite flush
```

## Guardrails
- Do not run global `search-replace` without `--dry-run`.
- Do not change `siteurl`/`home` unless explicitly requested.
- Do not run bulk destructive actions without backup + listing first.
