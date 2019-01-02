<?php

$lat1 = 38.345015;
$long1 = -0.479230;

$lat2 = 38.541673;
$long2 = -0.126957;

$lat3 = 39.522671;
$long3 = -0.358636;

function inMiles($lat1, $long1, $lat2, $long2)  {
    return sqrt(((69.1 * ($lat2 - $lat1)) ** 2) + ((53 * ($long2 - $long1)) ** 2));
}

function inKilometers($lat1, $long1, $lat2, $long2)  {
    $milesToKm = 1.609344;
    return sqrt(((69.1 * $milesToKm * ($lat2 - $lat1)) ** 2) + ((53 * $milesToKm * ($long2 - $long1)) ** 2));
}

function inDegrees($lat1, $long1, $lat2, $long2)  {
    return ($lat2 - $lat1) ** 2 + ($long2 - $long1) ** 2;
}

echo round(inMiles($lat1, $long1, $lat2, $long2), 2), PHP_EOL;
echo round(inMiles($lat1, $long1, $lat3, $long3), 2), PHP_EOL;
echo '------------------------------------', PHP_EOL;

echo round(inKilometers($lat1, $long1, $lat2, $long2), 2), PHP_EOL;
echo round(inKilometers($lat1, $long1, $lat3, $long3), 2), PHP_EOL;
echo '------------------------------------', PHP_EOL;

echo round(inDegrees($lat1, $long1, $lat2, $long2), 5), PHP_EOL;
echo round(inDegrees($lat1, $long1, $lat3, $long3), 5), PHP_EOL;
