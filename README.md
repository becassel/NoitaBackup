<!---
README.md. The README for NoitaBackup.
Copyright (C) 2021 Benjamin Cassell

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.
-->

# NoitaBackup
A simple script for backing up and restoring Noita worlds.

# Setup
The features provided in this script are all Bash intended to be used
explicitly on the Windows Subsystem for Linux (WSL), although it could be used
from other environments (e.g. Cygwin) with minor adjustments.

Start by adding noita.sh to at least one of the files that launches during your
shell startup (e.g. .profile, .bashrc, etc.):

```
source somepath/noita.sh
```

Where `somepath` is the directory you have saved the script in. You will likely
need to restart your session after making this change:

```
exec bash
```

Next, run the setup command to generate a config file for the script in
`${HOME}/.noitaconfig`:

```
noita-setup-config
```

By default, worlds are saved to `%UserProfile%/Docuemnts/My Games/Noita`,
however you may change this by adjusting the variables in `.noitaconfig`:

```
NOITA_BACKUPDIR_WORLDS # Determines where worlds are saved.
NOITA_SAVEDIR # Points to Noita's save data. You shouldn't need to touch this.
```

# Use

## List Worlds

Lists any currently backed up worlds:

```
noita-list-worlds
```

## Backup Worlds

Create a backup of a Noita world:

```
noita-backup-world name source
```

Where `name` is an optional friendly name you want for your world (defaults to
`world`), and `source` is the specific Noita gameplay data you want to backup
(defaults to the active Noita save, `save00`).

Sample use: `noita-backup-world really_good_perks`

## Restore Worlds

Restore a previous backup of a Noita world:

```
noita-restore-world name dest
```

Where `name` is the required friendly name of the world you want to restore,
and `dest` is the specific Noita gameplay data you want to restore over
(defaults to the active Noita save, `save00`).

Sample use: `noita-restore-world really_good_perks`

## Delete Backups

Delete a previous backup of a Noita world:

```
noita-delete-world name
```

Where `name` is the required friendly name of the world you want to delete. Be
careful, this action will delete your backup for good!

Sample use: `noita-delete-world really_good_perks`
