#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <image_path> <post_id> [title]" >&2
  exit 1
fi

IMAGE_PATH="$1"
POST_ID="$2"
TITLE="${3:-}"

if [[ ! -f "$IMAGE_PATH" ]]; then
  echo "Error: image not found: $IMAGE_PATH" >&2
  exit 1
fi

if [[ ! -x "./wp.sh" ]]; then
  echo "Error: ./wp.sh not found or not executable. Run from project root after install.sh." >&2
  exit 1
fi

if [[ ! "$POST_ID" =~ ^[0-9]+$ ]]; then
  echo "Error: post_id must be numeric" >&2
  exit 1
fi

ARGS=(media import "$IMAGE_PATH" --post_id="$POST_ID" --featured_image --porcelain)
if [[ -n "$TITLE" ]]; then
  ARGS+=(--title="$TITLE")
fi

set +e
ATTACH_ID="$(./wp.sh "${ARGS[@]}" 2>/tmp/wp-media-import.err)"
STATUS=$?
set -e

if [[ $STATUS -eq 0 && -n "$ATTACH_ID" ]]; then
  echo "Imported attachment ID: $ATTACH_ID"
  echo "Set as featured image for post ID: $POST_ID"
  exit 0
fi

echo "Warning: wp media import failed, using fallback importer (no thumbnail metadata generation)." >&2
cat /tmp/wp-media-import.err >&2 || true

TMP_PHP="$(mktemp)"
cat > "$TMP_PHP" <<'PHP'
<?php
if (!empty($args) && $args[0] === '--') {
    array_shift($args);
}

if (!isset($args) || count($args) < 2) {
    fwrite(STDERR, "Usage: eval-file <image_path> <post_id> [title]\n");
    exit(1);
}

$image_path = $args[0];
$post_id = (int) $args[1];
$title = $args[2] ?? basename($image_path);

if (!file_exists($image_path)) {
    fwrite(STDERR, "File not found: {$image_path}\n");
    exit(1);
}

$upload_dir = wp_upload_dir();
$filename = wp_unique_filename($upload_dir['path'], basename($image_path));
$target_path = trailingslashit($upload_dir['path']) . $filename;

if (!copy($image_path, $target_path)) {
    fwrite(STDERR, "Failed to copy file to {$target_path}\n");
    exit(1);
}

$filetype = wp_check_filetype($filename, null);
$attachment = array(
    'guid'           => trailingslashit($upload_dir['url']) . $filename,
    'post_mime_type' => $filetype['type'] ?: 'application/octet-stream',
    'post_title'     => $title,
    'post_content'   => '',
    'post_status'    => 'inherit',
);

$attach_id = wp_insert_attachment($attachment, $target_path, $post_id);
if (is_wp_error($attach_id) || !$attach_id) {
    fwrite(STDERR, "wp_insert_attachment failed\n");
    exit(1);
}

update_post_meta($post_id, '_thumbnail_id', (int) $attach_id);
echo (int) $attach_id . PHP_EOL;
PHP

ATTACH_ID="$(./wp.sh eval-file "$TMP_PHP" -- "$IMAGE_PATH" "$POST_ID" "$TITLE")"
rm -f "$TMP_PHP" /tmp/wp-media-import.err

echo "Imported attachment ID (fallback): $ATTACH_ID"
echo "Set as featured image for post ID: $POST_ID"
