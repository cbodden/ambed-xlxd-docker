#!/usr/bin/env bash
## compares what the Dockerfiles pin against upstream && opens a PR into testing that bumps the pin
##   LX3JL/xlxd master          vs  XLXD_GIT_REF        in AMBEd/Dockerfile && XLXd/Dockerfile
##   s6-overlay latest release  vs  S6_OVERLAY_VERSION  in AMBEd/Dockerfile && XLXd/Dockerfile
##
## one branch per upstream version (upstream/<name>-<version>):
##   same version next week   -> the open PR's description is refreshed
##   newer version            -> new PR, the older one is closed as superseded
##   PR closed without merge  -> its branch is left alone && that version isn't proposed again
##   pin already up to date   -> leftover upstream PRs for it are closed
## new PRs get a build check by dispatching docker-images on the branch (it publishes no tags there),
## since pushes / PRs made with GITHUB_TOKEN don't trigger workflows themselves
##
## run from a checkout of BASE (testing)
## env:
##   GH_TOKEN             token for gh (contents, pull-requests, actions: write)
##   REPO                 owner/repo (github.repository)
##   BASE                 branch the PRs target (default testing)
##   DRY_RUN              true = print the reports && the pin diffs only, touch nothing
##   PINNED_OVERRIDE      optional xlxd sha to pretend is pinned (testing)
##   S6_PINNED_OVERRIDE   optional s6-overlay version to pretend is pinned (testing)

set -euo pipefail

DRY_RUN=${DRY_RUN:-false}
BASE=${BASE:-testing}
BOT_NAME="github-actions[bot]"
BOT_EMAIL="41898283+github-actions[bot]@users.noreply.github.com"
DOCKERFILES="AMBEd/Dockerfile XLXd/Dockerfile"

## pin bumps, run from the repo root (or a copy of it)
bump_xlxd() { sed -i "s/^ARG XLXD_GIT_REF=.*/ARG XLXD_GIT_REF=$1/" ${DOCKERFILES}; }
bump_s6() { sed -i "s/^ARG S6_OVERLAY_VERSION=[^ ]*/ARG S6_OVERLAY_VERSION=$1/" ${DOCKERFILES}; }

## close open upstream PRs for <name> other than <keep> : close_stale <name> <keep branch> <comment>
close_stale() {
  local name=$1 keep=$2 comment=$3 n
  for n in $(gh pr list -R "${REPO}" --state open --json number,headRefName \
      -q ".[] | select(.headRefName | startswith(\"upstream/${name}-\")) | select(.headRefName != \"${keep}\") | .number"); do
    if [ "${DRY_RUN}" = "true" ]; then
      echo "dry run - would close PR #${n}: ${comment}"
    else
      gh pr close "${n}" -R "${REPO}" --comment "${comment}" --delete-branch
    fi
  done
}

## open or refresh the bump PR : open_pr <name> <version> <title> <body> <bump command>
open_pr() {
  local name=$1 version=$2 title=$3 body=$4 bump=$5
  local branch="upstream/${name}-${version}" existing tmp new f
  echo "${title}"
  echo
  echo "${body}"
  echo

  if [ "${DRY_RUN}" = "true" ]; then
    tmp=$(mktemp -d)
    for f in ${DOCKERFILES}; do
      mkdir -p "${tmp}/$(dirname "${f}")"
      cp "${f}" "${tmp}/${f}"
    done
    (cd "${tmp}" && ${bump})
    echo "dry run - ${branch} would change:"
    for f in ${DOCKERFILES}; do
      diff -u "${f}" "${tmp}/${f}" || true
    done
    rm -rf "${tmp}"
    close_stale "${name}" "${branch}" "superseded by ${branch}"
    return
  fi

  existing=$(gh pr list -R "${REPO}" --state open --head "${branch}" --json number -q '.[0].number // empty')
  if [ -n "${existing}" ]; then
    gh pr edit "${existing}" -R "${REPO}" --title "${title}" --body "${body}"
    echo "refreshed PR #${existing}"
  elif git ls-remote --exit-code --heads origin "${branch}" > /dev/null; then
    echo "${branch} exists with no open PR - that version was declined, not proposing it again"
    return
  else
    git switch -q -c "${branch}"
    ${bump}
    git -c user.name="${BOT_NAME}" -c user.email="${BOT_EMAIL}" commit -q -am "${title}"
    git push -q origin "${branch}"
    git switch -q "${BASE}"
    new=$(gh pr create -R "${REPO}" --base "${BASE}" --head "${branch}" --title "${title}" --body "${body}")
    echo "opened ${new}"
    gh workflow run docker-images.yml -R "${REPO}" --ref "${branch}"
    echo "dispatched docker-images on ${branch} as a build check"
    close_stale "${name}" "${branch}" "superseded by ${new}"
  fi
}

