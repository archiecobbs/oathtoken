#!/bin/sh

# Bail on any error
set -e

# Paths
PLB="/usr/libexec/PlistBuddy"
SRC_PLIST="${INFOPLIST_FILE}"
DST_PLIST="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

# Get SVN revision
SVN_REVISION=`svnversion -c . | sed 's/^[0-9]\{1,\}://g'`

# Set version strings
"${PLB}" -c 'Set :SVNRevision "'"${SVN_REVISION}"'"' "${DST_PLIST}"

