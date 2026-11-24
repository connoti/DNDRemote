<?php
// Run with WP-CLI on DirectNorth only, after verifying both package URLs.

if (untrailingslashit(home_url()) !== 'https://directnorth.digital') {
    WP_CLI::error('This change is for DirectNorth.digital.');
}

$page = get_post(11640);
if (!$page || $page->post_name !== 'remote' || $page->post_status !== 'publish') {
    WP_CLI::error('The published Remote Access page could not be confirmed.');
}

$upload = wp_get_upload_dir();
$directory = trailingslashit($upload['basedir']) . 'directnorth-remote/';
$base_url = trailingslashit($upload['baseurl']) . 'directnorth-remote/';
$files = [
    'Apple silicon' => 'directnorth-remote-1.5.3-apple-silicon-pilot.pkg',
    'Intel' => 'directnorth-remote-1.5.3-intel-pilot.pkg',
];

$buttons = '';
foreach ($files as $label => $filename) {
    $path = $directory . $filename;
    if (!is_file($path) || !is_readable($path) || filesize($path) < 20 * 1024 * 1024) {
        WP_CLI::error('Missing or incomplete package: ' . $filename);
    }
    $buttons .= '<a class="button" href="' . esc_url($base_url . $filename)
        . '">Download for Mac (' . esc_html($label) . ')</a>';
}

$before = $page->post_content;
$previous = '<div class="buttons"><a class="button" href="https://directnorth-downloads-137972146164.s3.amazonaws.com/DirectNorth-Remote-Access-Mac.dmg">Download for Mac</a>';
if (substr_count($before, $previous) !== 1) {
    WP_CLI::error('The original Mac download block did not match exactly once.');
}
$after = str_replace($previous, '<div class="buttons" style="flex-wrap:wrap">' . $buttons, $before);

$marker = '<p class="private">Private server:';
if (substr_count($after, $marker) !== 1) {
    WP_CLI::error('The download notice position did not match exactly once.');
}
$notice = '<p class="private">Mac downloads are unsigned pilot installers. '
    . 'Check Apple menu → About This Mac for your processor. '
    . '<a href="https://github.com/rustdesk/rustdesk/tree/1.5.3">RustDesk source and license</a>.</p>';
$after = str_replace($marker, $notice . $marker, $after);

$home = getenv('HOME');
if (!$home || strpos($home . '/', ABSPATH) === 0) {
    WP_CLI::error('A rollback file must be stored outside the web root.');
}
$backup = tempnam($home, 'directnorth-remote-11640-');
if (!$backup || file_put_contents($backup, $before) !== strlen($before) || !chmod($backup, 0600)) {
    WP_CLI::error('Failed to create the private rollback file.');
}

// Keep Divi's original inline HTML intact during the scoped content update.
kses_remove_filters();
$updated = wp_update_post(wp_slash(['ID' => $page->ID, 'post_content' => $after]), true);
if (is_wp_error($updated) || get_post_field('post_content', $page->ID, 'raw') !== $after) {
    wp_update_post(wp_slash(['ID' => $page->ID, 'post_content' => $before]), true);
    WP_CLI::error('Update failed its exact readback check. Rollback file: ' . $backup);
}

WP_CLI::success('Updated the two Mac pilot buttons. Rollback file: ' . $backup);
