
scheme=$(url_scheme "$BACKUP_URL")
case $scheme in
    (local|nfs)
        :
        ;;
    (*)
        return
        ;;
esac

# Detect all backups in the specified location
backups=()
backup_times=()
for backup in $BUILD_DIR/outputfs/$HOSTNAME/????-??-?? ;do
    Debug "RBME backup $backup detected."
    backups=( "${backups[@]}" ${backup##*/} )
done

# The user has to choose the backup
LogPrint "Select a backup to restore."
select choice in "${backups[@]}" "Abort"; do
    [ "$choice" != "Abort" ]
    StopIfError "User chose to abort recovery."
    n=( $REPLY ) # trim blanks from reply
    let n-- # because bash arrays count from 0
    if [ "$n" -lt 0 ] || [ "$n" -ge "${#backups[@]}" ] ; then
        LogPrint "Invalid choice $REPLY, please try again or abort."
        continue
    fi
    LogPrint "Backup ${backups[$n]} chosen."
    RBME_BACKUP=${backups[$n]}
    break
done 2>&1
