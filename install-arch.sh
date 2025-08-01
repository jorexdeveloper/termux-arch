#!/data/data/com.termux/files/usr/bin/bash

################################################################################
#                                                                              #
#     Termux Arch Installer.                                                   #
#                                                                              #
#     Installs Arch Linux in Termux.                                           #
#                                                                              #
#     Copyright (C) 2023-2025  Jore <https://github.com/jorexdeveloper>        #
#                                                                              #
#     This program is free software: you can redistribute it and/or modify     #
#     it under the terms of the GNU General Public License as published by     #
#     the Free Software Foundation, either version 3 of the License, or        #
#     (at your option) any later version.                                      #
#                                                                              #
#     This program is distributed in the hope that it will be useful,          #
#     but WITHOUT ANY WARRANTY; without even the implied warranty of           #
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            #
#     GNU General Public License for more details.                             #
#                                                                              #
#     You should have received a copy of the GNU General Public License        #
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.   #
#                                                                              #
################################################################################
# shellcheck disable=SC2034,SC2155

# ATTENTION!!! CHANGE BELOW FUNTIONS FOR DISTRO DEPENDENT ACTIONS!!!

################################################################################
# Called before any safety checks                                              #
# New Variables: AUTHOR GITHUB LOG_FILE ACTION_INSTALL ACTION_CONFIGURE        #
#                ROOTFS_DIRECTORY COLOR_SUPPORT all_available_colors           #
################################################################################
pre_check_actions() {
	return
}

################################################################################
# Called before printing intro                                                 #
# New Variables: none                                                          #
################################################################################
distro_banner() {
	local spaces=''
	for ((i = $((($(stty size | cut -d ' ' -f2) - 38) / 2)); i > 0; i--)); do
		spaces+=' '
	done
	msg -a "${spaces}                   -'"
	msg -a "${spaces}                  .o+'"
	msg -a "${spaces}                 'ooo/"
	msg -a "${spaces}                '+oooo:"
	msg -a "${spaces}               '+oooooo:"
	msg -a "${spaces}               -+oooooo+:"
	msg -a "${spaces}             '/:-:++oooo+:"
	msg -a "${spaces}            '/++++/+++++++:"
	msg -a "${spaces}           '/++++++++++++++:"
	msg -a "${spaces}          '/+++ooooooooooooo/'"
	msg -a "${spaces}         ./ooosssso++osssssso+'"
	msg -a "${spaces}        .oossssso-''''/ossssss+'"
	msg -a "${spaces}       -osssssso.      :ssssssso."
	msg -a "${spaces}      :osssssss/        osssso+++."
	msg -a "${spaces}     /ossssssss/        +ssssooo/-"
	msg -a "${spaces}   '/ossssso+/:-        -:/+osssso+-"
	msg -a "${spaces}  '+sso+:-'                 '.-/+oso:"
	msg -a "${spaces} '++:.                           '-/+/"
	msg -a "${spaces} .'                                 '/"
	msg -a "${spaces}          ${DISTRO_NAME} ${Y}${VERSION_NAME}${C}"
}

################################################################################
# Called after checking architecture and required pkgs                         #
# New Variables: SYS_ARCH LIB_GCC_PATH                                         #
################################################################################
post_check_actions() {
	# Resolve arch to match arch linux
	if [ "${SYS_ARCH}" = "arm64" ]; then
		new_sys_arch="aarch64"
	elif [ "${SYS_ARCH}" = "armhf" ]; then
		new_sys_arch="armv7"
	else
		new_sys_arch="${SYS_ARCH}"
	fi
}

################################################################################
# Called after checking for rootfs directory                                   #
# New Variables: KEEP_ROOTFS_DIRECTORY                                         #
################################################################################
pre_install_actions() {
	ARCHIVE_NAME="ArchLinuxARM-${new_sys_arch}-${VERSION_NAME}.tar.gz"
}

################################################################################
# Called after extracting rootfs                                               #
# New Variables: KEEP_ROOTFS_ARCHIVE                                           #
################################################################################
post_install_actions() {
	return
}

################################################################################
# Called before making configurations                                          #
# New Variables: none                                                          #
################################################################################
pre_config_actions() {
	return
}

