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

sHELP="
    $(basename "$0" .sh)  v$sSCRIPT_VER

    Required:       curl, tar, gzip, pgrep
    Optional:       du, find, wc (for -s|-S)

    Install path:          $sGE_INSTALL_PATH
    Base download URL:     $sGE_DOWNLOAD_BASE_URL
    Latest version URL:    $sGE_LATEST_VERSION_URL

    -h            - Show this help
                      All other parameters except -H will be ignored

    -H            - Show usage notes, formats, and examples

    -l            - List installed versions and saved packages

    -S            - Report file count and disk usage of install path

    -s <version>  - Report file count and disk usage of <version>

    -u            - Check for and install the latest release if it is not installed

    -i <version>  - Download and install <version>

    -R <version>  - Remove installed <version>

    -r <version>  - Remove saved package <version>

    -d <version>  - Download the package for <version> and save it to the install path

    -N            - Remove all saved packages matching the pattern "Proton-*.tar.gz" in the install path

    -X            - Remove the entire install path
                      -f is also required to confirm that you are sure

    -f            - Force install, upgrade, or remove
                      Combined with -u and/or -i, remove saved package and download a new copy

    -z            - Enable debug mode
                      Enable extra output messages and preserve any temporary files created

"
sUSAGE="
    USAGE:        - Acceptable formats for <version>:
                      5.9-GE-3-ST, Proton-5.9-GE-3-ST, 5.9-GE-3-ST.tar.gz, or Proton-5.9-GE-3-ST.tar.gz

                  - The order of parameters is not significant except
                    > If during invocation multiple identical parameters are supplied
                        For example: -s 5.11-GE-1-MF -s 5.9-GE-3-ST
                      Only the right-most parameter will be processed (-s 5.9-GE-3-ST)
                    > And/or if during invocation a parameter and it's capital counter-part are both included
                        For example: -s 5.11-GE-1-MF -S
                      Only the right-most parameter will be processed (-S)

                  - Most options (except -hH, -rR, and -sS) can be combined to
                    perform several actions in one invocation.
                      For example: Assuming the latest version is 5.9-GE-3-ST
                        ./$(basename "$0") -f -X -i Proton-5.11-GE-1-MF -z -u
                      will enable debug mode, remove the installation path,
                      update to the latest version 5.9-GE-3-ST, and then install version 5.11-GE-1-MF

                  - Order of operations if multiple unique parameters are supplied:
                      Show help, Show usage, Force toggle, Debug toggle, Remove install path,
                      Remove saved packages (if remove install path is not active),
                      Remove installed version (if remove install path is not active),
                      Download specific, Update, Install specific, List installed, Report usage

"
