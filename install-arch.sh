#!/data/data/com.termux/files/usr/bin/bash

################################################################################
#                                                                              #
# Termux Arch Installer.                                                       #
#                                                                              #
# Installs Arch Linux in Termux.                                               #
#                                                                              #
# Copyright (C) 2023-2025  Jore <https://github.com/jorexdeveloper>            #
#                                                                              #
# This program is free software: you can redistribute it and/or modify         #
# it under the terms of the GNU General Public License as published by         #
# the Free Software Foundation, either version 3 of the License, or            #
# (at your option) any later version.                                          #
#                                                                              #
# This program is distributed in the hope that it will be useful,              #
# but WITHOUT ANY WARRANTY; without even the implied warranty of               #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                #
# GNU General Public License for more details.                                 #
#                                                                              #
# You should have received a copy of the GNU General Public License            #
# along with this program.  If not, see <https://www.gnu.org/licenses/>.       #
#                                                                              #
################################################################################
# shellcheck disable=SC2034,SC2155

# ATTENTION!!! CHANGE BELOW FUNTIONS FOR DISTRO DEPENDENT ACTIONS!!!

################################################################################
# Called before any safety checks                                              #
# New Variables: AUTHOR GITHUB LOG_FILE ACTION_INSTALL ACTION_CONFIGURE        #
#                ROOTFS_DIRECTORY COLOR_SUPPORT (all available colors)         #
################################################################################
pre_check_actions() {
	P=${W} # primary color
	S=${C} # secondary color
	T=${M} # tertiary color
}

################################################################################
# Called before printing intro                                                 #
# New Variables: none                                                          #
################################################################################
distro_banner() {
	local spaces=$(printf "%*s" $((($(stty size | awk '{print $2}') - 38) / 2)) "")
	msg -a "${spaces}${S}                   -'"
	msg -a "${spaces}${S}                  .o+'"
	msg -a "${spaces}${S}                 'ooo/"
	msg -a "${spaces}${S}                '+oooo:"
	msg -a "${spaces}${S}               '+oooooo:"
	msg -a "${spaces}${S}               -+oooooo+:"
	msg -a "${spaces}${S}             '/:-:++oooo+:"
	msg -a "${spaces}${S}            '/++++/+++++++:"
	msg -a "${spaces}${S}           '/++++++++++++++:"
	msg -a "${spaces}${S}          '/+++ooooooooooooo/'"
	msg -a "${spaces}${S}         ./ooosssso++osssssso+'"
	msg -a "${spaces}${S}        .oossssso-''''/ossssss+'"
	msg -a "${spaces}${S}       -osssssso.      :ssssssso."
	msg -a "${spaces}${S}      :osssssss/        osssso+++."
	msg -a "${spaces}${S}     /ossssssss/        +ssssooo/-"
	msg -a "${spaces}${S}   '/ossssso+/:-        -:/+osssso+-"
	msg -a "${spaces}${S}  '+sso+:-'                 '.-/+oso:"
	msg -a "${spaces}${S} '++:.                           '-/+/"
	msg -a "${spaces}${S} .'                                 '/"
	msg -a "${spaces}${S}          ${P}${DISTRO_NAME}${S} ${T}${VERSION_NAME}${S}"
}

################################################################################
# Called after checking architecture and required pkgs                         #
# New Variables: SYS_ARCH LIB_GCC_PATH                                         #
################################################################################
post_check_actions() {
	# Resolve arch to match arch linux
	case "${SYS_ARCH}" in
		armhf)
			new_sys_arch=armv7
			;;
		arm64)
			new_sys_arch=aarch64
			;;
		*)
			new_sys_arch=${SYS_ARCH}
			;;
	esac
}

