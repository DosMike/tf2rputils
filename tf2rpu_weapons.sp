// Sub script for all things related to droping weapons, picking them up and holstering them

bool clientWeaponsHolstered[MAXPLAYERS + 1];
bool clientWeaponsIsFisting[MAXPLAYERS + 1];
int clientWeaponsHiddenMelee[MAXPLAYERS + 1];

static char TFClassNames[TFClassType][10] = {
	"<Unknown>", "Scout", "Sniper", "Soldier", "DemoMan", "Medic", "Heavy", "Pyro", "Spy", "Engineer"
};

//defaults to L for dropping intel
public Action commandDropItem(int client, const char[] command, int argc) {
	return commandDropWeapon(client, 0);
}
public Action commandDropWeapon(int client, int args) {
	if (client) {
		if (!canClientContinue(client, cvar_WeaponDropCommands)) return Plugin_Handled;
		int weapon = Client_GetActiveWeapon(client);
		if (weapon != INVALID_ENT_REFERENCE) {
			int weaponIndex;
			bool physgun = Impl_TF2rpu_IsPhysGun(weapon, weaponIndex);
			tf2WeaponSlot weaponSlot = _CheckWeaponSlot(weaponIndex);
			
			if ( weaponSlot > TF2WeaponSlot_Melee || !_HasWeaponWorldModel(weapon) || !Fire_ClientDropWeapon(client,weapon,weaponIndex) ) {
				//we shouldn't drop things that aren't weapons (cause issues with giveNamedItem when picking up)
				//we can't drop fists without world model
				//and we can't drop if other plugins say so
				return Plugin_Handled;
			} else if ( physgun ) {
				TF2_RemoveWeaponSlot(client, 1); //is hardcoded for physgun
				Impl_TF2rpu_SetActiveWeapon(client, TF2WeaponSlot_Unknown); //try to switch
				return Plugin_Handled;
			}
			if (Impl_TF2rpu_DropWeapon(client, weapon) == INVALID_ENT_REFERENCE)
				return Plugin_Handled; //could not drop
			if (weaponSlot == TF2WeaponSlot_Melee) {
				//Dropped melee weapon
				Impl_TF2rpu_GiveWeaponEx(client, WEAPON_HANDS, false); // give fists for melee to prevent t-posing
			}
			Impl_TF2rpu_SetActiveWeapon(client, -1); //switch to any other weapon to prevent confusion
			Fire_ClientDropWeaponPost(client,weapon,weaponIndex);
		}
	}
	return Plugin_Handled;
}

public Action commandHolsterWeapon(int client, int args) {
	if (!cvar_WeaponHolster.BoolValue) return Plugin_Continue;
	if (Client_IsValid(client, false)) {
		bool holstered = clientWeaponsHolstered[client];
		Impl_TF2rpu_ClientHolsterWeapon(client, !holstered);
	}
	return Plugin_Handled;
}

public Action commandCreateDroppedWeapon(int client, int args) {
	if (!Client_IsValid(client)) return Plugin_Handled;
	if (args < 1) {
		char cmd[32];
		GetCmdArg(0, cmd, sizeof(cmd));
		ReplyToCommand(client, "%t","command usage",cmd,"<classname>");
		return Plugin_Handled;
	}
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	int defIndex = Impl_TF2rpu_GetDefaultIndexFromWeaponClass(arg);
	if (defIndex < 0) {
		ReplyToCommand(client, "%t", "invalid weapon classname", arg);
	} else if (Impl_TF2rpu_SpawnWeaponAt(client, defIndex) < 0) {
		ReplyToCommand(client, "%t", "spawn weapon failed", arg, defIndex, client);
	}
	return Plugin_Handled;
}

/**
 * Holster or unholster weapons. It's important to drop the holstered Weapon, if
 * admins give the client a new melee. Otherwise the new melee would be
 * immediately replaced with the holstered weapon.
 * 
 * @param client   the client to holster a weapon from
 * @param holser   true to holser, false to unholster
 * @param dropHolser if true, the holstered weapon will not be restored
 */
