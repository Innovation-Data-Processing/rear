#!/bin/bash

create_dat_file () {
	local tmpdir="/tmp/fdrupstream/rear"
	if [ ! -d $tmpdir ]; then
		mkdir -p $tmpdir
	else
		rm -rf $tmpdir/*
	fi

	DATFILE=$tmpdir/rear.dat
	cat << EOT > "$DATFILE"
ACTION 0
ATTENDED N
LATESTVERSION Y 
USERID $fdru
PASSWORD $fdrp
EOT
}

run_restore () {
	local command="$FDRUPSTREAM_INSTALL_PATH/uscmd PARAMETER=$DATFILE CONFIGFILE=$CONFIGFILE BACKUPPROFILE=$BACKUPPROFILE FILES=$FILES DESTINATION=$DESTINATION"
	UserOutput ""
	LogUserOutput "Now running:"
	LogUserOutput "$command"
	UserOutput ""
	$command
	LogPrintIfError "The above restore exited with return code $?."
}

wait_for_restore () {
	LogUserOutput ""
	LogUserOutput "    Perform your restore now using Director, Web Portal, or USTBATCH."
	LogUserOutput ""    
	LogUserOutput "    IMPORTANT: Restore the entire '/' filesystem to '$TARGET_FS_ROOT/'"
	LogUserOutput "    on the recovery system."
	LogUserOutput "    When the restore is complete, then hit <enter> here."
	# Use the original STDIN STDOUT and STDERR when 'rear' was launched by the user
	# because 'read' outputs non-error stuff also to STDERR (e.g. its prompt):
	read 0<&6 1>&7 2>&8
}

# Get kernel parameters, if they exist
local fdru=$(grep -Po 'fdru=\K[^"][^\s]*' /proc/cmdline)
local fdrp=$(grep -Po 'fdrp=\K[^"][^\s]*' /proc/cmdline)
local fdrprofile=$(grep -Po 'fdrprofile=\K[^"][^\s]*' /proc/cmdline)

# Set FDRUPSTREAM_RESTORE_PROFILE from kernel parameter, if it exists:
if [ ! -z $fdrprofile ]; then
	FDRUPSTREAM_RESTORE_PROFILE=$fdrprofile
fi

# Check that FDRUPSTREAM_RESTORE_PROFILE is 8 or fewer characters:
if [ ${#FDRUPSTREAM_RESTORE_PROFILE} -gt 8 ]; then
        # invalid profile
        LogPrinterror "FDRUPSTREAM_RESTORE_PROFILE is invalid."
	LogPrinterror "A manual restore will be required."
	wait_for_restore
fi

# If FDRUPSTREAM_RESTORE_PROFILE is not set, then user must perform the restore manually:
if [ -z $FDRUPSTREAM_RESTORE_PROFILE ]; then
	LogPrint "FDRUPSTREAM_RESTORE_PROFILE is empty, so a manual restore is required."
	wait_for_restore
# Else give user the option of automatic or manual restore:
else
	local timeout=30
	# Have that timeout not bigger than USER_INPUT_TIMEOUT
	# e.g. for automated testing a small USER_INPUT_TIMEOUT may be specified and
	# we do not want to delay it here more than what USER_INPUT_TIMEOUT specifies:
	test "$timeout" -gt "$USER_INPUT_TIMEOUT" && timeout="$USER_INPUT_TIMEOUT"
	
	LogUserOutput ""
	LogUserOutput "    Ready for an FDR/Upstream restore"
	LogUserOutput ""
	LogUserOutput "Choose an option:"
	LogUserOutput "1)  Automatically restore the latest version date of profile $FDRUPSTREAM_RESTORE_PROFILE"
	LogUserOutput "2)  Manually perform your restore with Director, Web Portal, or USTBATCH"
	LogUserOutput ""
	
	local prompt="Please enter 1 or 2"
	local input_value=""
	local wilful_input=""
	input_value="$( UserInput -I CHOICE -t "$timeout" -p "$prompt" -D '1' )" && wilful_input="yes" || wilful_input="no"
	if is_true "$input_value" ; then
		is_true "$wilful_input" && LogPrint "User confirmed to proceed with automatic restore" || LogPrint "Proceeding with automatic restore by default"
	else
		# The user enforced MIGRATION_MODE uses the special 'TRUE' value in upper case letters
		# that is needed to overrule the prepare/default/270_overrule_migration_mode.sh script:
		MIGRATION_MODE='TRUE'
		LogUserOutput ""
		LogPrint "User will perform restore manually"
	fi

	case $input_value in
		1)
			INIFILE=/etc/opt/fdrupstream/fdrupstream.ini
			CONFIGFILE=$(grep -m 1 configfile $INIFILE | grep -Po 'configfile=\K[^"]+')
			BACKUPPROFILE=$FDRUPSTREAM_RESTORE_PROFILE
			FILES='/'
			DESTINATION=$TARGET_FS_ROOT/
			create_dat_file
			run_restore
			;;
		2)
			wait_for_restore;;
	esac
fi
