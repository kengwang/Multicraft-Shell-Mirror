<?php
$fl = array(
    array('file' => 'Linux64/multicraft-1.8.2-64.tar.gz', 'filename' => '1.8.2'),
    array('file' => 'Linux64/multicraft-2.0.1-64.tar.gz', 'filename' => '2.0.1'),
    array('file' => 'Linux64/multicraft-2.1.1-64.tar.gz', 'filename' => '2.1.1'),
    array('file' => 'Linux64/multicraft-2.2.0-64.tar.gz', 'filename' => '2.2.0'),
    array('file' => 'Linux64/multicraft-2.2.1-64.tar.gz', 'filename' => '2.2.1'),
    array('file' => 'Linux64/multicraft-2.3.0-64.tar.gz', 'filename' => '2.3.0'),
    array('file' => 'Linux64/multicraft-2.3.1-64.tar.gz', 'filename' => '2.3.1'),
    array('file' => 'Linux64/multicraft-2.3.2-64.tar.gz', 'filename' => '2.3.2'),
    array('file' => 'Linux64/multicraft-2.3.3-64.tar.gz', 'filename' => '2.3.3'),
    array('file' => 'Linux64/multicraft-2.3.4-64.tar.gz', 'filename' => '2.3.4')
);
$mirrorList = array(
    array('name' => 'Github - 同步于脚本更新 [更新速度快/国内下载速度慢](Github.com)', 'url' => 'https://raw.githubusercontent.com/kengwang/Multicraft-Shell-Mirror/master/muallver/'),
    array('name' => 'Gitee - 同步于Github更新 [更新速度快/国内下载速度将就](Gitee.com)', 'url' => 'https://gitee.com/kengwang/Multicraft-Shell-Mirror/raw/master/muallver/'),
    array('name' => 'Kengwang的阿里云OSS - [稳定/高速/请赞助!] (oss-beijing.aliyuncs.com)', 'url' => 'https://multicraftshell.oss-cn-beijing.aliyuncs.com/muallver/'),
    array('name' => 'Multicraft 官方 - !仅支持下载最新版', 'url' => 'http://multicraft.org/files/','mu'=>true)
);
if ($_GET['f'] == 'GetAvailable') {
    global $fl;
    foreach ($fl as $k => $f) {
        echo "[{$k}] => {$f['filename']} " . PHP_EOL;
    }
}

if ($_GET['f']=='getMd5') echo file_get_contents('http://multicraftshell.oss-cn-beijing.aliyuncs.com/muallver/'.$fl[$_GET['file']]['file'].'.md5sum');

if ($_GET['f'] == 'check') echo 'Pass';

if ($_GET['f'] == 'GetMirror') {
    global $mirrorList;
    foreach ($mirrorList as $k => $mirror) {
        echo "[{$k}] => {$mirror['name']}" . PHP_EOL;
    }
}

if ($_GET['f'] == 'Download') {
    if ($mirrorList[$_GET['mirror']]['mu'] == true) {
        header('Location: http://multicraft.org/download/linux64');
        exit;
    }
    global $mirrorList, $fl;
    header('Location: ' . $mirrorList[$_GET['mirror']]['url'] . $fl[$_GET['file']]['file']);
    exit;
}