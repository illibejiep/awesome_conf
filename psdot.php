<?php

exec('ps -e -o pid,ppid,comm,%mem,%cpu',$out);
unset($out[0]);

$pslist = array();
$maxMem = 0;
$maxCpu = 0;
foreach ($out as $line) {
    $line = trim(preg_replace('/ +/',' ',$line));

    $psData = explode(' ',$line);
    $pslist[$psData[0]] = array(
        'id' => (int)$psData[0],
        'pid' => (int)$psData[1],
        'name' => $psData[2],
        'mem' => (float)$psData[3],
        'cpu' => (float)$psData[4],
    );
    $maxMem = max($maxMem,(float)$psData[3]);
    $maxCpu = max($maxCpu,(float)$psData[4]);
}

echo '
graph A {
        overlap="0:true"
        truecolor=true
        dpi=120
        size="16,10"
        layout="neato"
        bgcolor="#1E231F"
        sep="300,1"
        splines=curved
        node [
                shape=circle
                style="filled"
                gradientangle=100
                fillcolor="#1E231F11:#F0E0AD11"
                color="#ffffff00#"
                fontcolor="#7F9F7Faa"
                fontname="ubuntu"
                fixedsize=true
        ]
        edge [
                len=1.6
                color="#F0E0AD55"
        ]
';

$minFont = 15;
$maxFont = 100;


foreach ($pslist as $id=>$psData) {
    $fontSize = (int)($minFont + $psData['mem']*$maxFont/$maxMem);

    echo 'p'.$id.' [label="'.$psData['name'].'" fontsize="'.$fontSize.'" width="'.($fontSize/30).'"]'.PHP_EOL;
}
foreach ($pslist as $id=>$psData)
    if ($psData['pid'])
        echo 'p'.$id.' -- p'.$psData['pid'].PHP_EOL;

echo '}';

