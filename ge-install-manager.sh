#!/usr/bin/env sh
###############################################################################
#                                                                             #
#      Toazd 2020 Unlicense https://unlicense.org/                            #
#                                                                             #
#      GloriousEggroll installation manager                                   #
#       Manage proton-ge-custom installations                                 #
#       https://github.com/GloriousEggroll/proton-ge-custom                   #
#                                                                             #
#      NOTE shellcheck should be invoked with the -x parameter                #
#      "-x, --external-sources                                                #
#        Follow source statements even when the file is not specified         #
#        as input.  By default, shellcheck will only follow files             #
#        specified on the command line (plus /dev/null). This                 #
#        option allows following any file the script may source."             #
#                                                                             #
###############################################################################

set +e # WARNING DO NOT set -e

###############################################################################
sSCRIPT_VER="0.6.4 \"Intrepid voyager\""                                      #
#                                             ________                        #
#                                   __.------'--------`---.___                #
#                              _.--'  _.-' /==================`--.___         #
#                         __.-'     .'    /                          `--._    #
#         .--------------' --------'=======================================   #
#   ___.-'-----------..__                 .'`-._________.---------'           #
#  '--|  ==========<=|| [`.______________/                                    #
#      `-------------'`---'             /                                     #
#                 `._____              /                                      #
#                        `------------'                                       #
#                                                                             #
###############################################################################

sGE_INSTALL_PATH="$HOME"/.steam/root/compatibilitytools.d
sSTEAM_PID="$HOME"/.steam/steam.pid
sGE_DOWNLOAD_BASE_URL="https://github.com/GloriousEggroll/proton-ge-custom/releases/download"
sGE_LATEST_VERSION_URL="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"
sHELP=""
sUSAGE=""
iFORCE=0
iDEBUG=0
iDOWNLOAD=0
iINSTALL=0
iREMOVE=0
iUPDATE=0
iFINAL_CLEANUP=0
iREMOVE_INSTALL_PATH=0
iREMOVE_SAVED_PACKAGES=0
iLIST_INSTALLED_GE_VERSIONS=0
iREPORT_USAGE=0
iSHOW_HELP=0
iSHOW_USAGE=0

###############################################################################

ShowHelp() {

    if [ -z "$sHELP" ] && [ -z "$sUSAGE" ]; then
        . ./README.sh
    fi
    printf "%s" "$sHELP"

    return 0
}

###############################################################################

ShowUsage() {

    if [ -z "$sHELP" ] && [ -z "$sUSAGE" ]; then
        . ./README.sh
    fi
    printf "%s" "$sUSAGE"

    return 0
}

###############################################################################