##################
###### xlxd ######
##################

## version from a main.h at a given commit : ver <sha> <path>
ver() {
  curl -fsSL "https://raw.githubusercontent.com/LX3JL/xlxd/$1/$2" \
    | awk '/define VERSION_(MAJOR|MINOR|REVISION)/{v=v (v?".":"") $3} END{print v}'
}

check_xlxd() {
  local upstream_repo=LX3JL/xlxd
  local pinned_ambed pinned_xlxd pinned upstream xlxd_old xlxd_new ambed_old ambed_new
  local compare commits log watch dash_other title body

  pinned_ambed=$(sed -n 's/^ARG XLXD_GIT_REF=//p' AMBEd/Dockerfile)
  pinned_xlxd=$(sed -n 's/^ARG XLXD_GIT_REF=//p' XLXd/Dockerfile)
  pinned=${PINNED_OVERRIDE:-${pinned_xlxd}}
  upstream=$(gh api "repos/${upstream_repo}/commits/master" --jq .sha)
  if [ -z "${pinned}" ] || [ -z "${upstream}" ]; then
    echo "xlxd: could not read pinned (${pinned:-none}) or upstream (${upstream:-none}) ref"
    return 1
  fi
  if [ "${pinned}" = "${upstream}" ] && [ "${pinned_ambed}" = "${upstream}" ]; then
    echo "xlxd up to date : pinned ${pinned:0:7} == ${upstream_repo} master"
    close_stale xlxd "" "XLXD_GIT_REF is already ${pinned:0:7} (upstream master) - closing"
    return
  fi

  xlxd_old=$(ver "${pinned}" src/main.h)
  xlxd_new=$(ver "${upstream}" src/main.h)
  ambed_old=$(ver "${pinned}" ambed/main.h)
  ambed_new=$(ver "${upstream}" ambed/main.h)

  compare=$(gh api "repos/${upstream_repo}/compare/${pinned}...${upstream}")
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
  if [ "${dash_other}" -gt 0 ]; then
    watch="${watch}
- plus ${dash_other} other changed file(s) in \`dashboard1/\`"
  fi
  ## the compare api only returns the first 300 files
  if [ "$(jq '.files | length' <<< "${compare}")" -ge 300 ]; then
    watch="${watch}
- **list truncated** : github only returns the first 300 changed files - check the compare link"
  fi

  title="xlxd: bump to ${upstream:0:7} (xlxd ${xlxd_old} -> ${xlxd_new}, AMBEd ${ambed_old} -> ${ambed_new})"
  if [ "${xlxd_old}" = "${xlxd_new}" ] && [ "${ambed_old}" = "${ambed_new}" ]; then
    title="xlxd: bump to ${upstream:0:7} (${commits} new commits, xlxd ${xlxd_new}, AMBEd ${ambed_new})"
  fi

  body=$(cat <<EOF
${upstream_repo} master has moved past the commit pinned in the Dockerfiles; this PR sets \`XLXD_GIT_REF\` to it in \`AMBEd/Dockerfile\` && \`XLXd/Dockerfile\`.

| | pinned | upstream master |
| :-- | :-- | :-- |
| commit | \`${pinned:0:7}\` | \`${upstream:0:7}\` |
| xlxd | ${xlxd_old} | ${xlxd_new} |
| AMBEd | ${ambed_old} | ${ambed_new} |

**${commits} new commits** - [compare](https://github.com/${upstream_repo}/compare/${pinned}...${upstream})

### recent commits
${log}

### changed files worth checking before merging
${watch:-- none of the usual suspects (dashboard, makefiles, main.h, config)}

### before / after merging
- [ ] the docker images build check on this branch passed (both images, amd64 + arm64)
- [ ] merge -> CI publishes \`:test\`
- [ ] run \`:test\` on 005 with the ThumbDVs
- [ ] merge \`testing\` -> \`main\` -> CI publishes \`:latest\`
- [ ] tag \`v${xlxd_new}\` -> CI publishes \`:${xlxd_new}\`

_opened by the upstream-check workflow - refreshed $(date -u +%Y-%m-%d)_
EOF
)
  if [ "${pinned_ambed}" != "${pinned_xlxd}" ]; then
    body="${body}

**WARNING** : AMBEd (\`${pinned_ambed:0:7}\`) && XLXd (\`${pinned_xlxd:0:7}\`) pins differ - this PR sets both"
  fi
  open_pr xlxd "${upstream:0:7}" "${title}" "${body}" "bump_xlxd ${upstream}"
}

########################
###### s6-overlay ######
########################

check_s6() {
  local upstream_repo=just-containers/s6-overlay
  local pinned_ambed pinned_xlxd pinned latest changelog stop="" v notes title body

  pinned_ambed=$(sed -n 's/^ARG S6_OVERLAY_VERSION=\([^ ]*\).*/\1/p' AMBEd/Dockerfile)
  pinned_xlxd=$(sed -n 's/^ARG S6_OVERLAY_VERSION=\([^ ]*\).*/\1/p' XLXd/Dockerfile)
  pinned=${S6_PINNED_OVERRIDE:-${pinned_xlxd}}
  latest=$(gh api "repos/${upstream_repo}/releases/latest" --jq '.tag_name | ltrimstr("v")')
  if [ -z "${pinned}" ] || [ -z "${latest}" ]; then
    echo "s6-overlay: could not read pinned (${pinned:-none}) or latest (${latest:-none}) version"
    return 1
  fi
  if [ "${pinned}" = "${latest}" ] && [ "${pinned_ambed}" = "${latest}" ]; then
    echo "s6-overlay up to date : pinned ${pinned} == latest release"
    close_stale s6-overlay "" "S6_OVERLAY_VERSION is already ${latest} (latest release) - closing"
    return
  fi

  ## the CHANGELOG entries newer than the pinned version
  ## not every release has a heading, so stop at the first one at or below the pinned version
  changelog=$(curl -fsSL "https://raw.githubusercontent.com/${upstream_repo}/v${latest}/CHANGELOG.md" || true)
  while read -r v; do
    if [ "$(printf '%s\n%s\n' "${v}" "${pinned}" | sort -V | head -1)" = "${v}" ]; then
      stop="### Version ${v}"
      break
    fi
  done < <(sed -n 's/^### Version //p' <<< "${changelog}")
  notes=$(awk -v stop="${stop}" 'stop != "" && $0 == stop {exit} /^### Version /{f=1} f' <<< "${changelog}" | head -80)

  title="s6-overlay: bump ${pinned} -> ${latest}"
  body=$(cat <<EOF
${upstream_repo} has a release newer than the version pinned in the Dockerfiles; this PR sets \`S6_OVERLAY_VERSION\` to it in both.

| | pinned | latest release |
| :-- | :-- | :-- |
| \`AMBEd/Dockerfile\` | ${pinned_ambed} | ${latest} |
| \`XLXd/Dockerfile\` | ${pinned_xlxd} | ${latest} |

[release notes](https://github.com/${upstream_repo}/releases/tag/v${latest})

### CHANGELOG since ${pinned}
${notes:-- could not read the CHANGELOG}

### before / after merging
- [ ] the docker images build check on this branch passed (both images, amd64 + arm64)
- [ ] check the CHANGELOG for moved paths (since 3.2.3.2 the \`user\` bundle lives in \`/etc/s6-overlay/user-bundles.d/user/contents.d\`)
- [ ] merge -> CI publishes \`:test\`
- [ ] run \`:test\` on 005 and check xlxd, httpd and ambed start
- [ ] merge \`testing\` -> \`main\` -> CI publishes \`:latest\`

_opened by the upstream-check workflow - refreshed $(date -u +%Y-%m-%d)_
EOF
)
  if [ "${pinned_ambed}" != "${pinned_xlxd}" ]; then
    body="${body}

**WARNING** : AMBEd (\`${pinned_ambed}\`) && XLXd (\`${pinned_xlxd}\`) pins differ - this PR sets both"
  fi
  open_pr s6-overlay "${latest}" "${title}" "${body}" "bump_s6 ${latest}"
}

## run both, fail the job if either failed
rc=0
check_xlxd || rc=1
echo
check_s6 || rc=1
exit ${rc}
