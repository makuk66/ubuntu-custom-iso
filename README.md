Create a custom installer with preseed, with UK choices and some credentials.
I use this to re-image my test cluster machines.
See https://help.ubuntu.com/community/InstallCDCustomization

This setup creates an "ubuntu" user, and an extra user.

## To create the ISO, on Ubuntu Linux:

```
# for mkpasswd:
apt-get --yes install whois

echo $USER > extra-user-username
echo "Martijn Koster" > extra-user-fullname
(printf "$USER:"; stty -echo; mkpasswd --stdin --method=sha-512; stty echo) > extra-user-passwd
cp ~/.ssh/id_dsa.pub extra-user-ssh-key
cp ubuntu-uk.seed.template ubuntu-uk.seed
password=$(<extra-user-passwd)
sed -i \
  -e 's,^\(d-i passwd/user-password-crypted password\).*,\1 '"$password," \
  -e 's,^\(d-i passwd/root-password-crypted password\).*,\1 '"$password," \
  ubuntu-uk.seed
sudo id
./build.sh
rm extra-user-passwd ubuntu-uk.seed
```

## To write the resulting ISO to a USB stick on OSX

```
scp ubuntu-16.04-server-auto-amd64.iso mak@crab.lan:ISO/
```
```
diskutil list
diskutil unmountDisk /dev/disk4
diskutil list
# check that disk is the one you intend to overwrite
sudo dd if=/Users/mak/ISO/ubuntu-16.04-server-auto-amd64.iso of=/dev/rdisk4 bs=1m
diskutil eject /dev/disk4
```

## Ideas for improvement

- ensure all packages are available on-disk, make internet connectivity optional
- rather than using a USB stick, I could run the installer from another partition,
  but that would require some custom partitioning.
- it might be quicker/easier to backup/restore rather than install (be it from USB or disk).