void Impl_TF2rpu_ClientHolsterWeapon(int client, bool holster, bool dropHolster=false) {
	if (!IsClientInGame(client)) return;
	if (dropHolster) clientWeaponsHiddenMelee[client] = -1;
	if (clientWeaponsHolstered[client] == holster) {
		if (holster) Impl_TF2rpu_SetActiveWeapon(client, TF2WeaponSlot_Melee);
		return;
	}
	if (holster) {
		//important so pulling out fists isn't triggering unholster
		clientWeaponsIsFisting[client] = false;
		//map weapon to definition index
		int melee = Client_GetWeaponBySlot(client, TF2WeaponSlot_Melee);
		if (melee == INVALID_ENT_REFERENCE || ((melee = Impl_TF2rpu_GetWeapondDefinitionIndex(melee)) == WEAPON_HANDS)) {
			CPrintToChat(client, "%t", "no melee to holster");
			return;
		}
		clientWeaponsHolstered[client] = true;
		clientWeaponsHiddenMelee[client] = melee;
		CPrintToChat(client, "%t", "holster info");
		Impl_TF2rpu_GiveWeaponEx(client, WEAPON_HANDS, true);
		Fire_ClientHolsterWeapon(client, melee);
	} else if (clientWeaponsHiddenMelee[client] >= 0) {
		clientWeaponsHolstered[client] = false;
		Impl_TF2rpu_GiveWeaponEx(client, clientWeaponsHiddenMelee[client], true);
		Fire_ClientHolsterWeapon(client, -1);
	} else {
		clientWeaponsHolstered[client] = false;
	}
}

int Impl_TF2rpu_GetClientHolsteredWeapon(int client) {
	return clientWeaponsHolstered[client] ? clientWeaponsHiddenMelee[client] : -1;
}

void Event_ClientWeaponSwitchPost(int client, int weapon) {
	if (client && clientWeaponsHolstered[client]) {
		if (!clientWeaponsIsFisting[client]) {
			clientWeaponsIsFisting[client] = true;
		} else if (weapon != INVALID_ENT_REFERENCE && Impl_TF2rpu_GetWeapondDefinitionIndex(weapon) == WEAPON_HANDS) {
			Impl_TF2rpu_ClientHolsterWeapon(client, false);
		}
	}
}

public Action Event_ClientTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damageType) { // weapon param doesn't work
	if(Client_IsValid(attacker, false) && attacker != victim) {
		int attackerWeapon = Impl_TF2rpu_GetActiveWeapon(attacker);
		if (attackerWeapon == WEAPON_HANDS && cvar_WeaponHolsterNoFistdamage.BoolValue) {
			return Plugin_Handled; //Fists equal unarmed -> no damage
		}
	}
	return Plugin_Continue;
}

bool clientCanInteractEntity(int client, int entity, bool expectTargetClient=false) {
	if (!Client_IsValid(client, false) || !IsPlayerAlive(client) || !IsValidEntity(entity)) return false;
	if (expectTargetClient && !Client_IsValid(entity, false)) return false;
	if (Entity_IsPlayer(entity) && (!Client_IsIngame(entity) || !IsPlayerAlive(entity))) return false;
	return Entity_GetDistance(client, entity) <= 150.0;
}

bool pickUpWeapon(int client, int entity) {
	char classname[64];
	if (!IsValidEntity(entity)) return false;
	if (!clientCanInteractEntity(client, entity)) return false;
	GetEntityClassname(entity, classname, sizeof(classname));
	if (!StrEqual(classname, "tf_dropped_weapon")) return false; //use target is weapon
	if (!cvar_WeaponPickup.BoolValue) return false;
	
	int index = Impl_TF2rpu_GetWeapondDefinitionIndex(entity);
	bool canClassPickup = Impl_TF2rpu_WeaponConvertCompatible(index, TF2_GetPlayerClass(client));
	if (!Fire_ClientPickupWeapon(client,entity,index)) return false;
	if (!canClassPickup && !canClientContinue(client,cvar_WeaponPickupIgnoreClass)) {
		char weaponName[100];
		if (!TF2Econ_GetItemName(index, weaponName, sizeof(weaponName))) {
			strcopy(weaponName, sizeof(weaponName), "INVALID");
		}
		PrintToChat(client, "%t", "action invalid player class", TFClassNames[TF2_GetPlayerClass(client)]);
		return false;
	}
	int weapon;
	tf2WeaponSlot slot = _CheckWeaponSlot(index, TF2_GetPlayerClass(client));
	//try to drop the current weapon in the slot into the world
	if (( weapon = GetPlayerWeaponSlot(client, slot) )!=-1) {
		Impl_TF2rpu_DropWeapon(client, weapon);
	}
	//read ammo of dropped weapon
	int clip = GetEntData(entity, droppedWeaponClipOffset), ammo = GetEntData(entity, droppedWeaponAmmoOffset);
	//delete weapon on floor
	AcceptEntityInput(entity, "Kill");
	//give new weapon and set ammo
	Impl_TF2rpu_ClientHolsterWeapon(client, false, slot == TF2WeaponSlot_Melee);
	if (( weapon = _GiveWeapon(client, index) )!=INVALID_ENT_REFERENCE) {
		Weapon_SetPrimaryClip(weapon, clip);
		Client_SetWeaponPlayerAmmoEx(client, weapon, ammo);
		//play pickup sound
		EmitSoundToAll("weapons/default_reload.wav", client);
	}
	Fire_ClientPickupWeaponPost(client,entity,index);
	
	return true;
}