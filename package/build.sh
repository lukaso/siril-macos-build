#!/bin/sh

# set -e

if [ -z "${JHBUILD_LIBDIR}" ]
then
  echo "JHBUILD_LIBDIR undefined. Are you running inside jhbuild?"
  exit 2
fi

#FIXME: ugly patch to restore correct path lib (cfitsio and wcslib)
install_name_tool -change libwcs.7.3.1.dylib /Users/distiller/gtk/inst/lib/libwcs.7.dylib  /Users/distiller/gtk/inst/bin/siril
install_name_tool -change libwcs.7.3.1.dylib /Users/distiller/gtk/inst/lib/libwcs.7.dylib  /Users/distiller/gtk/inst/bin/siril-cli
install_name_tool -change @rpath/libcfitsio.9.dylib /Users/distiller/gtk/inst/lib/libcfitsio.9.dylib  /Users/distiller/gtk/inst/bin/siril
install_name_tool -change @rpath/libcfitsio.9.dylib /Users/distiller/gtk/inst/lib/libcfitsio.9.dylib  /Users/distiller/gtk/inst/bin/siril-cli

printf "Determining SIRIL version: "

rm -f SIRIL_VERSION

SIRIL_VERSION="$(siril --version | awk '{print $2}')"

echo "$SIRIL_VERSION"

# cat info-2.10.plist.tmpl | sed "s|%VERSION%|${SIRIL_VERSION}|g" > info-2.10.plist

echo "Copying charset.alias"
cp "/usr/lib/charset.alias" "${HOME}/gtk/inst/lib/"
echo "Creating bundle"

cd "${HOME}/gtk/source/siril/platform-specific/os-x/"
gtk-mac-bundler siril.bundle

cd "${HOME}/project/package"

BASEDIR=$(dirname "$0")

#  target directory
PACKAGE_DIR="${HOME}/Desktop"

echo "Signing libs"

if [ -n "${codesign_subject}" ]
then
  echo "Signing libraries and plugins"
  find  ${PACKAGE_DIR}/SiriL.app/Contents/Resources/lib/ -type f -perm +111 \
     | xargs file \
     | grep ' Mach-O '|awk -F ':' '{print $1}' \
     | xargs /usr/bin/codesign -s "${codesign_subject}" \
         --options runtime \
         --entitlements ${HOME}/project/package/siril-hardening.entitlements
  echo "Signing app"
  /usr/bin/codesign -s "${codesign_subject}" \
    --timestamp \
    --deep \
    --options runtime \
    --entitlements ${HOME}/project/package/siril-hardening.entitlements \
    ${PACKAGE_DIR}/SiriL.app
fi

echo "Building DMG"
if [ -z "${CIRCLECI}" ]
then
  DMGNAME="siril-${SIRIL_VERSION}-x86_64.dmg"
else
  DMGNAME="siril-${SIRIL_VERSION}-x86_64-b${CIRCLE_BUILD_NUM}-${CIRCLE_BRANCH}.dmg"
fi

mkdir -p /tmp/artifacts/
rm -f /tmp/tmp.dmg
rm -f "siril-${SIRIL_VERSION}-x86_64.dmg"

cd create-dmg

./create-dmg \
  --volname "SiriL Install" \
  --background "${HOME}/gtk/source/siril/platform-specific/os-x/siril-dmg.png" \
  --window-pos 1 1 \
  --icon "SiriL.app" 190 360 \
  --window-size 640 480 \
  --icon-size 110 \
  --icon "Applications" 110 110 \
  --hide-extension "Applications" \
  --app-drop-link 450 360 \
  --format UDBZ \
  --hdiutil-verbose \
  "/tmp/artifacts/${DMGNAME}" \
  "$PACKAGE_DIR/"
rm -f /tmp/artifacts/rw.*.dmg
cd ..

if [ -n "${codesign_subject}" ]
then
  echo "Signing DMG"
  /usr/bin/codesign  -s "${codesign_subject}" "/tmp/artifacts/${DMGNAME}"
fi

echo "Done"
