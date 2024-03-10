#!/bin/bash
#
# changed_templates.sh

set -e

tip="$(git rev-list -1 --parents HEAD)"
case "$tip" in
	# This is a merge commit, pick last parent
	*" "*" "*) tip="${tip##* }" ;;
	# This is a non-merge commit, pick itself
	*)         tip="${tip%% *}" ;;
esac

base="$(git merge-base upstream/master $tip)"

[ $(git rev-list --count "$tip" "^$base") -lt 200 ] || {
	echo "::error title=Branch out of date::Your branch is too out of date. Please rebase on upstream and force-push."
	exit 1
}

echo "$base $tip" >/tmp/revisions

git diff-tree -r --no-renames --name-only --diff-filter=AM \
	"$base" "$tip" \
	-- 'srcpkgs/*/template' |
	cut -d/ -f 2 |
	xargs ./xbps-src sort-dependencies |
	tee /tmp/templates |
	sed "s/^/  /" >&2

if [ -f ".github-actions-exclude.txt" ]; then
   grep -vf .github-actions-exclude.txt /tmp/templates > /tmp/excluded-templates
else
   cat /tmp/templates > /tmp/excluded-templates
fi

if [ -f ".github-actions-include.txt" ]; then
   cat /tmp/excluded-templates ./.github-actions-include.txt > /tmp/templates
else
   cat /tmp/excluded-templates > /tmp/templates
fi

/bin/echo -e '\x1b[32mChanged packages:\x1b[0m'
cat /tmp/templates
