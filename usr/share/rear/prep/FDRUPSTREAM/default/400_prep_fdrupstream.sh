#
# prepare stuff for FDRUPSTREAM
#

COPY_AS_IS=( "${COPY_AS_IS[@]}" "${COPY_AS_IS_FDRUPSTREAM[@]}" "${FDRUPSTREAM_INSTALL_PATH}" )
COPY_AS_IS_EXCLUDE=( "${COPY_AS_IS_EXCLUDE[@]}" "${COPY_AS_IS_EXCLUDE_FDRUPSTREAM[@]}" )
PROGS=( "${PROGS[@]}" "${PROGS_FDRUPSTREAM[@]}" col )
REQUIRED_PROGS=( "${REQUIRED_PROGS[@]}" "${REQUIRED_PROGS_FDRUPSTREAM[@]}" col )

# If FDRUPSTREAM_RESTORE_PROFILE is set, verify it contains a legit profile name:
if [ ${#FDRUPSTREAM_RESTORE_PROFILE} -gt 8 ]; then
	# invalid profile
	LogPrintError "FDRUPSTREAM_RESTORE_PROFILE contains too many characters and is invalid"
	LogPrintError "Please correct and retry."
	Error exit 1
fi
