
// command implementations that are not weapon / class switch specific

public Action commandRegenerateSelf(int client, int args) {
	char command[32], arg1[MAX_NAME_LENGTH];
	if(args < 1) {
		GetCmdArg(0, command, sizeof(command));
		CReplyToCommand(client, "%t", "Command usage", command, "<#userid|name>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	int targets[MAXPLAYERS + 1], amount;
	bool tn_is_ml;
	if((amount = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, arg1, sizeof(arg1), tn_is_ml))) {
		for(int i; i < amount; i++) {
			TF2_RegeneratePlayer(targets[i]);
		}
		if(tn_is_ml) {
			ShowActivity2(client, "[SM] ", "%t", "Admin resupplied target", client, arg1);
		} else {
			ShowActivity2(client, "[SM] ", "%t", "Admin resupplied target", client, "_s", arg1);
		}
	} else {
		ReplyToTargetError(client, amount);
	}
	return Plugin_Handled;
}

static int _giveByName(int client, char[] weapon, int namesize) {
	int entity = Impl_TF2rpu_GiveWeapon(client, weapon);
	if (entity == INVALID_ENT_REFERENCE && !StrEqual(weapon, "saxxy") && StrContains(weapon,"tf_")!=0) {
		//is not saxxy or something, prefix with weapon
		char buf[64];
		FormatEx(buf, sizeof(buf), "tf_weapon_%s", weapon);
		strcopy(weapon, namesize, buf); //write back to accelerate further loops
		entity = Impl_TF2rpu_GiveWeapon(client, weapon); //try again
	}
	return entity;
}
static int _giveByIndex(int client, int weaponIndex, char[] weapon, int namesize) {
	int entity = Impl_TF2rpu_GiveWeaponEx(client, weaponIndex);
	if (entity != INVALID_ENT_REFERENCE)
		Entity_GetClassName(entity, weapon, namesize);
	return entity;
}
static void _refillWeaponAmmo(int client, int weapon) {
	if (weapon == INVALID_ENT_REFERENCE) return;
	Weapon_SetPrimaryClip(weapon, TF2Util_GetWeaponMaxClip(weapon));
	if (Impl_TF2rpu_HasAmmoEntity(weapon)) {
		char classname[64];
		GetEntityClassname(weapon, classname, sizeof(classname));
		Client_SetWeaponPlayerAmmoEx(client, weapon, Impl_TF2rpu_GetMaxAmmo(classname));
	}
}
static void _refillAllAmmo(int client) {
	_refillWeaponAmmo(client, GetPlayerWeaponSlot(client, TF2WeaponSlot_Main));
	_refillWeaponAmmo(client, GetPlayerWeaponSlot(client, TF2WeaponSlot_Side));
	SetEntData(client, FindDataMapOffs(client, "m_iAmmo") + (3 * 4), 200, 4); //refill metal
}
public Action commandGiveWeapon(int client, int args) {
	char command[32], arg1[MAX_NAME_LENGTH], weapon[64];
	GetCmdArg(0, command, sizeof(command));
	if(args != 2) {
		CReplyToCommand(client, "%t", "Command usage", command, "<#userid|name> <item>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, weapon, sizeof(weapon));
	int weaponAsIndex = -1;
	if ('0' <= weapon[0] <= '9') //seems to be numeric
		weaponAsIndex = StringToInt(weapon);
		
	bool tn_is_ml;
	int targets[MAXPLAYERS + 1], amount = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, arg1, sizeof(arg1), tn_is_ml);
	if(amount) {
		if(StrEqual(command, "sm_give")) {
			if (StrEqual(weapon, "ammo")) {
				for(int i; i < amount; i++) {
					_refillAllAmmo(targets[i]);
				}
			} else {
				for(int i; i < amount; i++) {
					if (weaponAsIndex < 0) {
						if (_giveByName(targets[i], weapon, sizeof(weapon)) == INVALID_ENT_REFERENCE) {
							ReplyToCommand(client, "%t", "invalid weapon classname", weapon);
							return Plugin_Handled;
						}
					} else {
						if (_giveByIndex(client, weaponAsIndex, weapon, sizeof(weapon)) == INVALID_ENT_REFERENCE) {
							ReplyToCommand(client, "%t", "invalid weapon definition index", weapon);
							return Plugin_Handled;
						}
					}
				}
			}
		}
		if(tn_is_ml) {
			ShowActivity2(client, "[SM] ", "%t", "Admin gave weapon", client, weapon, arg1);
		} else {
			ShowActivity2(client, "[SM] ", "%t", "Admin gave weapon", client, weapon, "_s", arg1);
		}
	} else {
		ReplyToTargetError(client, amount);
	}
	return Plugin_Handled;
}

public Action commandGod(int client, int args) {
	char command[32], arg1[MAX_NAME_LENGTH], arg2[2];
	if(args < 2) {
		GetCmdArg(0, command, sizeof(command));
		CReplyToCommand(client, "%t", "Command usage", command, "<#userid|name> <1/0>");
		return Plugin_Handled;
	}
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int targets[MAXPLAYERS + 1], amount;
	bool tn_is_ml;
	if((amount = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, arg1, sizeof(arg1), tn_is_ml))) {
		for(int i; i < amount; i++) {
			Entity_SetTakeDamage(targets[i], (StringToInt(arg2) == 1) ? DAMAGE_NO : DAMAGE_YES);
		}
		if(StringToInt(arg2) == 1) {
			if(tn_is_ml) {
				ShowActivity2(client, "[SM] ", "%t", "Admin gave god mode to target", client, arg1);
			} else {
				ShowActivity2(client, "[SM] ", "%t", "Admin gave god mode to target", client, "_s", arg1);
			}
		} else {
			if(tn_is_ml) {
				ShowActivity2(client, "[SM] ", "%t", "Admin removed god mode from target", client, arg1);
			} else {
				ShowActivity2(client, "[SM] ", "%t", "Admin removed god mode from target", client, "_s", arg1);
			}
		}
	} else {
		ReplyToTargetError(client, amount);
	}
	return Plugin_Handled;
}

public Action commandHp(int client, int args) {
	char command[32], arg1[MAX_NAME_LENGTH], arg2[16], arg3[6];
	if(args < 2) {
		GetCmdArg(0, command, sizeof(command));
		CReplyToCommand(client, "%t", "Command usage", command, "<#userid|name> <health|'RESET'> ['MAX'|'FIX']");
	} else {
		bool tn_is_ml, maxhp=false, reset=false, nodecay=false;
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		int targets[MAXPLAYERS + 1], amount, hp = StringToInt(arg2);
		if (hp == 0 && StrEqual(arg2, "reset", false)) {
			reset = true;
		} else if (args > 2) {
			GetCmdArg(3, arg3, sizeof(arg3));
			if (StrEqual(arg3, "max", false)) maxhp = true;
			else if (StrEqual(arg3, "fix", false)) nodecay = true;
		}
		if((amount = ProcessTargetString(arg1, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, arg1, sizeof(arg1), tn_is_ml))) {
			if (reset) {
				for(int i; i < amount; i++) {
					Impl_TF2rpu_ResetMaxHealth(targets[i]);
				}
				if(tn_is_ml) {
					ShowActivity2(client, "[SM] ", "%t", "Admin reset maxhealth of target", client, arg1);
				} else {
					ShowActivity2(client, "[SM] ", "%t", "Admin reset maxhealth of target", client, "_s", arg1);
				}
			} else if (maxhp) {
				for(int i; i < amount; i++) {
					Impl_TF2rpu_SetClientMaxHealth(targets[i], hp);
				}
				if(tn_is_ml) {
					ShowActivity2(client, "[SM] ", "%t", "Admin set maxhealth of target", client, arg1, arg2);
				} else {
					ShowActivity2(client, "[SM] ", "%t", "Admin set maxhealth of target", client, "_s", arg1, arg2);
				}
			} else {
				for(int i; i < amount; i++) {
					Impl_TF2rpu_SetHealthEx(targets[i], hp, _, nodecay);
				}
				if(tn_is_ml) {
					ShowActivity2(client, "[SM] ", "%t", "Admin set health of target", client, arg1, arg2);
				} else {
					ShowActivity2(client, "[SM] ", "%t", "Admin set health of target", client, "_s", arg1, arg2);
				}
			}
		} else {
			ReplyToTargetError(client, amount);
		}
	}
	return Plugin_Handled;
}