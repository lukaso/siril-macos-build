echo "*** REMOVE brew"
PATH=$(echo "$PATH" | sed -e 's/\/usr\/local\/bin://')


cd $HOME
mkdir -p ~/.config && cp ~/project/jhbuildrc-gtk-osx-gimp-2.99 ~/.config/jhbuildrc-custom
curl https://gitlab.gnome.org/samm-git/gtk-osx/raw/gimp/gtk-osx-setup.sh > gtk-osx-setup.sh
chmod +x gtk-osx-setup.sh
echo 'export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH:$HOME/.new_local/bin"' >> ~/.profile
echo 'export ARCHFLAGS="-arch x86_64"' >> ~/.profile
# PYTHON variable seems to be incorrectly set
echo 'export PYTHON=/Library/Frameworks/Python.framework/Versions/3.9/bin/python3' >> ~/.profile
# Unclear why this is needed, but if missing, jhbuild fails in some circumstances
echo 'export PYENV_VERSION="3.9.7"' >> ~/.profile
source ~/.profile
PIPENV_YES=1 ./gtk-osx-setup.sh
$HOME/.new_local/bin/jhbuild bootstrap-gtk-osx-gimp
cat ~/.profile

cd ~/Source
git clone https://gitlab.gnome.org/lukaso/gtk-mac-bundler
cd gtk-mac-bundler
make install

source ~/.profile && jhbuild build icu libnsgif meta-gtk-osx-freetype meta-gtk-osx-bootstrap meta-gtk-osx-gtk3
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

source ~/.profile && jhbuild build $(jhbuild info siril|grep '^Requires:'|sed -e 's|^Requires:||' -e 's|gegl||'|tr -d ',')
find  ~/gtk/source -type d -mindepth 1 -maxdepth 1 | xargs -I% rm -rf %/*

source ~/.profile
jhbuild build siril

#        - run:
#            name: Importing signing certificate
#            command: |
#              mkdir ${HOME}/codesign && cd ${HOME}/codesign
#              echo "$osx_crt" | base64 -D > gnome.pfx
#              curl 'https://developer.apple.com/certificationauthority/AppleWWDRCA.cer' > apple.cer
##              security create-keychain -p "" signchain
#              security set-keychain-settings signchain
#              security unlock-keychain -u signchain
#              security list-keychains  -s "${HOME}/Library/Keychains/signchain-db" "${HOME}/Library/Keychains/login.keychain-db"
#              security import apple.cer -k signchain  -T /usr/bin/codesign
#              security import gnome.pfx  -k signchain -P "$osx_crt_pw" -T /usr/bin/codesign
#              security set-key-partition-list -S apple-tool:,apple: -k "" signchain
#              rm -rf ${HOME}/codesign

source ~/.profile
cd ${HOME}/project/package
jhbuild run ./build.sh

