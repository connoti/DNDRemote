<?php
// Run with WP-CLI on DirectNorth. Updates only the Get connected guide.

$page = get_post(11640);
if (untrailingslashit(home_url()) !== 'https://directnorth.digital' || !$page
    || $page->post_name !== 'remote' || $page->post_status !== 'publish') {
    WP_CLI::error('The published DirectNorth Remote Access page could not be confirmed.');
}

$before = $page->post_content;
$start = '<h2>Get connected.</h2>';
$end = '<p class="callout">The downloads configure <code>remote.directnorth.digital</code> automatically. Only connect with people you know and trust.</p>';
if (substr_count($before, $start) !== 1 || substr_count($before, $end) !== 1
    || strpos($before, 'Download the Mac disk image and open the DMG file.') === false) {
    WP_CLI::error('The original guide did not match.');
}

$guide = <<<'HTML'
<h2>Get connected.</h2>
<p>A short guide for Mac and Windows.</p>
</div>
<div class="grid">
<div class="block">
<h3>Mac</h3>
<ol>
<li>Choose <strong>Mac Apple silicon</strong> for a Mac with an Apple chip or <strong>Mac Intel</strong> for a Mac with an Intel processor. Check <strong>Apple menu → About This Mac</strong> if you’re unsure.</li>
<li>Open the downloaded <strong>.pkg</strong> file and follow the Installer prompts.</li>
<li>Open <strong>RustDesk</strong> from Applications. Look for green <strong>Ready</strong> and the ID under <strong>Your Desktop</strong>.</li>
<li>If someone will control your Mac, allow RustDesk in <strong>Privacy &amp; Security</strong> for <strong>Screen Recording</strong> (or <strong>Screen &amp; System Audio Recording</strong>) and <strong>Accessibility</strong>. Allow <strong>Input Monitoring</strong> if RustDesk asks for it.</li>
</ol>
<p>The Mac packages are unsigned pilots. If macOS blocks the installer, contact DirectNorth.</p>
</div>
<div class="block">
<h3>Windows</h3>
<ol>
<li>Choose the <strong>Windows 64-bit installer</strong> and open the downloaded <strong>.exe</strong> file.</li>
<li>Follow any Windows prompts and wait for RustDesk to open.</li>
<li>Look for green <strong>Ready</strong> and the ID under <strong>Your Desktop</strong>.</li>
</ol>
</div>
<div class="block wide">
<h3>Share or control a desktop</h3>
<p><strong>To share:</strong> Give your trusted helper the ID under <strong>Your Desktop</strong>. Approve their request when it appears. If RustDesk asks for a one-time password, share it privately with that helper.</p>
<p><strong>To help:</strong> Enter the other person’s RustDesk ID under <strong>Control Remote Desktop</strong>, select <strong>Connect</strong>, and wait for them to approve the session. Disconnect when you’re done.</p>
<p class="callout">The downloads configure <code>remote.directnorth.digital</code> automatically. Only connect with people you know and trust.</p>
HTML;

$start_at = strpos($before, $start);
$end_at = strpos($before, $end) + strlen($end);
$original_guide = substr($before, $start_at, $end_at - $start_at);
if ($end_at <= $start_at || strpos($original_guide, 'Download the Mac disk image') === false
    || strpos($original_guide, '[/et_pb_') !== false) {
    WP_CLI::error('The guide boundaries could not be confirmed within one Divi module.');
}
$after = substr_replace($before, $guide, $start_at, $end_at - $start_at);

kses_remove_filters();
$result = wp_update_post(wp_slash(['ID' => $page->ID, 'post_content' => $after]), true);
if (is_wp_error($result) || get_post_field('post_content', $page->ID, 'raw') !== $after) {
    wp_update_post(wp_slash(['ID' => $page->ID, 'post_content' => $before]), true);
    WP_CLI::error('The guide failed its exact readback check.');
}
WP_CLI::success('Updated only the Get connected guide.');