################################################################################
# Called after configurations                                                  #
# New Variables: none                                                          #
################################################################################
post_config_actions() {
	# Fix environment variables on login or su.
	# local fix="session  required  pam_env.so readenv=1"
	# for f in su su-l system-local-login system-remote-login; do
	# 	if [ -f "${ROOTFS_DIRECTORY}/etc/pam.d/${f}" ] && ! grep -q "${fix}" "${ROOTFS_DIRECTORY}/etc/pam.d/${f}" >>"${LOG_FILE}" 2>&1; then
	# 		echo "${fix}" >>"${ROOTFS_DIRECTORY}/etc/pam.d/${f}"
	# 	fi
	# done
	# execute distro specific command for locale generation
	if [ -f "${ROOTFS_DIRECTORY}/etc/locale.gen" ] && [ -x "${ROOTFS_DIRECTORY}/sbin/locale-gen" ]; then
		msg -t "Hold on while I generate the locales for you."
		sed -i -E 's/#[[:space:]]?(en_US.UTF-8[[:space:]]+UTF-8)/\1/g' "${ROOTFS_DIRECTORY}/etc/locale.gen"
		if distro_exec locale-gen >>"${LOG_FILE}" 2>&1; then
			msg -s "Done, the locales are ready!"
		else
			msg -e "I failed to generate the locales."
		fi
	fi
	# Initialize keyring
	msg -t "Give me a few more seconds to set up the ${DISTRO_NAME} keyring."
	if distro_exec /bin/pacman-key --init >>"${LOG_FILE}" 2>&1 && distro_exec /bin/pacman-key --populate archlinuxarm >>"${LOG_FILE}" 2>&1; then
		msg -s "Done, the ${DISTRO_NAME} keyring is ready for use!"
	else
		msg -e "Sorry, I failed to set up the ${DISTRO_NAME} keyring."
	fi
	# Remove uneeded kernel
	msg -t "Lastly, some cleanups. You probably won't need the kernel."
	if distro_exec /bin/pacman -Rnsc --noconfirm "linux-${new_sys_arch}" >>"${LOG_FILE}" 2>&1 && distro_exec /bin/pacman -Scc --noconfirm >>"${LOG_FILE}" 2>&1; then
		msg -s "Done, your system is as light as a feather!"
	else
		msg -e "Sorry, I failed to make the cleanups."
	fi
}

################################################################################
# Called before complete message                                               #
# New Variables: none                                                          #
################################################################################
pre_complete_actions() {
	if ! ${GUI_INSTALLED:-false} && ask -y -- -t "Should I set up the GUI now?"; then
		set_up_gui && set_up_browser && GUI_INSTALLED=true
	fi
}

################################################################################
# Called after complete message                                                #
# New Variables: none                                                          #
################################################################################
post_complete_actions() {
	return
}

################################################################################
# Local Functions                                                              #
################################################################################

# Sets up the GUI
set_up_gui() {
	msg -t "The installation is going to take very long."
	msg "Lemme me acquire the '${Y}Termux wake lock${C}'."
	if [ -x "$(command -v termux-wake-lock)" ]; then
		if termux-wake-lock >>"${LOG_FILE}" 2>&1; then
			msg -s "Great, the Termux wake lock is now activated."
		else
			msg -e "I have failed to set up the Termux wake lock."
			msg "Keep Termux open during the installation."
		fi
	else
		msg -e "I could not find the '${Y}termux-wake-lock${R}' command."
		msg "Keep Termux open during the installation."
	fi
	msg -t "Lemme first upgrade the packages in ${DISTRO_NAME}."
	msg "This won't take long."
	if distro_exec pacman --color auto -Syu; then
		msg -s "Done, all the ${DISTRO_NAME} packages are upgraded."
		msg -t "Now lemme install the GUI in ${DISTRO_NAME}."
		msg "This will take very long."
		if distro_exec pacman --color auto -Sy tigervnc dbus xfce4; then
			msg -s "Finally, the GUI is now installed in ${DISTRO_NAME}."
			msg -t "Now lemme add the xstartup script for VNC."
			if {
				local xstartup="$(
					cat 2>>"${LOG_FILE}" <<-EOF
						#!/usr/bin/bash
						unset SESSION_MANAGER
						unset DBUS_SESSION_BUS_ADDRESS
						export XDG_RUNTIME_DIR=\${TMPDIR:-/tmp}/runtime-"\${USER:-root}"
						export SHELL="\${SHELL:-/bin/sh}"
						if [ -r ~/.Xresources ]; then
						    xrdb ~/.Xresources
						fi
						exec startxfce4
					EOF
				)"
				mkdir -p "${ROOTFS_DIRECTORY}/root/.vnc"
				echo "${xstartup}" >"${ROOTFS_DIRECTORY}/root/.vnc/xstartup"
				chmod 744 "${ROOTFS_DIRECTORY}/root/.vnc/xstartup"
				if [ "${DEFAULT_LOGIN}" != "root" ]; then
					mkdir -p "${ROOTFS_DIRECTORY}/home/${DEFAULT_LOGIN}/.vnc"
					echo "${xstartup}" >"${ROOTFS_DIRECTORY}/home/${DEFAULT_LOGIN}/.vnc/xstartup"
					chmod 744 "${ROOTFS_DIRECTORY}/home/${DEFAULT_LOGIN}/.vnc/xstartup"
				fi
			} 2>>"${LOG_FILE}"; then
				msg -s "Done, xstartup script added successfully!"
			else
				msg -e "I failed to add the xstartup script."
			fi
		else
			msg -qm0 "I have failed to install the GUI in ${DISTRO_NAME}."
		fi
	else
		msg -qm0 "I have failed to upgrade the packages in ${DISTRO_NAME}."
	fi
}