################################################################################
# Called after checking for rootfs directory                                   #
# New Variables: KEEP_ROOTFS_DIRECTORY                                         #
################################################################################
pre_install_actions() {
	ARCHIVE_NAME=ArchLinuxARM-${new_sys_arch}-${VERSION_NAME}.tar.gz
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
	if [[ -f ${ROOTFS_DIRECTORY}/etc/locale.gen && -x ${ROOTFS_DIRECTORY}/sbin/locale-gen ]]; then
		msg -tn "Generating locales..."
		sed -i -E 's/#[[:space:]]?(en_US.UTF-8[[:space:]]+UTF-8)/\1/g' "${ROOTFS_DIRECTORY}"/etc/locale.gen

		if distro_exec locale-gen &>>"${LOG_FILE}"; then
			cursor -u1
			msg -ts "Locales generated"
		else
			cursor -u1
			msg -te "Failed to generate locales."
		fi
	fi

	msg -tn "Setting up ${DISTRO_NAME} keyring..."

	if distro_exec /bin/pacman-key --init &>>"${LOG_FILE}" && distro_exec /bin/pacman-key --populate archlinuxarm &>>"${LOG_FILE}"; then
		cursor -u1
		msg -ts "${DISTRO_NAME} keyring set up"
	else
		cursor -u1
		msg -te "Failed to set up ${DISTRO_NAME} keyring"
	fi

	msg -tn "Removing ${DISTRO_NAME} kernel..."

	if distro_exec /bin/pacman -Rnsc --noconfirm linux-"${new_sys_arch}" &>>"${LOG_FILE}" && distro_exec /bin/pacman -Scc --noconfirm &>>"${LOG_FILE}"; then
		cursor -u1
		msg -ts "${DISTRO_NAME} kernel removed"
	else
		cursor -u1
		msg -ts "Failed to remove ${DISTRO_NAME}"
	fi
}

