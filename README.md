# CS:GO Pause Plugin
Adds simple pause/unpause commands for players

This is an extremely simple plugin to add pause-commands for players that simply wrap the builtin pause system connected to commands.

It adds some simple commands that can be used by all players:

# Player Commands
> * sm_tech (!tech)
> * sm_pause (!pause, !tac)
> * sm_unpause (!unpause)

It also adds commands for admins to use:
# Admin Commands
> * sm_forcetechpause (!forcetechnical, !ftech)
> * sm_forcepause (!forcepause, !fp)
> * sm_forceunpause (!forceunpause, !fup)

You can change these commands in the commands.cfg.

# Installation
Simply download the latest build and paste the folder structure, to your server.

This plugin was built by: Splewis
And reworked by me to support more variations and in general use of builtin feature.

## Changelog
> * 1.0.1 - Rework of the plugin itself.
> * 1.0.2 - Added translation files, fixed more variations of commands and cleaned up the code.
> * 1.0.3 - Development with using the built-in system
> * 1.0.4a - Takes the needed features of timer for pauses, limit and technical aspect into consideration.
> * 1.0.5a - Both teams now need to write !unpause, to start the match. Fixing up syntax, as well as deleting certain command variations, to loosen up the command section. Added a 30-second timer to the !pause, that unpauses when timer runs out. This function also allows people to use !unpause before time runs out. In addition added af cfg file with command variations, to add or delete variations depending on what you need.

## Credits
> * Bacardi - Giving me the start features to edit this up.
> * BeepIsla - For giving me that simple idea of using the built-in system.

## To Do:
> * General brainstorming on what to add.