GetLatestGEVersionInfo() {

    sGE_RELEASE_HTML=$(curl -sz "$sGE_INSTALL_PATH/latest" -L "$sGE_LATEST_VERSION_URL" -o -)

    [ "$iDEBUG" = 1 ] && echo "Latest release URL: $sGE_LATEST_VERSION_URL"

    # if curl returned NULL (remote file not newer) fill the var with the contents of the saved file 'latest'
    if [ -z "$sGE_RELEASE_HTML" ]; then
        [ "$iDEBUG" = 1 ] && echo "Remote file not newer, using saved ${sGE_INSTALL_PATH}/latest"
        if [ ! -f "${sGE_INSTALL_PATH}/latest" ]; then
            printf "%s\n%sn" "Server return NULL and no saved release information found in $sGE_INSTALL_PATH" "Is $sGE_LATEST_VERSION_URL valid?"
            return 1
        else
            sGE_RELEASE_HTML=$(cat "${sGE_INSTALL_PATH}/latest" 2>/dev/null)
        fi
    elif [ -n "$sGE_RELEASE_HTML" ]; then
        # TODO if new version is recevied, show release info from html file?
        [ "$iDEBUG" = 1 ] && echo "Saving latest release information to ${sGE_INSTALL_PATH}/latest"
        printf "%s" "$sGE_RELEASE_HTML" > "${sGE_INSTALL_PATH}/latest"
    fi

    # TODO check hash and/or length / might need a config file
    [ -z "$sGE_RELEASE_HTML" ] && {
        printf "%s\n%s\n" "Local saved release information NULL or corrupt" "Release information not available"
        return 1
    }

    # Get the latest release from the html
    sGE_LATEST_VERSION=${sGE_RELEASE_HTML#*"\"tag_name\": \""}
    sGE_LATEST_VERSION=${sGE_LATEST_VERSION%%"\","*}

    #if IsInstalled "$sGE_LATEST_VERSION"; then
    #    echo "Latest version: $sGE_LATEST_VERSION (installed)"
    #else
    #    echo "Latest version: $sGE_LATEST_VERSION (not installed)"
    #fi

    # Get the download url from the release file html
    #sGE_DOWNLOAD_BASE_URL=${sGE_RELEASE_HTML#*"\"browser_download_url\": \""}
    #sGE_LATEST_VERSION_DOWNLOAD_URL=${sGE_LATEST_VERSION_DOWNLOAD_URL%%"\""*}

    # if name is used instead of tag_name
    #echo "Package URL: $sGE_LATEST_VERSION_DOWNLOAD_URL"
    #sGE_VERSION=$(CleanUpVersion "$sGE_VERSION")

    return 0
}

###############################################################################

DownloadGEPackage() {

    sTMP_DIR=$(mktemp -qd --tmpdir "$(basename "$0" .sh).tmp.XXXXXXXXXX")
    sTMP_PACKAGE=${sTMP_DIR}/Proton-${sDOWNLOAD_VERSION}.tar.gz
    sGE_DOWNLOAD_URL=${sGE_DOWNLOAD_BASE_URL}/${sDOWNLOAD_VERSION}/Proton-${sDOWNLOAD_VERSION}.tar.gz
    sSIZE_BYTES=""

    echo "Downloading $sGE_DOWNLOAD_URL"
    if curl -# -L "$sGE_DOWNLOAD_URL" -o "$sTMP_PACKAGE"; then
        sSIZE_BYTES=$(stat -c "%s" "$sTMP_PACKAGE")
        [ "$iDEBUG" = 1 ] && echo "Package size in bytes: $sSIZE_BYTES"
        if [ "$sSIZE_BYTES" = 9 ] && [ "$(cat "$sTMP_PACKAGE" 2>/dev/null)" = "Not Found" ]; then
            echo "Package not found"
            CleanUp
            return 1
        fi
        [ "$iDEBUG" = 1 ] && echo "Copying package $sTMP_PACKAGE to $sGE_INSTALL_PATH"
        if cp "$sTMP_PACKAGE" "$sGE_INSTALL_PATH"; then
            [ "$iDEBUG" = 1 ] && echo "Package copied successfully"
            echo "Download succeeded"
            CleanUp
        else
            [ "$iDEBUG" = 1 ] && echo "Copy package $sTMP_PACKAGE to $sGE_INSTALL_PATH failed"
            echo "Download failed"
            CleanUp
            return 1
        fi
    else
        echo "Download failed"
        CleanUp
        return 1
    fi

    return 0
}

###############################################################################

InstallGEVersion() {

    if [ "$iUPDATE" = 1 ]; then
        sVERSION=$sGE_LATEST_VERSION
    elif [ "$iUPDATE" = 0 ]; then
        sVERSION=$sINSTALL_VERSION
    fi

    if IsInstalled "$sVERSION"; then
        if [ "$iFORCE" = 0 ]; then
            echo "Install: $sVERSION already installed"
            return 0
        elif [ "$iFORCE" = 1 ]; then
            if IsSteamRunning; then
                echo "Please close steam before installing a version that is already installed"
                return 1
            else
                echo "Install: Forcing re-install of version $sVERSION"
            fi
        fi
    fi

    # if a saved package exists and -f is not included
    if [ -f "${sGE_INSTALL_PATH}/Proton-${sVERSION}.tar.gz" ] && [ "$iFORCE" = 0 ]; then
        echo "Using saved package: ${sGE_INSTALL_PATH}/Proton-${sVERSION}.tar.gz"
        sEXTRACT_PACKAGE_VERSION=$sVERSION
        if ExtractGEPackage; then
            return 0
        else
            return 1
        fi
    # if a saved package exists and -f is included
    # NOTE doesn't matter if steam is running
    elif [ -f "${sGE_INSTALL_PATH}/Proton-${sVERSION}.tar.gz" ] && [ "$iFORCE" = 1 ]; then
        echo "Removing saved package ${sGE_INSTALL_PATH}/Proton-${sVERSION}.tar.gz"
        if rm -f "${sGE_INSTALL_PATH}/Proton-${sVERSION}.tar.gz"; then
            echo "Package ${sGE_INSTALL_PATH}/Proton-${sVERSION}.tar.gz removed"
        else
            echo "Removing package ${sGE_INSTALL_PATH}/Proton-${sVERSION}.tar.gz failed"
            return 1
        fi
    fi

    # If a saved package for this version doesn't exist or was removed, download it and install it
    sDOWNLOAD_VERSION=$sVERSION
    if DownloadGEPackage; then
        sEXTRACT_PACKAGE_VERSION=$sVERSION
        if ExtractGEPackage; then
            return 0
        else
            return 1
        fi
    else
        return 1
    fi

    return 0
}

###############################################################################

RemoveGEVersion() {

    sREMOVE_PATH=${sGE_INSTALL_PATH}/Proton-${sREMOVE_VERSION}
    iFAILED=0

    # remove installed path
    if [ -z "$sREMOVE_PACKAGE" ]; then
        if [ -d "$sREMOVE_PATH" ]; then
            [ "$iDEBUG" = 1 ] && echo "Removing $sREMOVE_PATH"
            if IsSteamRunning && IsInstalled "$sREMOVE_VERSION"; then
                echo "Please close steam before removing a version"
            else
                if rm -rf "$sREMOVE_PATH"; then
                    echo "Removed version $sREMOVE_VERSION"
                else
                    echo "Removal of \"$sREMOVE_PATH\" failed"
                    iFAILED=1
                fi
            fi
        else
            if [ "$iFORCE" = 0 ]; then
                echo "Version not found at: \"$sREMOVE_PATH\""
                iFAILED=1
            fi
        fi
    # remove saved package
    # NOTE doesn't matter if steam is installed
    elif [ -n "$sREMOVE_PACKAGE" ]; then
        if [ -f "$sGE_INSTALL_PATH/Proton-${sREMOVE_VERSION}.tar.gz" ]; then
            if rm -f "$sGE_INSTALL_PATH/Proton-${sREMOVE_VERSION}.tar.gz"; then
                echo "Package $sGE_INSTALL_PATH/Proton-${sREMOVE_VERSION}.tar.gz removed"
            else
                echo "Failed to remove package $sGE_INSTALL_PATH/Proton-${sREMOVE_VERSION}.tar.gz"
                iFAILED=1
            fi
        fi
    fi

    [ "$iFAILED" = 1 ] && return 1 || return 0
}

###############################################################################

ExtractGEPackage() {

    printf "%s" "Extracting"
    if tar --checkpoint=.1000 -C "$sGE_INSTALL_PATH" -xzf "${sGE_INSTALL_PATH}/Proton-${sEXTRACT_PACKAGE_VERSION}.tar.gz" 2>/dev/null; then
        printf "\n%s\n" "Package extraction successful"
        return 0
    else
        printf "\n%s\n" "Package extraction failed"
        [ -d "${sGE_INSTALL_PATH}/Proton-${sEXTRACT_PACKAGE_VERSION}" ] && {
            [ "$iDEBUG" = 1 ] && echo "Removing failed extraction path ${sGE_INSTALL_PATH}/Proton-${sEXTRACT_PACKAGE_VERSION}"
            [ -d "${sGE_INSTALL_PATH}/Proton-${sEXTRACT_PACKAGE_VERSION}" ] && {
                if ! rm -rf "${sGE_INSTALL_PATH}/Proton-${sEXTRACT_PACKAGE_VERSION}"; then
                    echo "Failed to remove partial extraction path at: ${sGE_INSTALL_PATH}/Proton-${sEXTRACT_PACKAGE_VERSION}"
                    # TODO update/remove message if install verification is updated
                    echo "Manual removal is required or this script may interpret it as a valid install"
                else
                    [ "$iDEBUG" = 1 ] && echo "Removal succeeded"
                fi
            }
        }
        return 1
    fi

    return 0
}

###############################################################################

# TODO better verification
ListInstalledGEVersions() {

    iCOUNT=0
    sNODE=""

    [ "$iDEBUG" = 1 ] && echo "Install path: $sGE_INSTALL_PATH"

    echo "Installed version(s):"
    for sNODE in "$sGE_INSTALL_PATH"/*; do
        if [ -d "$sNODE" ]; then
            sVERSION=$(cat "$sNODE"/version 2>/dev/null)
            sVERSION=${sVERSION#*[[:blank:]]}
            if [ -z "$sVERSION" ] || [ "$sVERSION" = "file not found" ]; then sVERSION="error: version file not found"; fi
            echo "  ${sNODE##*/} ($sVERSION)"
            iCOUNT=$(( iCOUNT + 1 ))
        fi
    done
    [ "$iCOUNT" -eq 0 ] && echo "None found"

    echo "Saved packages:"
    for sNODE in "$sGE_INSTALL_PATH"/Proton-*.tar.gz; do
        if [ -f "$sNODE" ]; then
            echo "  ${sNODE##*/}"
            iCOUNT=$(( iCOUNT + 1 ))
        fi
    done
    [ "$iCOUNT" -eq 0 ] && echo "None found"

    return 0
}

