#
#  s390 zIPL boot loader and grubby for configuring boot loader`

test -d $VAR_DIR/recovery || mkdir -p $VAR_DIR/recovery

local bootdir="$( echo -n /boot/ )"
test -d "$bootdir" || $bootdir='/boot/'

# cf. https://github.com/rear/rear/issues/2137
# findmnt is used the same as grub-probe to find the device where /boot is mounted
# example
# findmnt -no SOURCE --target /boot
# --> /dev/dasda1
#
# on sles:
#   findmnt returns --> /dev/dasda3[/@/.snapshots/1/snapshot]
#   use 300_include_grub_tools.sh instead of this file (grub2-probe)
if has_binary findmnt ; then
    findmnt -no SOURCE --target $bootdir >$VAR_DIR/recovery/bootdisk || return 0
fi

# Missing programs in the PROGS array are ignored:
# zipl and grubby are  added in conf/Linux-s390x.conf
PROGS=( "${PROGS[@]}" findmnt )

COPY_AS_IS=( "${COPY_AS_IS[@]}" /etc/zipl.conf )

