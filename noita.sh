#!bin/bash

# noita.sh. A simple script for backing up and restoring Noita data.
# Copyright (C) 2021 Benjamin Cassell
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program.  If not, see <http://www.gnu.org/licenses/>.


NOITA_CONFIG="${HOME}/.noitaconfig"


# Attempts to load values from the Noita configuration.
noita-load-config() {
	if [ ! -f "${NOITA_CONFIG}" ]; then
		echo "No Noita configuration file ${NOITA_CONFIG}. Please run noita-setup-config. Aborting."
		return 1;
	fi
	source "${NOITA_CONFIG}"
	if [ ${?} -ne 0 ]; then
		echo "Error while sourcing Noita configuration file ${NOITA_CONFIG}. Aborting."
		return 1;
	fi
}


# Create the user's configuration file for Noita. This must be run prior to
# using any of the backup-related commands.
noita-setup-config() {
	# Warn the user if the Noita config already exists (and give them the option to abort).
	if [ -f "${NOITA_CONFIG}" ]; then
		local yes_no
		read -p "Noita configuration file ${NOITA_CONFIG} already exists. Delete and overwrite [Y/N]? " -n 1 -r yes_no
		echo
		case "${yes_no}" in
			y|Y)
				echo "Deleting existing Noita configuration file ${NOITA_CONFIG}..."
				rm -f "${NOITA_CONFIG}"
				if [ ${?} -ne 0 ]; then
					echo "Could not delete Noita configuration file ${NOITA_CONFIG}. Aborting."
					return 1
				fi
				echo "Done."
				;;
			n|N)
				echo "Setup cancelled by user. Aborting."
				return 0
				;;
			*)
				echo "Invalid option ${yes_no}. Please explicitly use [Y/N]. Aborting."
				return 1
				;;
		esac
	fi

	# Write out the config file.
	local backupdir="$(realpath "$(wslupath "$(wslvar UserProfile)")/Documents/My Games/Noita")"
	echo "Creating Noita configuration file ${NOITA_CONFIG}."
	echo "By default, backups will be stored in ${backupdir}. To change this behaviour, modify the values NOITA_BACKUPDIR_WORLDS in the Noita configuration file."

	cat <<EOF >> "${NOITA_CONFIG}"
#!bin/bash
# Configuration values for the Noita script.

NOITA_BACKUPDIR_WORLDS="${backupdir}/worlds"
NOITA_SAVEDIR="$(realpath "$(wslupath "$(wslvar AppData)")/../LocalLow/Nolla_Games_Noita")"
EOF

	if [ ${?} -ne 0 ]; then
		echo "Error while creating Noita configuration file ${NOITA_CONFIG}. Aborting."
		return 1;
	fi
}


# List any worlds that have been backed up.
noita-list-worlds() {
	noita-load-config
	if [ ${?} -ne 0 ]; then
		return 1;
	fi

	# If the primary directory doesn't exist, abort.
	if [ ! -d "${NOITA_BACKUPDIR_WORLDS}" ]; then
		echo "No root worlds backup folder ${NOITA_BACKUPDIR_WORLDS} detected. Aborting."
		return 1;
	fi

	# List 'em!
	ls "${NOITA_BACKUPDIR_WORLDS}"
	if [ ${?} -ne 0 ]; then
		echo "Error while listing backup worlds. Aborting."
		return 1;
	fi
}


# Backup the current Noita world. Arguments: $1 (optional) - The name of the
# world that be used as the root directory for the backup (defaults to
# "world"). $2 (optional) - The Noita save file to copy from (defaults to
# "save00").
noita-backup-world() {
	noita-load-config
	if [ ${?} -ne 0 ]; then
		return 1;
	fi

	local world_name="${1:-world}"
	local noita_save="${2:-save00}"
	local noita_savedir_full="${NOITA_SAVEDIR}/${noita_save}"
	local noita_backupdir_full="${NOITA_BACKUPDIR_WORLDS}/${world_name}"

	# Abort if no current Noita world exists to backup.
	if [ ! -d "${noita_savedir_full}" ]; then
		echo "No Noita data detected at ${noita_savedir_full}. Aborting."
		return 1
	fi

	# Warn the user if the backup already exists (and give them the option to abort).
	if [ -d "${noita_backupdir_full}" ]; then
		local yes_no
		read -p "Noita backup world ${noita_backupdir_full} already exists. Delete and overwrite [Y/N]? " -n 1 -r yes_no
		echo
		case "${yes_no}" in
			y|Y)
				echo "Deleting existing backup world ${world_name}..."
				rm -rf "${noita_backupdir_full}"
				if [ ${?} -ne 0 ]; then
					echo "Could not delete Noita backup world ${noita_backupdir_full}. Aborting."
					return 1
				fi
				echo "Done."
				;;
			n|N)
				echo "Backup cancelled by user. Aborting."
				return 0
				;;
			*)
				echo "Invalid option ${yes_no}. Please explicitly use [Y/N]. Aborting."
				return 1
				;;
		esac
	fi

	# If the primary directory doesn't exist, create it.
	if [ ! -d "${NOITA_BACKUPDIR_WORLDS}" ]; then
		echo "No root worlds backup folder ${NOITA_BACKUPDIR_WORLDS} detected. Creating it."
		mkdir -p "${NOITA_BACKUPDIR_WORLDS}"
		if [ ${?} -ne 0 ]; then
			echo "Error encountered while creating root worlds backup folder ${NOITA_BACKUPDIR_WORLDS}. Aborting."
			return 1;
		fi
	fi

	# Copy the files over.
	echo "Backing up world ${world_name}..."
	cp -R -v "${noita_savedir_full}" "${noita_backupdir_full}"
	if [ ${?} -ne 0 ]; then
		echo "Error encountered during backup. Aborting."
		return 1;
	fi
	echo "Done."
}