# Sets up the Browser
set_up_browser() {
	local available_browsers=(
		"Chromium" "Firefox" "Both Browsers"
	)
	choose -d2 -t "Select your prefered Browser." \
		"${available_browsers[@]}"
	local selected_browser="${available_browsers[$((${?} - 1))]}"
	local selected_browsers verb
	if [ "${selected_browser}" = "${available_browsers[-1]}" ]; then
		selected_browsers=("${available_browsers[@]:0:${#available_browsers[@]}-1}")
		selected_browsers=("${selected_browsers[@]// /-}")
		verb="are"
	else
		selected_browsers=("${selected_browser// /-}")
		verb="is"
	fi
	msg "Okay then, I shall install '${Y}${selected_browser}${C}'."
	if distro_exec pacman --color auto -Sy "${selected_browsers[@],,}"; then
		if [ "${selected_browsers[0]}" = "${available_browsers[0]}" ]; then
			sed -Ei 's/^(Exec=.*chromium).*(%U)$/\1 --no-sandbox \2/' "${ROOTFS_DIRECTORY}/usr/share/applications/chromium.desktop"
		fi
		msg "Done, ${selected_browser} ${verb} now installed in ${DISTRO_NAME}."
	else
		msg -e "I have failed to install ${selected_browser} in ${DISTRO_NAME}."
	fi
}

DISTRO_NAME="Arch Linux ARM"
PROGRAM_NAME="$(basename "${0}")"
DISTRO_REPOSITORY="termux-arch"
VERSION_NAME="latest"
KERNEL_RELEASE="$(uname -r)"

SHASUM_CMD=md5sum
TRUSTED_SHASUMS="$(
	cat <<-EOF
		50d193e062794e21026bd0e981311fa5  ArchLinuxARM-armv7-latest.tar.gz
		bdef3220a954dadacf03f18d18544204  ArchLinuxARM-aarch64-latest.tar.gz
	EOF
)"

ARCHIVE_STRIP_DIRS=0 # directories stripped by tar when extracting rootfs archive
BASE_URL="http://os.archlinuxarm.org/os"
TERMUX_FILES_DIR="/data/data/com.termux/files"

DISTRO_SHORTCUT="${TERMUX_FILES_DIR}/usr/bin/arch"
DISTRO_LAUNCHER="${TERMUX_FILES_DIR}/usr/bin/archlinux"

DEFAULT_ROOTFS_DIR="${TERMUX_FILES_DIR}/archlinux"
DEFAULT_LOGIN="alarm"

# WARNING!!! DO NOT CHANGE BELOW!!!

# Check in script's directory for template
distro_template="$(realpath "$(dirname "${0}")")/termux-distro.sh"
# shellcheck disable=SC1090
if [ -f "${distro_template}" ] && [ -r "${distro_template}" ]; then
	source "${distro_template}" "${@}"
elif curl -fsSLO "https://raw.githubusercontent.com/jorexdeveloper/termux-distro/main/termux-distro.sh" 2>"/dev/null" && [ -f "${distro_template}" ]; then
	source "${distro_template}"
else
	echo "You need an active internet connection to run this script."
fi
