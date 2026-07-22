<?php

# UniFi Controller NG - main web frontend.
# Uses the LoxBerry Design System (lb-* classes), not jQuery Mobile.

require_once "loxberry_system.php";
require_once "loxberry_web.php";
require_once "loxberry_log.php";

##########################################################################
# Constants / setup
##########################################################################

define('UNIFING_SERVICE', 'unifing');
define('UNIFING_APP_CONTAINER', 'unifing-app');
define('UNIFING_DB_CONTAINER', 'unifing-db');
# Absolute path to the sudo-enabled control helper (replaced at install time).
define('UNIFING_CTL', 'sudo REPLACELBPSBINDIR/unifing_ctl.sh');
# Docker Hub tags of the app image.
define('UNIFING_TAGS_URL', 'https://hub.docker.com/v2/repositories/linuxserver/unifi-network-application/tags/?page_size=100&page=1&ordering=last_updated');

$version = LBSystem::pluginversion();
$L = LBSystem::readlanguage("language.ini");
$envfile = "$lbpconfigdir/env";

$form = isset($_REQUEST['form']) ? $_REQUEST['form'] : 'main';

$log = LBLog::newLog(["name" => "index", "addtime" => 1]);
$log->LOGSTART("index.php called (form: $form)");

##########################################################################
# Helper functions
##########################################################################

function unifing_service_status()
{
    $out = shell_exec("systemctl show --value " . UNIFING_SERVICE . " --property ActiveState 2>/dev/null");
    return $out === null ? "unknown" : trim($out);
}

function unifing_container_version($envfile)
{
    if (!is_readable($envfile)) {
        return "";
    }
    foreach (file($envfile, FILE_IGNORE_NEW_LINES) as $line) {
        if (strpos($line, 'VERSION=') === 0) {
            return trim(substr($line, strlen('VERSION=')));
        }
    }
    return "";
}

function unifing_set_container_version($envfile, $version)
{
    $lines = is_readable($envfile) ? file($envfile, FILE_IGNORE_NEW_LINES) : array();
    $out = array();
    $found = false;
    foreach ($lines as $line) {
        if (strpos($line, 'VERSION=') === 0) {
            $out[] = "VERSION=$version";
            $found = true;
        } elseif (trim($line) !== '') {
            $out[] = $line;
        }
    }
    if (!$found) {
        array_unshift($out, "VERSION=$version");
    }
    file_put_contents($envfile, implode("\n", $out) . "\n");
}

function unifing_controller_version()
{
    $ctx = stream_context_create([
        "ssl"  => ["verify_peer" => false, "verify_peer_name" => false],
        "http" => ["timeout" => 3, "ignore_errors" => true],
    ]);
    $json = @file_get_contents("https://127.0.0.1:8443/status", false, $ctx);
    if ($json === false) {
        return "starting";
    }
    $data = json_decode($json, true);
    if (isset($data["meta"]["server_version"])) {
        return $data["meta"]["server_version"];
    }
    return "starting";
}

function unifing_host_arch()
{
    switch (php_uname('m')) {
        case 'x86_64':
        case 'amd64':
            return 'amd64';
        case 'aarch64':
        case 'arm64':
            return 'arm64';
        default:
            return php_uname('m');
    }
}

function unifing_versions()
{
    $ctx = stream_context_create([
        "ssl"  => ["verify_peer" => false, "verify_peer_name" => false],
        "http" => ["timeout" => 5],
    ]);
    $json = @file_get_contents(UNIFING_TAGS_URL, false, $ctx);
    if ($json === false) {
        return array();
    }
    $data = json_decode($json, true);
    if (!isset($data["results"])) {
        return array();
    }
    $arch = unifing_host_arch();
    $items = array();
    foreach ($data["results"] as $result) {
        if (!isset($result["images"]) || count($result["images"]) < 2) {
            continue;
        }
        $archs = array();
        foreach ($result["images"] as $image) {
            if (isset($image["architecture"])) {
                $archs[] = $image["architecture"];
            }
        }
        if (in_array($arch, $archs, true)) {
            $items[] = $result["name"];
        }
    }
    return $items;
}

function unifing_ctl($action)
{
    $allowed = array("restart", "start", "stop", "reset");
    if (!in_array($action, $allowed, true)) {
        return;
    }
    shell_exec(UNIFING_CTL . " " . $action . " > /dev/null 2>&1 &");
}

function unifing_diagnostics()
{
    $sections = array();

    $status = shell_exec("systemctl status " . UNIFING_SERVICE . " --no-pager -l 2>&1");
    $sections[] = "=== systemctl status " . UNIFING_SERVICE . " ===\n" . ($status ?: "");

    $ps = shell_exec("docker ps -a --filter name=" . UNIFING_APP_CONTAINER . " --filter name=" . UNIFING_DB_CONTAINER . " 2>&1");
    $sections[] = "=== docker ps -a ===\n" . ($ps ?: "");

    $df = shell_exec("df -h / 2>&1");
    $sections[] = "=== disk space ===\n" . ($df ?: "");

    $applog = shell_exec("docker logs --tail 150 --timestamps " . UNIFING_APP_CONTAINER . " 2>&1");
    $sections[] = "=== docker logs " . UNIFING_APP_CONTAINER . " (app) ===\n" . ($applog ?: "");

    $dblog = shell_exec("docker logs --tail 150 --timestamps " . UNIFING_DB_CONTAINER . " 2>&1");
    $sections[] = "=== docker logs " . UNIFING_DB_CONTAINER . " (database) ===\n" . ($dblog ?: "");

    $serverlog = shell_exec("docker exec " . UNIFING_APP_CONTAINER . " tail -n 150 /config/logs/server.log 2>&1");
    $sections[] = "=== UniFi server.log ===\n" . ($serverlog ?: "");

    return implode("\n\n", $sections);
}

##########################################################################
# POST actions (Post/Redirect/Get)
##########################################################################

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if ($form === 'setversion') {
        $newversion = isset($_POST['version']) ? trim($_POST['version']) : '';
        if ($newversion !== '' && preg_match('/^[A-Za-z0-9._-]+$/', $newversion)) {
            unifing_set_container_version($envfile, $newversion);
            $log->INF("Changing container version to $newversion");
            unifing_ctl("restart");
        }
    } elseif ($form === 'reset') {
        $log->INF("Resetting service");
        unifing_ctl("reset");
    }
    header("Location: index.php");
    exit;
}

##########################################################################
# Status fragment (plain text, polled by the main page)
##########################################################################

if ($form === 'statusonly') {
    header("Content-Type: text/plain; charset=utf-8");
    echo unifing_service_status();
    exit;
}

##########################################################################
# Diagnostics page (opened in its own window)
##########################################################################

if ($form === 'diagnostics') {
    $diagnostics = unifing_diagnostics();
    LBWeb::lbheader($L['DIAG.HEADING'] . " - " . $L['BASIC.LABEL_PLUGINTITLE'], "https://wiki.loxberry.de", "help.html", true);
    include "$lbptemplatedir/diagnostics.html";
    LBWeb::lbfooter();
    exit;
}

##########################################################################
# Main page
##########################################################################

$status         = unifing_service_status();
$containerversion = unifing_container_version($envfile);
$controllerversion = unifing_controller_version();
$versions       = unifing_versions();

LBWeb::lbheader($L['BASIC.LABEL_PLUGINTITLE'] . " V$version", "https://wiki.loxberry.de", "help.html", true);
include "$lbptemplatedir/main.html";
LBWeb::lbfooter();
exit;