###############################################################################

ReportGEDiskUsage() {

    sPATH=""
    iFAILED=0

    # check for commands required by this optional feature and report any missing
    # NOTE Arch only - coreutils: du, wc - required by base: find
    # TODO are there any platforms that can run Steam that don't have du, find, and wc?
    if ! command -v du >/dev/null; then
        iFAILED=1
        echo "command du not found"
    else
        [ "$iDEBUG" = 1 ] && echo "command du found"
    fi

    if ! command -v find >/dev/null; then
        iFAILED=1
        echo "command find not found"
    else
        [ "$iDEBUG" = 1 ] && echo "command find found"
    fi

    if ! command -v wc >/dev/null; then
        iFAILED=1
        echo "command wc not found"
    else
        [ "$iDEBUG" = 1 ] && echo "command wc found"
    fi

    # if all checks succeeded
    if [ "$iFAILED" = 0 ]; then
        # set the path to be reported on based on which parameter was used -s|-S
        # NOTE if -S is invoked, sREPORT_VERSION is set to NULL
        if [ "$sREPORT_VERSION" = "" ]; then
            sPATH=$sGE_INSTALL_PATH
        elif [ -n "$sREPORT_VERSION" ]; then
            sPATH=$sGE_INSTALL_PATH/Proton-${sREPORT_VERSION}
        fi

        if [ -d "$sPATH" ]; then
            sSIZE=$(du -sh "$sPATH")
            sFILE_COUNT=$(find "$sPATH" -type f | wc -l)
            printf "%s\n%s\n%s\n" "Path: $sPATH" "Files: $sFILE_COUNT" "Disk usage: ${sSIZE%%[[:blank:]]*}"
        else
            [ "$iDEBUG" = 1 ] && echo "Path: $sPATH"
            echo "Version \"$sREPORT_VERSION\" not found"
            return 1
        fi
    # if any check failed
    elif [ "$iFAILED" = 1 ]; then
        echo "Report not available"
        [ "$iDEBUG" = 1 ] && echo "See -h for a list of optional commands required to use this feature"
        return 1
    fi

    return 0
}