################################################################################
# Called before complete message                                               #
# New Variables: none                                                          #
################################################################################
pre_complete_actions() {
	if [[ ! ${DE_INSTALLED} ]] && ask -y -- -t "Install Desktop Environment?"; then
		set_up_de && {
			DE_INSTALLED=1
			set_up_browser
		}
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

# Sets up the desktop environment
set_up_de() {
	if command -v termux-wake-lock &>>"${LOG_FILE}"; then
		msg -tn "Acquiring Termux wake lock..."

		if termux-wake-lock &>>"${LOG_FILE}"; then
			cursor -u1
			msg -ts "Termux wake lock held"
		else
			cursor -u1
			msg -te "Failed to acquire Termux wake lock"
		fi
	fi

	msg -tn "Installing desktop packages in ${DISTRO_NAME}..."
	trap 'buffer -h; echo; msg -fem2; exit 130' INT
	buffer -s

	local pkgs=(tigervnc dbus xfce4)
	if buffer -i pacman --color auto -Syu && distro_exec pacman --color auto -Syu &&
		buffer -i pacman --color auto -Sy "${pkgs[@]}" && distro_exec pacman --color auto -Sy "${pkgs[@]}"; then
		buffer -h3
		trap - INT
		cursor -u1
		msg -ts "Desktop packages installed in ${DISTRO_NAME}"

		msg -tn "Creating xstartup program..."

		local xstartup=$(
			cat 2>>"${LOG_FILE}" <<-EOF
				#!/bin/bash
				unset SESSION_MANAGER
				unset DBUS_SESSION_BUS_ADDRESS

				export XDG_RUNTIME_DIR=\${TMPDIR}/runtime-"\${USER}"
				export SHELL=\${SHELL}

				if [[ -r ~/.Xresources ]]; then
				    xrdb ~/.Xresources
				fi

				exec startxfce4
			EOF
		)

		if {
			mkdir -p "${ROOTFS_DIRECTORY}"/root/.vnc &&
				echo "${xstartup}" >"${ROOTFS_DIRECTORY}"/root/.vnc/xstartup &&
				chmod 744 "${ROOTFS_DIRECTORY}"/root/.vnc/xstartup &&
				if [[ ${DEFAULT_LOGIN} != root ]]; then
					mkdir -p "${ROOTFS_DIRECTORY}"/home/"${DEFAULT_LOGIN}"/.vnc &&
						echo "${xstartup}" >"${ROOTFS_DIRECTORY}"/home/"${DEFAULT_LOGIN}"/.vnc/xstartup &&
						chmod 744 "${ROOTFS_DIRECTORY}"/home/"${DEFAULT_LOGIN}"/.vnc/xstartup
				fi
		} 2>>"${LOG_FILE}"; then
			cursor -u1
			msg -ts "Xstartup program created"
		else
			cursor -u1
			msg -te "Failed create xstartup program"
		fi
	else
		buffer -h5
		trap - INT
		cursor -u1
		msg -te "Failed to install Desktop packages in ${DISTRO_NAME}"
		return 1
	fi
}

# Sets up the Browser
set_up_browser() {
	local available_browsers selected_browser selected_browsers suffix
	available_browsers=(
		"Chromium" "Firefox" "Chromium & Firefox"
	)

	choose -d2 -t "Select Browser" \
		"${available_browsers[@]}"
	selected_browser=${available_browsers[$((${?} - 1))]}

	if [[ ${selected_browser} == "${available_browsers[-1]}" ]]; then
		selected_browsers=("${available_browsers[@]:0:${#available_browsers[@]}-1}")
		selected_browsers=("${selected_browsers[@]// /-}")
		suffix=s
	else
		selected_browsers=("${selected_browser// /-}")
		suffix=
	fi

	msg -tn "Installing ${selected_browser} Browser${suffix}..."
	trap 'buffer -h; echo; msg -fem2; exit 130' INT
	buffer -s

	if buffer -i pacman --color auto -Sy "${selected_browsers[@],,}" && distro_exec pacman --color auto -Sy "${selected_browsers[@],,}"; then
		if [[ ${selected_browsers[0]} == "${available_browsers[0]}" && -f "${ROOTFS_DIRECTORY}"/usr/share/applications/chromium.desktop ]]; then
			sed -Ei 's/^(Exec=.*chromium).*(%U)$/\1 --no-sandbox \2/' "${ROOTFS_DIRECTORY}"/usr/share/applications/chromium.desktop
		fi

		buffer -h3
		trap - INT
		cursor -u1
		msg -ts "${selected_browser} Browser${suffix} installed"
	else
		buffer -h5
		trap - INT
		cursor -u1
		msg -te "Failed to install ${selected_browser} Browser${suffix}"
	fi
}

DISTRO_NAME="Arch Linux ARM"
PROGRAM_NAME=$(basename "${0}")
DISTRO_REPOSITORY=termux-arch
KERNEL_RELEASE=$(uname -r)
VERSION_NAME=latest

SHASUM_CMD=md5sum
TRUSTED_SHASUMS=$(
	cat <<-EOF
		50d193e062794e21026bd0e981311fa5  ArchLinuxARM-armv7-latest.tar.gz
		bdef3220a954dadacf03f18d18544204  ArchLinuxARM-aarch64-latest.tar.gz
	EOF
)

ARCHIVE_STRIP_DIRS=0 # directories stripped by tar when extracting rootfs archive
BASE_URL=http://os.archlinuxarm.org/os
TERMUX_FILES_DIR=/data/data/com.termux/files

DISTRO_SHORTCUT=${TERMUX_FILES_DIR}/usr/bin/arch
DISTRO_LAUNCHER=${TERMUX_FILES_DIR}/usr/bin/archlinux

DEFAULT_ROOTFS_DIR=${TERMUX_FILES_DIR}/archlinux
DEFAULT_LOGIN=root

# WARNING!!! DO NOT CHANGE BELOW!!!

# Check in program's directory for template
distro_template=$(realpath "$(dirname "${0}")")/termux-distro.sh

# shellcheck disable=SC1090
if [[ -f ${distro_template} ]] || curl -fsSLO https://raw.githubusercontent.com/jorexdeveloper/termux-distro/main/termux-distro.sh &>/dev/null; then
	source "${distro_template}" "${@}" || exit 1
else
	echo "You need an active internet connection to run this program."
fi
