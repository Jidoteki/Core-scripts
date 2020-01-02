#!/bin/busybox ash
# (c) Robert Shingledecker 2003-2012
# Called from tc-config
# A non-interactive script to restore configs, directories, etc defined by the user
# in the file .filetool.lst
. /etc/init.d/tc-functions
useBusybox

# wait up to 5 minutes for disks to settle
/sbin/udevadm settle --timeout=300

# generate symlinks for Amazon/Xen: sdb -> xvdb
all_disks="a b c d e f g h i j k l m n o p"
for i in $all_disks; do
	if [ -b "/dev/xvd${i}" ]; then
		ln -svf /dev/xvd${i} /dev/sd${i} >>/tmp/symlinktool_xvd.msg 2>&1 || true
		ln -svf /dev/xvd${i}1 /dev/sd${i}1 >>/tmp/symlinktool_xvd.msg 2>&1 || true
	fi
done

# backward compat for Amazon systems where xvda1 doesn't exist
if dmesg | grep -qw amazon; then
  if ! dmesg | grep -qw xvda1; then
    rm /dev/sda1 && \
    ln -svf /dev/xvda /dev/sda1 >>/tmp/symlinktool_xvd.msg 2>&1 || true
  fi
fi

TCE="$1"
DEVICE=""
MYDATA=mydata
[ -r /etc/sysconfig/mydata ] && read MYDATA < /etc/sysconfig/mydata
for i in `cat /proc/cmdline`; do
	case $i in
		*=*)
			case $i in
				restore*)
					RESTORE=1
					DEVICE=${i#*=}
				;;
			esac
		;;
		*)
			case $i in
				restore) RESTORE=1 ;;
				protect) PROTECT=1 ;;
				symlinksnorestore) SYMLINKSNORESTORE=1 ;;
			esac
		;;
	esac
done

if [ -n "$PROTECT" ]; then
	# Check if backup file is in TCE directory
	if [ -d "$TCE" ] && [ -f "$TCE"/"$MYDATA".tgz.bfe ]; then
		DEVICE="$(echo $TCE|cut -f3- -d/)"
	fi
	if [ -z "$DEVICE" ]; then
		DEVICE=`autoscan "$MYDATA".tgz.bfe 'f'`
	fi
	if [ -n "$DEVICE" ]; then
		if [ -n "$SYMLINKSNORESTORE" ]; then
			/usr/bin/filetool.sh -r "$DEVICE"
		else
			/usr/bin/symlinktool.sh -r "$DEVICE"
		fi
		exit 0
	fi
fi

# Check if backup file is in TCE directory
if [ -d "$TCE" ] && [ -f "$TCE"/"$MYDATA".tgz ]; then
	TCEDIR="$(echo $TCE|cut -f3- -d/)"
fi

if [ -z "$DEVICE" ]; then
	if [ -n "$TCEDIR" ]; then
		DEVICE="$TCEDIR"
	else
		DEVICE=`autoscan "$MYDATA".tgz 'f'`
	fi
fi

if [ -n "$DEVICE" ]; then
	if [ -n "$SYMLINKSNORESTORE" ]; then
		/usr/bin/filetool.sh -r "$DEVICE"
	else
		/usr/bin/symlinktool.sh -r "$DEVICE"
	fi
	exit 0
fi

# Nothing found, set default backup location
# use persistent TCE directory
if [ "${TCE:0:8}" != "/tmp/tce" ]; then
	DEVICE="${TCE#/mnt/}"
	echo "$DEVICE" > /etc/sysconfig/backup_device
fi