###############################################################################

RemoveSavedPackages() {

    iSUCCESS=0
    iFAILED=0

    [ "$iDEBUG" = 1 ] && echo "Install path: $sGE_INSTALL_PATH"

    for sPACKAGE in "$sGE_INSTALL_PATH"/Proton-*.tar.gz; do
        if [ -f "$sPACKAGE" ]; then
            if rm -f "$sPACKAGE"; then
                [ "$iDEBUG" = 1 ] && echo "Package $sPACKAGE removed"
                iSUCCESS=$(( iSUCCESS + 1 ))
            else
                echo "Remove $sPACKAGE failed"
                iFAILED=$(( iFAILED + 1 ))
            fi
        fi
    done

    if [ "$iSUCCESS" -eq 0 ]; then
        echo "0 packages removed"
    elif [ "$iSUCCESS" -gt 0 ]; then
        echo "$iSUCCESS packages removed"
    fi

    [ "$iFAILED" -gt 0 ] && {
        echo "Failed to remove $iFAILED package(s)"
        return 1
    }

    return 0
}

###############################################################################

RemoveGEInstallPath() {

    sSIZE=""

    if command -v du >/dev/null; then
        sSIZE=$(du -sh "$sGE_INSTALL_PATH")
    else
        echo "command du not found, reported size will be wrong"
        sSIZE="error"
    fi

    if rm -rf "$sGE_INSTALL_PATH"; then
        echo "Remove install path succeeded ( ${sSIZE%%[[:blank:]]*} removed )"
        if [ "$iDEBUG" = 1 ]; then
            mkdir -pv "$sGE_INSTALL_PATH"
        else
            mkdir -p "$sGE_INSTALL_PATH"
        fi
    else
        echo "Removal of install path $sGE_INSTALL_PATH failed"
        return 1
    fi

    return 0
}

