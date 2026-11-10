#!/bin/sh
## build time: add a ReflectorsPage['Show'] option to the dashboard (upstream always shows the page)
## and make the menu link and the page switch honour it. fails the build if upstream's markup moved.
## usage: patch-dashboard.sh <dashboard dir>
set -eu
WEB=$1
CFG="${WEB}/pgs/config.inc.php"
IDX="${WEB}/index.php"

## the option, next to the other page switches (customize.sh sets it from REFLECTORS_PAGE)
grep -q "PageOptions\['IRCDDB'\]\['Show'\]" "${CFG}"
sed -i "/PageOptions\['IRCDDB'\]\['Show'\]/i \$PageOptions['ReflectorsPage']['Show']             = true;		// Show the Reflectors list page" "${CFG}"

## the menu link: wrap the table cell (no end-of-line anchor - upstream ships the php files with CRLF)
grep -q '<td><a href="./index.php?show=reflectors"' "${IDX}"
sed -i "/<td><a href=\"\.\/index\.php?show=reflectors\"/{
s|<td><a href=\"\./index\.php?show=reflectors\"|<?php if (\$PageOptions['ReflectorsPage']['Show']) { ?>&|
s|</td>|</td><?php } ?>|
}" "${IDX}"

## the page itself: fall back to the users page when it's switched off
grep -q "case 'reflectors' *: require_once(\"./pgs/reflectors.php\"); break;" "${IDX}"
sed -i "s|case 'reflectors' *: require_once(\"./pgs/reflectors.php\"); break;|case 'reflectors' : require_once(\$PageOptions['ReflectorsPage']['Show'] ? \"./pgs/reflectors.php\" : \"./pgs/users.php\"); break;|" "${IDX}"

## all three must have landed
grep -q "^\$PageOptions\['ReflectorsPage'\]\['Show'\]" "${CFG}"
grep -q "<?php if (\$PageOptions\['ReflectorsPage'\]\['Show'\]) { ?><td><a href=\"./index.php?show=reflectors\"" "${IDX}"
grep -q "require_once(\$PageOptions\['ReflectorsPage'\]\['Show'\] ? \"./pgs/reflectors.php\"" "${IDX}"
echo "dashboard patched: ReflectorsPage switch"
