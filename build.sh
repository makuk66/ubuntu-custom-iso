#!/bin/bash

set -euo pipefail

# See http://askubuntu.com/questions/409607/how-to-create-a-customized-ubuntu-server-iso

VERSION=${1:-16.04.3}
SOURCE="ubuntu-$VERSION-server-amd64.iso"
TARGET="$(echo "$SOURCE" | sed -e 's/server-/server-auto-/')"

if [ ! -f "$SOURCE" ]; then
  URL="http://releases.ubuntu.com/$VERSION/$SOURCE"
  echo "Downloading $URL"
  curl --output "${SOURCE}.tmp" "$URL"
  mv "${SOURCE}.tmp" "$SOURCE"
fi
echo "SOURCE=$SOURCE"
echo "TARGET=$TARGET"

# remove old custom iso
sudo rm -f "$TARGET"

# install pre-requisites
sudo apt-get install syslinux genisoimage

# unmount iso if needed
if [ -d iso ]; then sudo umount iso || true ; fi
sudo rm -fr iso newIso
mkdir -p iso

# mount source image and copy contents
sudo mount -o ro,loop "$SOURCE" iso/
sudo rsync -a iso/ newIso
sudo umount iso
sudo rmdir iso

# new preseed file
sudo cp ubuntu-uk.seed newIso/preseed/
cp bootmenu.cfg newtxt.cfg
egrep -v '^default' newIso/isolinux/txt.cfg >> newtxt.cfg
sudo mv newtxt.cfg newIso/isolinux/txt.cfg
echo en | sudo dd of=newIso/isolinux/lang
sudo cp postinstall.sh newIso/
for f in extra-user-ssh-key extra-user-passwd extra-user-fullname extra-user-username; do sudo cp $f newIso/; done

# re-generate md5sum
# The find will warn 'File system loop detected' and return non-zero exit status on the 'ubuntu' symlink to '.'
# To avoid that, temporarily move it out of the way
sudo mv newIso/ubuntu .
(cd newIso; sudo find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec "$(which md5sum)" {} \; > ../md5sum.txt)
sudo mv md5sum.txt newIso/
sudo mv ubuntu newIso

# build ISO image
sudo mkisofs -r -V "Custom Ubuntu Install CD" \
  -cache-inodes \
  -J -l -b isolinux/isolinux.bin \
  -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -o "$TARGET" newIso/
ls -l "$TARGET"
sudo chown "$USER:$USER" "$TARGET"
isohybrid "$TARGET"

#sleep 300
sudo rm -fr newIso rsync.out

echo "created $TARGET"