###############################################################################

IsInstalled() {

    [ -z "$1" ] && return 1

    sVERSION=${1}

    if [ -d "${sGE_INSTALL_PATH}/Proton-${sVERSION}" ]; then
        return 0
    else
        return 1
    fi

    return 0
}

###############################################################################

IsSteamRunning() {

    if command -v pgrep >/dev/null; then
        if [ -n "$(pgrep -F "$sSTEAM_PID")" ]; then
            return 0
        else
            return 1
        fi
    else
        printf "%s\n%s\n" "Warning: command pgrep not found" "IsSteamRunning check will always return false unless this command is installed"
        return 0
    fi

    # NOTE do not return 0 here
}

###############################################################################

CleanUpVersion() {

    [ -z "$1" ] && { printf "%s\n" "Internal error: CleanUpVersion() requires one parameter" 1>/dev/stderr; return 1; }

    sVERSION=$1

    [ "$iDEBUG" = 1 ] && {
        iLENGTH=${#sVERSION}
        echo "CleanUpVersion before: $sVERSION" 1>/dev/stderr
    }

    sVERSION=${sVERSION#*"Proton-"}
    sVERSION=${sVERSION#*"proton-"}
    sVERSION=${sVERSION%".tar.gz"*}

    [ "$iDEBUG" = 1 ] && {
        echo "CleanUpVersion after: $sVERSION" 1>/dev/stderr
        echo "CleanUpVersion: removed $(( iLENGTH - ${#sVERSION} )) characters" 1>/dev/stderr
    }

    printf "%s" "$sVERSION"

    return 0
}

###############################################################################

CleanUp() {

    [ -d "$sTMP_DIR" ] && {
        if [ "$iDEBUG" = 0 ]; then
            if ! rm -rf "$sTMP_DIR"; then
                echo "Failed to remove temporary file path at $sTMP_DIR"
                return 1
            fi
        elif [ "$iDEBUG" = 1 ]; then
            [ "$iFINAL_CLEANUP" = 1 ] && echo "Temporary file path not removed: $sTMP_DIR"
        fi
    }

    return 0
}

###############################################################################

Main() {

    # show help and/or usage
    if [ "$iSHOW_HELP" = 1 ] && [ "$iSHOW_USAGE" = 0 ]; then
        ShowHelp
        exit
    elif [ "$iSHOW_HELP" = 1 ] && [ "$iSHOW_USAGE" = 1 ]; then
        ShowHelp
        ShowUsage
        exit
    elif [ "$iSHOW_HELP" = 0 ] && [ "$iSHOW_USAGE" = 1 ]; then
        ShowUsage
        exit
    fi

    if [ "$iDEBUG" = 1 ]; then
        mkdir -pv "$sGE_INSTALL_PATH"
    else
        mkdir -p "$sGE_INSTALL_PATH"
    fi

    # debug mode
    if [ "$iDEBUG" = 1 ]; then
        echo "Debug mode enabled"
    fi

    # remove install path
    if [ "$iREMOVE_INSTALL_PATH" = 1 ] && [ "$iFORCE" = 1 ]; then
        if IsSteamRunning; then
            echo "Please close steam before removing the install path"
        else
            RemoveGEInstallPath
        fi
    elif [ "$iREMOVE_INSTALL_PATH" = 1 ] && [ "$iFORCE" = 0 ]; then
        echo "-X must be combined with -f to confirm that you are sure"
    fi

    # remove saved packages
    if [ "$iREMOVE_SAVED_PACKAGES" = 1 ] && [ "$iREMOVE_INSTALL_PATH" = 0 ]; then
        # TODO -f required?
        RemoveSavedPackages
    fi

    # remove an installed version or package
    if [ "$iREMOVE" = 1 ] && [ "$iREMOVE_INSTALL_PATH" = 0 ] && [ "$iREMOVE_SAVED_PACKAGES" = 0 ]; then
        # NOTE sREMOVE_VERSION and sREMOVE_PACKAGE are set in getops
        sREMOVE_VERSION=$(CleanUpVersion "$sREMOVE_VERSION")
        RemoveGEVersion
    elif [ "$iREMOVE" = 1 ] && [ "$iREMOVE_INSTALL_PATH" = 1 ]; then
        echo "Skipping remove version/package because remove install path was requested in the same invocation"
        [ "$iDEBUG" = 1 ] && printf "%s\n%s\n" "iREMOVE_INSTALL_PATH: $iREMOVE_INSTALL_PATH" "iREMOVE_SAVED_PACKAGES: $iREMOVE_SAVED_PACKAGES"
    fi

    # downlaod a package
    if [ "$iDOWNLOAD" = 1 ]; then
        # NOTE sDOWNLOAD_VERSION is set in getops
        sDOWNLOAD_VERSION=$(CleanUpVersion "$sDOWNLOAD_VERSION")
        DownloadGEPackage
    fi

    # check for new version and update if it is not installed
    if [ "$iUPDATE" = 1 ]; then
        if GetLatestGEVersionInfo; then
            # Latest version is installed and -f is suppled
            if IsInstalled "$sGE_LATEST_VERSION" && [ "$iFORCE" = 1 ]; then
                sREMOVE_VERSION=$sGE_LATEST_VERSION
                if RemoveGEVersion; then
                    if InstallGEVersion; then
                        echo "Update succeeded"
                    else
                        echo "Update failed"
                    fi
                fi
            # Latest version is installed and -f was not supplied
            elif IsInstalled "$sGE_LATEST_VERSION" && [ "$iFORCE" = 0 ]; then
                echo "Update: Latest version is installed"
            # Latest version is not installed
            elif ! IsInstalled "$sGE_LATEST_VERSION"; then
                echo "Update: Latest version is not installed"
                if InstallGEVersion; then
                    echo "Update succeeded"
                else
                    echo "Update failed"
                fi
            fi
        else
            # GetLatestGEVersionInfo failed
            echo "Update failed"
        fi
        # WARNING this hack will haunt you
        [ "$iINSTALL" = 1 ] && iUPDATE=0
    fi

    # install a package
    if [ "$iINSTALL" = 1 ] && [ "$iUPDATE" = 0 ]; then
        # NOTE sINSTALL_VERSION is set in getops
        sINSTALL_VERSION=$(CleanUpVersion "$sINSTALL_VERSION")
        InstallGEVersion
    fi

    # list installed versions
    if [ "$iLIST_INSTALLED_GE_VERSIONS" = 1 ]; then
        ListInstalledGEVersions
    fi

    # report install path usage
    if [ "$iREPORT_USAGE" = 1 ] && [ -n "$sREPORT_VERSION" ]; then
        sREPORT_VERSION=$(CleanUpVersion "$sREPORT_VERSION")
        ReportGEDiskUsage
    elif [ "$iREPORT_USAGE" = 1 ] && [ -z "$sREPORT_VERSION" ]; then
        ReportGEDiskUsage
    fi

    # if no parameters were supplied, check for latest version and report if it is installed or not
    # TODO is there a better way?
    # NOTE ignore iFORCE and iDEBUG flags
    if [ "$iREMOVE_INSTALL_PATH" = 0 ] && \
        [ "$iREMOVE_SAVED_PACKAGES" = 0 ] && \
        [ "$iREMOVE" = 0 ] && \
        [ "$iLIST_INSTALLED_GE_VERSIONS" = 0 ] && \
        [ "$iREPORT_USAGE" = 0 ] && \
        [ "$iDOWNLOAD" = 0 ] && \
        [ "$iINSTALL" = 0 ] && \
        [ "$iUPDATE" = 0 ]; then

        [ "$iDEBUG" = 1 ] && {
            if IsSteamRunning; then
                echo "Steam is running"
            else
                echo "Steam is not running"
            fi
        }

        ShowHelp
    fi
}

###############################################################################

trap '[ "$iDEBUG" = 1 ] && echo "Exit status (before CleanUp): $?"; iFINAL_CLEANUP=1 CleanUp; [ "$iDEBUG" = 1 ] && echo "Exit status (CleanUp): $?"' EXIT

###############################################################################

OPTERR=1 # make sure it's on
while getopts 'zhHflSs:i:d:R:r:NuX' sOPT; do
    case "$sOPT" in
        ("h") iSHOW_HELP=1 ;;
        ("H") iSHOW_USAGE=1 ;;
        ("f") iFORCE=1 ;;
        ("z") iDEBUG=1 ;;
        ("X") iREMOVE_INSTALL_PATH=1 ;;
        ("N") iREMOVE_SAVED_PACKAGES=1 ;;
        ("r") iREMOVE=1 sREMOVE_VERSION=$OPTARG sREMOVE_PACKAGE="";;
        ("R") iREMOVE=1 sREMOVE_PACKAGE=${OPTARG:-""} sREMOVE_VERSION="" ;;
        ("l") iLIST_INSTALLED_GE_VERSIONS=1 ;;
        ("s") iREPORT_USAGE=1 sREPORT_VERSION=${OPTARG:-""} ;;
        ("S") iREPORT_USAGE=1 sREPORT_VERSION="" ;;
        ("d") iDOWNLOAD=1 sDOWNLOAD_VERSION=$OPTARG ;;
        ("i") iINSTALL=1 sINSTALL_VERSION=$OPTARG ;;
        ("u") iUPDATE=1 ;;
        (":"|"?") exit 1 ;;
    esac
done

###############################################################################

Main
