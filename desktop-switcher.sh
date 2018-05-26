#!/bin/bash
################################################################################
# This script changes the workspaces, their content (icons and wallpaper) and
# the recent documents list. It uses desktop names to identify the individual
# workspaces.
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# The folder structure (to run this script) must be structured like this
# (corresponding to the configuration you've done in this script):
# 
# [1] Configuration
# - DESKTOP_HOME:  the root folder for all workspaces
# - DESKTOP_NAMES: a list of workspace names, that exists in ${DESKTOP_HOME}
#                  IMPORTANT NOTE: avoid spaces in the name of the workspace
#
# [2] Preparation
# The folder ${DESKTOP_HOME} contains these elements to get individual
# workspaces (replace %workspace-?% by individual names):
#
# - ${DESKTOP_HOME}/%workspace-?%/
#     (required) the folder, that contains the elements of this individual
#     desktop
# - ${DESKTOP_HOME}/%workspace-?%.jpg
#     (optional) is the wallpaper of the desktop
# ${DESKTOP_HOME}/.%workspace-?%.xbel
#     (optional) a copy of the current "${HOME}/.local/share/recently-used.xbel"
#     
# [3] Installation
# First start - test the script at commandline:
# 1) open terminal (<Ctrl>+<Alt>+<T>)
# 2) set executable rights:
#    $> chmod +x path_to/desktop-switcher.sh
# 3) run the script:
#    $> path_to/desktop-switcher.sh
# 4) switch through the workspaces/desktops by using an applet or this keys
#    left workspace: <Strg>+<Alt>+<Arrow-left>
#    right workspace: <Strg>+<Alt>+<Arrow-right>
#
# DOES IT FIT?
#
# >>>> NO! - try to find the error or post me.
#
# >>>> YES:
#
# 6) open "Startup Applications" (german: "Startprogramme") in your Mint Menu
# 7) hit the button "Add" and choose "Custom command"
# 8) fill the formular:
#    a) name: enter an individual name (e.g. desktop-switcher)
#    b) command: choose the script
#    c) OK
# 9) restart your computer and enjoy your new muliple desktop environment ;-)
# 
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
#
# The script was tested in an cinnamon environment:
# - Linux Mint 18.1
# - Linux Mint 18.2
# - Linux Mint 18.3
# 
#--- base sources --------------------------------------------------------------
# https://github.com/linuxmint/Cinnamon/issues/4108
# https://forums.linuxmint.com/viewtopic.php?t=118540
################################################################################
# @author hofsve - 2017-12-23 - name based workspaces
# @author hofsve - 2018-05-26 - individual recent documents for every workspace
################################################################################

#---- CONFIGURATION ------------------------------------------------------------
GLOBAL_DESKTOP="/home/hofrichter/Schreibtisch"
DESKTOP_HOME="/home/hofrichter/Schreibtische" # full path to images directory;
DESKTOP_NAMES=(Claudia Hakon Morten Sven)

################################################################################
# DO NOT TOUCH THE REST OF THE SCRIPT, UNLESS YOU KNOW, HAT YOU DO!
################################################################################
#---- FUNCTIONs ----------------------------------------------------------------
setDesktop() {
    # resolve the name of the chosen desktop
    CURR_DESKTOP_NAME="${DESKTOP_NAMES[$1]}"
    CURR_DESKTOP_DIR="${DESKTOP_HOME}/${CURR_DESKTOP_NAME}"
    CURR_DESKTOP_IMG="${CURR_DESKTOP_DIR}.jpg"
    
    if [ ! -d ${CURR_DESKTOP_DIR} ]; then
        # the fallback shows the the directory, where all custom desktop
        # directory is placed in:
        CURR_DESKTOP_DIR=${DESKTOP_HOME}
        CURR_DESKTOP_IMG=
    fi
    
    # change the wallpaper:
    gsettings set org.gnome.desktop.background picture-uri "file://${CURR_DESKTOP_IMG}"
    rm ${GLOBAL_DESKTOP} && ln -s ${CURR_DESKTOP_DIR} ${GLOBAL_DESKTOP}

    # disable the icons:
    gsettings set org.nemo.desktop show-desktop-icons false
    
    # build the pattern for 'sed' and change the desktop directory:
    pattern='s#^XDG_DESKTOP_DIR=.*#XDG_DESKTOP_DIR="'${CURR_DESKTOP_DIR}'"#g'
    sed -i "$pattern" ~/.config/user-dirs.dirs
    
    # enable the icons:
    gsettings set org.nemo.desktop show-desktop-icons false
    sleep 0.5
    gsettings set org.nemo.desktop show-desktop-icons true
}
#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
setRecentDocuments() {
    if [ ! -z "$1" ]; then
        PREV_DESKTOP_NAME="${DESKTOP_NAMES[$1]}"
        cp -pf "${HOME}/.local/share/recently-used.xbel" "${DESKTOP_HOME}/.${PREV_DESKTOP_NAME}.recently-used.xbel"
    fi
    CURR_DESKTOP_NAME="${DESKTOP_NAMES[$2]}"
    if [ -f "${DESKTOP_HOME}/.${CURR_DESKTOP_NAME}.recently-used.xbel" ]; then
        cp -pf "${DESKTOP_HOME}/.${CURR_DESKTOP_NAME}.recently-used.xbel" "${HOME}/.local/share/recently-used.xbel"
    fi
    touch "${HOME}/.local/share/recently-used.xbel"
}

#---- MAIN ---------------------------------------------------------------------
# set the desktop names
DESKTOP_NAMES_STR=$(printf "'%s', " ${DESKTOP_NAMES[*]})
DESKTOP_NAMES_STR="[$(echo ${DESKTOP_NAMES_STR} | rev | cut -c 2- | rev)]"
gsettings set org.cinnamon.desktop.wm.preferences workspace-names "${DESKTOP_NAMES_STR}"
gsettings set org.cinnamon number-workspaces ${#DESKTOP_NAMES[@]}
# onStart:
setDesktop 0

# onChange:
PREV_DESKTOP_NUM=
xprop -root -spy _NET_CURRENT_DESKTOP | while read -r; do
    # get the desktop number:
    CURR_DESKTOP_NUM="${REPLY: -1}"
    setRecentDocuments "${PREV_DESKTOP_NUM}" "${CURR_DESKTOP_NUM}"
    setDesktop "${CURR_DESKTOP_NUM}"
    PREV_DESKTOP_NUM=${CURR_DESKTOP_NUM}
done

