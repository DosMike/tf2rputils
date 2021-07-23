TF2RP Utils
=====

Utility Plugin for TF2 mainly intended as library for another Plugin i work on

Features
-----

- Drop and pick up weapons on demand
- Holster your melee weapons to "show fists"
- Mess with attributes to set max health optionally without overheal
- Give yourself weapons similar to TF2Item GiveWeapon but with TF2Econ data
- sm_god, sm_resupply
- Other stuff i probably forgot (check tf2rputils.inc)

Commands
-----

| Aliases | Flags | Description |
|--|--|--|
| sm_dropweapon sm_dropit |  | Drop the weapon you're currently holding |
| sm_hands sm_holster |  | Put your weapons away and show hands |
| sm_spawnweapon sm_spawngun | ADMFLAG_CHEATS | Create a weapon and drop it in the world - Only supports normal rarity items |
| sm_resupply | ADMFLAG_CHEATS | <#userid\|name> - Regenerate yourself as if you used a resupply locker |
| sm_give | ADMFLAG_CHEATS | <#userid\|name> <weapon> - Weapon is the item index or classname, tf_weapon_ is optional, or `ammo` for ammo |
| sm_fakegive | ADMFLAG_CHEATS | <#userid\|name> <weapon> - Pretends to give a weapon |
| sm_god | ADMFLAG_ROOT | <#userid\|name> <1/0> - Enables or disables god mode on a player |
| sm_hp | ADMFLAG_ROOT | <#userid\|name> <health\|'RESET'> ['MAX'\|'FIX'] - Sets health of a player, FIX will prevent overheal decay |

ConVars
-----

|Name  |Default  | Description |
|--|--|--|
| tfrpu_weapondrop_enable | 0 | Enables the weapon drop system |
| tfrpu_weapondrop_command | 2 | Allows players to actively drop weapons, value 2 will allow only admin |
| tfrpu_weapondrop_noammo | 1 | Disable ammo boxes from dropping |
| tfrpu_weaponpickup_enable | 0 | Allow players to pick up weapons from the ground with +use |
| tfrpu_weaponpickup_ignoreclass | 0 | Any player can pick up any weapons on the ground, value 2 will allow only admin |
| tfrpu_weaponholster_enable | 0 | Players can use !holster to put their melee away |
| tfrpu_weaponholster_nodamage | 1 | Fists (given by !holster) do not deal any damage |
| tfrpu_instantclass_enable | 0 | Allows players to change class without cooldown / death, value 2 will only enable this for admins |
| tfrpu_instantclass_keephp | 1 | Changin class does not heal, but \"duck\" hp to the new max, value 2 will on apply to non-admins |

Requirements
-----

- smlib
- morecolors.inc
- tf2items
- tf2attributes
- tf_econ_data
- tf2utils

*TODO: link deps*

Credits
-----

Pretty much all of the AlliedModders community!
There's a lot of information scattered around on the forums, discord and various GitHub repos.