# Delete a Noita world. Arguments: $1 - The name of the world to delete.
noita-delete-world() {
	noita-load-config
	if [ ${?} -ne 0 ]; then
		return 1;
	fi

	local world_name="${1}"
	local noita_backupdir_full="${NOITA_BACKUPDIR_WORLDS}/${world_name}"

	# Abort if no world was provided.
	if [ -z "${world_name}" ]; then
		echo "No world provided to delete. Aborting."
		return 1
	fi

	# Abort if the specified Noita world doesn't exist.
	if [ ! -d "${noita_backupdir_full}" ]; then
		echo "No Noita data detected at ${noita_backupdir_full}. Aborting."
		return 1
	fi

	# Double-check that the user actually wants to do this.
	local yes_no
	read -p "Noita backup world ${noita_backupdir_full} will be deleted. Proceed [Y/N]? " -n 1 -r yes_no
	echo
	case "${yes_no}" in
		y|Y)
			echo "Deleting backup world ${world_name}..."
			rm -rf "${noita_backupdir_full}"
			if [ ${?} -ne 0 ]; then
				echo "Could not delete Noita backup world ${noita_backupdir_full}. Aborting."
				return 1
			fi
			echo "Done."
			;;
		n|N)
			echo "Delete cancelled by user. Aborting."
			return 0
			;;
		*)
			echo "Invalid option ${yes_no}. Please explicitly use [Y/N]. Aborting."
			return 1
			;;
	esac
}


# Restore the current Noita world. Arguments: $1 - The name of the world that
# will be restored. $2 (optional) - The Noita save file to restore over
# (defaults to "save00").
noita-restore-world() {
	noita-load-config
	if [ ${?} -ne 0 ]; then
		return 1;
	fi

	local world_name="${1}"
	local noita_save="${2:-save00}"
	local noita_savedir_full="${NOITA_SAVEDIR}/${noita_save}"
	local noita_backupdir_full="${NOITA_BACKUPDIR_WORLDS}/${world_name}"

	# Abort if no world was provided.
	if [ -z "${world_name}" ]; then
		echo "No world provided to restore. Aborting."
		return 1
	fi

	# Abort if no current Noita world exists to restore.
	if [ ! -d "${noita_backupdir_full}" ]; then
		echo "No Noita backup world detected at ${noita_backupdir_full}. Aborting."
		return 1
	fi

	# Warn the user if a Noita save already exists (and give them the option to abort).
	if [ -d "${noita_savedir_full}" ]; then
		local yes_no
		read -p "Noita save ${noita_savedir_full} already exists. Delete and overwrite [Y/N]? " -n 1 -r yes_no
		echo
		case "${yes_no}" in
			y|Y)
				echo "Deleting existing save ${noita_save}..."
				rm -rf "${noita_savedir_full}"
				if [ ${?} -ne 0 ]; then
					echo "Could not delete Noita save ${noita_savedir_full}. Aborting."
					return 1
				fi
				echo "Done."
				;;
			n|N)
				echo "Restore cancelled by user. Aborting."
				return 0
				;;
			*)
				echo "Invalid option ${yes_no}. Please explicitly use [Y/N]. Aborting."
				return 1
				;;
		esac
	fi

	# Realistically we might want to check that the Noita save directory exists
	# here, but if it doesn't, the user probably has bigger problems.

	# Copy the files over.
	echo "Restoring world ${world_name}..."
	cp -R -v "${noita_backupdir_full}" "${noita_savedir_full}"
	if [ ${?} -ne 0 ]; then
		echo "Error encountered during restore. Aborting."
		return 1;
	fi
	echo "Done."
}

