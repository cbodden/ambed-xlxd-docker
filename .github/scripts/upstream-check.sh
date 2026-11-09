#!/usr/bin/env bash
## compares the LX3JL/xlxd commit pinned in the Dockerfiles (XLXD_GIT_REF)
## against upstream master && opens / updates an issue when upstream moved
##
## env:
##   GH_TOKEN         token for gh (issues: write)
##   REPO             owner/repo to file the issue in (github.repository)
##   DRY_RUN          true = print the report only, never touch issues
##   PINNED_OVERRIDE  optional sha to pretend is pinned (testing)

set -euo pipefail

UPSTREAM=LX3JL/xlxd
TITLE_PREFIX="Upstream xlxd update"
DRY_RUN=${DRY_RUN:-false}

pinned_ambed=$(sed -n 's/^ARG XLXD_GIT_REF=//p' AMBEd/Dockerfile)
pinned_xlxd=$(sed -n 's/^ARG XLXD_GIT_REF=//p' XLXd/Dockerfile)
pinned=${PINNED_OVERRIDE:-${pinned_xlxd}}
upstream=$(git ls-remote "https://github.com/${UPSTREAM}.git" refs/heads/master | cut -f1)

if [ -z "${pinned}" ] || [ -z "${upstream}" ]; then
  echo "could not read pinned (${pinned:-none}) or upstream (${upstream:-none}) ref"
  exit 1
fi

## version from a main.h at a given commit : ver <sha> <path>
ver() {
  curl -fsSL "https://raw.githubusercontent.com/${UPSTREAM}/$1/$2" \
    | awk '/define VERSION_(MAJOR|MINOR|REVISION)/{v=v (v?".":"") $3} END{print v}'
}

if [ "${pinned}" = "${upstream}" ]; then
  echo "up to date : pinned ${pinned:0:7} == ${UPSTREAM} master"
  [ "${pinned_ambed}" != "${pinned_xlxd}" ] \
    && echo "WARNING : AMBEd (${pinned_ambed:0:7}) && XLXd (${pinned_xlxd:0:7}) pins differ"
  exit 0
fi

xlxd_old=$(ver "${pinned}" src/main.h)
xlxd_new=$(ver "${upstream}" src/main.h)
ambed_old=$(ver "${pinned}" ambed/main.h)
ambed_new=$(ver "${upstream}" ambed/main.h)

compare=$(gh api "repos/${UPSTREAM}/compare/${pinned}...${upstream}")
commits=$(jq -r '.total_commits' <<< "${compare}")
log=$(jq -r '.commits[-15:] | reverse | .[] | "- `\(.sha[0:7])` \(.commit.message | split("\n")[0])"' <<< "${compare}")
## areas that broke or changed the docker build before :
## build config, makefiles, the dashboard config customize.sh seds, removed / renamed dashboard1 files
watch=$(jq -r '[.files[]
  | select(.filename == "src/main.h" or .filename == "ambed/main.h"
           or (.filename | endswith("makefile")) or (.filename | startswith("config/"))
           or .filename == "dashboard1/pgs/config.inc.php"
           or ((.filename | startswith("dashboard1/") or startswith("dashboard/"))
               and (.status == "removed" or .status == "renamed")))
  | "- `\(.filename)` (\(.status))"] | unique | .[]' <<< "${compare}")
dash_other=$(jq -r '[.files[] | select((.filename | startswith("dashboard1/"))
  and .filename != "dashboard1/pgs/config.inc.php" and .status != "removed" and .status != "renamed")] | length' <<< "${compare}")
[ "${dash_other}" -gt 0 ] && watch="${watch}
- plus ${dash_other} other changed file(s) in \`dashboard1/\`"
## the compare api only returns the first 300 files
[ "$(jq '.files | length' <<< "${compare}")" -ge 300 ] && watch="${watch}
- **list truncated** : github only returns the first 300 changed files - check the compare link"

title="${TITLE_PREFIX}: xlxd ${xlxd_old} -> ${xlxd_new}, AMBEd ${ambed_old} -> ${ambed_new}"
[ "${xlxd_old}" = "${xlxd_new}" ] && [ "${ambed_old}" = "${ambed_new}" ] \
  && title="${TITLE_PREFIX}: ${commits} new commits (xlxd ${xlxd_new}, AMBEd ${ambed_new})"

body=$(cat <<EOF
${UPSTREAM} master has moved past the commit pinned in the Dockerfiles.

| | pinned | upstream master |
| :-- | :-- | :-- |
| commit | \`${pinned:0:7}\` | \`${upstream:0:7}\` |
| xlxd | ${xlxd_old} | ${xlxd_new} |
| AMBEd | ${ambed_old} | ${ambed_new} |

**${commits} new commits** - [compare](https://github.com/${UPSTREAM}/compare/${pinned}...${upstream})

### recent commits
${log}

### changed files worth checking before upgrading
${watch:-- none of the usual suspects (dashboard, makefiles, main.h, config)}

### upgrade steps
- [ ] set \`ARG XLXD_GIT_REF=${upstream}\` in \`AMBEd/Dockerfile\` && \`XLXd/Dockerfile\`
- [ ] push to \`testing\` -> CI publishes \`:test\`
- [ ] run \`:test\` on 005 with the ThumbDVs
- [ ] merge \`testing\` -> \`main\` -> CI publishes \`:latest\`
- [ ] tag \`v${xlxd_new}\` -> CI publishes \`:${xlxd_new}\`

_updated by the upstream-check workflow - $(date -u +%Y-%m-%d)_
EOF
)

if [ "${pinned_ambed}" != "${pinned_xlxd}" ]; then
  body="${body}

**WARNING** : AMBEd (\`${pinned_ambed:0:7}\`) && XLXd (\`${pinned_xlxd:0:7}\`) pins differ"
fi

echo "${title}"
echo
echo "${body}"

if [ "${DRY_RUN}" = "true" ]; then
  echo
  echo "dry run - not touching issues"
  exit 0
fi

existing=$(gh issue list -R "${REPO}" --state open --search "in:title \"${TITLE_PREFIX}\"" \
  --json number,title -q "[.[] | select(.title | startswith(\"${TITLE_PREFIX}\"))][0].number // empty")

if [ -n "${existing}" ]; then
  gh issue edit "${existing}" -R "${REPO}" --title "${title}" --body "${body}"
  echo "updated issue #${existing}"
else
  gh issue create -R "${REPO}" --title "${title}" --body "${body}"
fi
