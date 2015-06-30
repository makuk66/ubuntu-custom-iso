#!/bin/bash

# See http://askubuntu.com/questions/409607/how-to-create-a-customized-ubuntu-server-iso

export SOURCE=ubuntu-14.04.2-server-amd64.iso
export TARGET=$(echo "$SOURCE" | sed -e 's/server-/server-auto-/')

if [ ! -f $SOURCE ]; then
  echo missing $SOURCE
  exit 1
fi
echo SOURCE=$SOURCE
echo TARGET=$TARGET

# remove old custom iso
sudo rm -f $TARGET

# install pre-requisites
sudo apt-get install syslinux genisoimage

# unmount iso if needed
if [ -d iso ]; then sudo umount iso || true ; fi
sudo rm -fr iso newIso
mkdir -p iso

# mount source image and copy contents
sudo mount -o ro,loop $SOURCE iso/
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
(cd newIso; sudo find '!' -name "md5sum.txt" '!' -path "./isolinux/*" -follow -type f -exec `which md5sum` {} \; > ../md5sum.txt)
sudo mv md5sum.txt newIso/

# build ISO image
sudo mkisofs -r -V "Custom Ubuntu Install CD" \
  -cache-inodes \
  -J -l -b isolinux/isolinux.bin \
  -c isolinux/boot.cat -no-emul-boot \
  -boot-load-size 4 -boot-info-table \
  -o $TARGET newIso/
ls -l $TARGET
sudo chown $USER:$USER $TARGET
isohybrid $TARGET

#sleep 300
sudo rm -fr newIso rsync.out

echo created $TARGET
