#!/bin/sh
## build time: add a ReflectorsPage['Show'] option to the dashboard (upstream always shows the page)
## and make the menu link and the page switch honour it, and add an optional InfoPage.
## fails the build if upstream's markup moved.
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

## an optional info page (InfoPage, INFO_PAGE) showing the operator's own HTML file (pgs/info.php),
## with its menu link right after Users / Modules. customize.sh sets the switch, title and file
TMP=$(mktemp -d)

## the options, after the Traffic switch
cat > "${TMP}/cfg" <<"EOF"
$PageOptions['InfoPage']['Show']                     = false;		// Show the info page
$PageOptions['InfoPage']['Title']                    = 'Info';		// Its menu link
$PageOptions['InfoPage']['File']                     = '/config/info.html';	// The HTML shown on it
EOF
[ "$(grep -c "^\$PageOptions\['Traffic'\]\['Show'\]" "${CFG}")" -eq 1 ]
sed -i "/^\$PageOptions\['Traffic'\]\['Show'\]/r ${TMP}/cfg" "${CFG}"

## a page name index.php accepts
grep -q "'p25peers'\];" "${IDX}"
sed -i "s/'p25peers'\];/'p25peers', 'info'];/" "${IDX}"

## no auto-refresh on it, like the reflectors list - a refresh would jump back to the top
grep -q "(\$_GET\['show'\] != 'interlinks')" "${IDX}"
sed -i "s/(\$_GET\['show'\] != 'interlinks')/& \&\& (\$_GET['show'] != 'info')/" "${IDX}"

## the menu link
cat > "${TMP}/menu" <<"EOF"
<?php if ($PageOptions['InfoPage']['Show']) { ?><td><a href="./index.php?show=info" class="menulink<?php if ($_GET['show'] == 'info') { echo 'active'; } ?>"><?php echo sanitize_output($PageOptions['InfoPage']['Title']); ?></a></td><?php } ?>
EOF
[ "$(grep -c '<td><a href="./index.php" class="menulink' "${IDX}")" -eq 1 ]
sed -i "/<td><a href=\"\.\/index\.php\" class=\"menulink/r ${TMP}/menu" "${IDX}"

## the page, falling back to the users page when it's switched off
cat > "${TMP}/case" <<"EOF"
      case 'info'       : require_once($PageOptions['InfoPage']['Show'] ? "./pgs/info.php" : "./pgs/users.php"); break;
EOF
[ "$(grep -c "case 'p25peers' *:" "${IDX}")" -eq 1 ]
sed -i "/case 'p25peers' *:/r ${TMP}/case" "${IDX}"
rm -r "${TMP}"

## all five must have landed
grep -q "^\$PageOptions\['InfoPage'\]\['File'\]" "${CFG}"
grep -q "'p25peers', 'info'\];" "${IDX}"
grep -q "(\$_GET\['show'\] != 'info')" "${IDX}"
grep -q "<?php if (\$PageOptions\['InfoPage'\]\['Show'\]) { ?><td><a href=\"./index.php?show=info\"" "${IDX}"
grep -q "case 'info' *: require_once(\$PageOptions\['InfoPage'\]\['Show'\] ? \"./pgs/info.php\"" "${IDX}"
echo "dashboard patched: InfoPage switch"
