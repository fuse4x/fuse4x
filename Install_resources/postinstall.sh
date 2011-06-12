#!/bin/sh

KEXT_ID=org.fuse4x.kext.fuse4x

kextstat -b $KEXT_ID | grep $KEXT_ID

if [ $? -eq 0 ] ; then
	# TODO: Use lsvfs to find number of fuse4x filesystems in use. If the
	# number is 0 then we can safely unload the kext

	# kext is loaded - let's unload it
	kextunload -b $KEXT_ID;

	if [ $? -ne 0 ] ; then
		osascript <<-END
		    say "Older version of Fuse4X in use. Please restart your computer to use the new version."
		END
	fi
fi
