#!/bin/bash
set -eo pipefail

if [[ -z "$SVN_USERNAME" ]]; then
	echo "Set the SVN_USERNAME secret"
	exit 1
fi

if [[ -z "$SVN_PASSWORD" ]]; then
	echo "Set the SVN_PASSWORD secret"
	exit 1
fi

if [[ -z "$PLUGIN_VERSION" ]]; then
	echo "Set the PLUGIN_VERSION env var"
	exit 1
fi

echo "Publish version: ${PLUGIN_VERSION}"

ELEMENTOR_PATH="$GITHUB_WORKSPACE/elementor"
SVN_PATH="$GITHUB_WORKSPACE/svn"

cd $ELEMENTOR_PATH
mkdir -p $SVN_PATH
cd $SVN_PATH
svn co https://plugins.svn.wordpress.org/elementor/trunk
rm -rf trunk/*
rsync -ah --progress $ELEMENTOR_PATH/* $SVN_PATH/trunk

echo "Preparing files"
cd $SVN_PATH/trunk
svn status | grep -v '^.[ \t]*\\..*' | grep '^!' | awk '{print $2}' | xargs svn delete;
svn status | grep -v '^.[ \t]*\\..*' | grep '^?' | awk '{print $2}' | xargs svn add;
svn status

echo "Commit files to trunk"
svn ci -m "Upload v${PLUGIN_VERSION}" --no-auth-cache --non-interactive  --username "$SVN_USERNAME" --password "$SVN_PASSWORD"

echo "Copy files from trunk to tag ${PLUGIN_VERSION}"
svn cp https://plugins.svn.wordpress.org/elementor/trunk https://plugins.svn.wordpress.org/elementor/tags/${PLUGIN_VERSION} --message "Tagged ${PLUGIN_VERSION}" --no-auth-cache --non-interactive  --username "$SVN_USERNAME" --password "$SVN_PASSWORD"
svn update
