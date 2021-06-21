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
- Nice and easy use of CusrorAnnotation and HudMessageCustom
- Other stuff i probably forgot (check tf2rputils.inc)

ConVars
-----

|Name  |Default  | Description |
|--|--|--|
| tfrpu_weapondrop_enable | 1 | Enables the weapon drop system |
| tfrpu_weapondrop_command | 1 | Allows players to actively drop weapons, value 2 will allow only admin |
| tfrpu_weapondrop_noammo | 1 | Disable ammo boxes from dropping |
| tfrpu_weaponpickup_enable | 1 | Allow players to pick up weapons from the ground with +use |
| tfrpu_weaponpickup_ignoreclass | 1 | Any player can pick up any weapons on the ground, value 2 will allow only admin |
| tfrpu_weaponholster_enable | 1 | Players can use !holster to put their melee away |
| tfrpu_weaponholster_nodamage | 1 | Fists (given by !holster) do not deal any damage |
| tfrpu_instantclass_enable | 1 | Allows players to change class without cooldown / death, value 2 will only enable this for admins |
| tfrpu_instantclass_keephp | 1 | Changin class does not heal, but \"duck\" hp to the new max, value 2 will on apply to non-admins |

**These will change to 0-defaults soon**

Requirements
-----

- smlib
- morecolors.inc
- tf2items
- tf2attributes
- tf_econ_data

*TODO: link deps*

Credits
-----

Pretty much all of the AlliedModders community!
There's a lot of information scattered around on the forums, discord and various GitHub repos.