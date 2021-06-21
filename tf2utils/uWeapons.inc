#define WEAPON_HANDS 5

enum tf2WeaponSlot { //lower case for implicit int conversion
	TF2WeaponSlot_Unknown = -1,
	TF2WeaponSlot_Main, //main weapon, mostly primary, but secondary for spy
	TF2WeaponSlot_Side, //side weapon, mostly secondaries, but sapper for spy
	TF2WeaponSlot_Melee, //melee weapons
	TF2WeaponSlot_Building = 4, //probably shouldn't be replaced, used for holding a constuction blueprint
	TF2WeaponSlot_PDA,
	TF2WeaponSlot_PDA2,
}

/**
 * Get the weapon definition index unchecked.
 * 
 * @throw invalid entity or property not found
 */
int Impl_TF2rpu_GetWeapondDefinitionIndex(int weapon) {
	return GetEntProp(weapon, Prop_Send, PROP_ITEMDEFINITIONINDEX);
}
/**
 * Tries to generify the weapon class name. since the generic name is usually shorter
 * it will write back into the same var.
 * This function is mainly important for the class weapon converter
 */
void Impl_TF2rpu_GenerifyWeaponClass(char[] classname, int maxlen) {
	if (String_StartsWith(classname, "tf_weapon_handgun_")) {
		strcopy(classname, maxlen, "tf_weapon_pistol");
	} else if (String_StartsWith(classname, "tf_weapon_shotgun_")) {
		strcopy(classname, maxlen, "tf_weapon_shotgun");
	} else if (String_StartsWith(classname, "tf_weapon_bat_")) {
		strcopy(classname, maxlen, "tf_weapon_bat");
//causing problems
//	} else if (String_StartsWith(classname, "tf_weapon_rocketlauncher_")) {
//		strcopy(classname, maxlen, "tf_weapon_rocketlauncher");
	} else if (String_StartsWith(classname, "tf_weapon_flaregun_")) {
		strcopy(classname, maxlen, "tf_weapon_flaregun");
	}
}

int Impl_TF2rpu_GiveWeapon(int client, const char[] classname) {
	if (!Client_IsValid(client) || !IsPlayerAlive(client)) return -1; // can't give to dead players
	int weaponDefinition = Impl_TF2rpu_GetDefaultIndexFromWeaponClass(classname);
	if (weaponDefinition < 0) return -1;
	Impl_TF2rpu_WeaponConvertCompatible(weaponDefinition, TF2_GetPlayerClass(client));
	return Impl_TF2rpu_GiveWeaponEx(client, weaponDefinition);
}
int Impl_TF2rpu_GiveWeaponEx(int client, int weaponDefinitionIndex, bool switchTo=true) {
	int weapon = _GiveWeapon(client, weaponDefinitionIndex);
	if (Entity_IsValid(weapon)) {
		SetEntProp(weapon, Prop_Send, PROP_ACCOUNTID, GetSteamAccountID(client));
		Weapon_SetOwner(weapon, client);
		if (switchTo) {
			Client_SetActiveWeapon(client, weapon);
		}
	}
	return weapon;
}
static bool _TF2rpu_TF2EconItemFilter_ByClassname(int itemDef, any data) {
	char query[64];
	char buffer[64];
	
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	pack.ReadString(query, sizeof(query));
	
	TF2Econ_GetItemClassName(itemDef, buffer, sizeof(buffer));
//	if (String_StartsWith(buffer, query)) {
//		rarity
//		PrintToServer("[TF2Econ Filter] %s %i has rarity %i", buffer, itemDef, TF2Econ_GetItemRarity(itemDef));
//		return TF2Econ_GetItemRarity(itemDef) == TF2Econ_DefaultRarityNormal;
//	} else return false;
//	PrintToServer("[TF2Econ Filter] StartsWith %s %s", buffer, query);
	if (String_StartsWith(query, "tf_weapon_rocketlauncher"))
		return StrEqual(buffer, query) && TF2Econ_GetItemRarity(itemDef)<=TF2Econ_DefaultRarityNormal;
	else
		return String_StartsWith(buffer, query) && TF2Econ_GetItemRarity(itemDef)<=TF2Econ_DefaultRarityNormal;
}
static bool _TF2rpu_TF2EconItemFilter_ByClassnameAndPlayerclass(int itemDef, any data) {
	char wclass[64];
	char buffer[64];
	TFClassType pclass;
	
	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	pack.ReadString(wclass, sizeof(wclass));
	pclass = view_as<TFClassType>(pack.ReadCell());
	
	TF2Econ_GetItemClassName(itemDef, buffer, sizeof(buffer));
	if (String_StartsWith(wclass, "tf_weapon_rocketlauncher"))
		return StrEqual(buffer, wclass) && 
			TF2Econ_GetItemLoadoutSlot(itemDef, pclass)!=-1 &&
			TF2Econ_GetItemRarity(itemDef)<=TF2Econ_DefaultRarityNormal;
	else
		return String_StartsWith(buffer, wclass) && 
			TF2Econ_GetItemLoadoutSlot(itemDef, pclass)!=-1 &&
			TF2Econ_GetItemRarity(itemDef)<=TF2Econ_DefaultRarityNormal;
}
int Impl_TF2rpu_GetDefaultIndexFromWeaponClass(const char[] classname) {
	DataPack pack = new DataPack();
	pack.WriteString(classname);
	ArrayList items = TF2Econ_GetItemList(_TF2rpu_TF2EconItemFilter_ByClassname, pack);
	delete pack;
	
	int result = -1;
	if (items.Length > 0) {
		result = view_as<int>(items.Get(0));
	}
	delete items;
	return result;
}

/**
 * Like Client_GetWeapon, but checks for the weapon definition index, instead
 * of the weapon class name.
 * @param client the client to check
 * @param weaponIndex the weapon definition index to search
 * @return weapon or INVALID_ENT_REFERENCE if the player does not have that weapon
 */
int Impl_TF2rpu_GetWeapon(int client, int weaponIndex) {
	int index, weapon;
	while ((weapon = Client_GetNextWeapon(client, index))!=-1) {
		if (Impl_TF2rpu_GetWeapondDefinitionIndex(weapon) == weaponIndex) {
			return weapon;
		}
	}
	return INVALID_ENT_REFERENCE;
}

// return the max ammo per weapon ignoring the clip
// carefull with the tf_weapon_flamethrower tf_weapon_minigun tf_weapon_sniperrifle, it does not have ammo, the returned value there will be clip
// NOTE: Some weapon classname append the player class despite the classname listed in the wiki, so use StrContains()==0 when uncertain
// @return max ammo, 0 if not available, -1 if weapon not recognized (not all available classes are recognizes, e.g. meele, because that'd only waste time)
int Impl_TF2rpu_GetMaxAmmo(const char[] classname) { //not provided by any used library
	// weapons with ammo could use a datamap value m_iPrimaryAmmoCount
	// max clip has to be fetched using 323L 317W CTFWeaponBase::GetMaxClip1()
	if (StrEqual(classname, "tf_weapon_scattergun") || StrEqual(classname, "tf_weapon_soda_popper") || 
		StrContains(classname, "tf_weapon_shotgun")==0 ) { 
		// Shotguns
		 return 32;
	} else if (StrContains(classname, "tf_weapon_pistol")==0 || StrEqual(classname, "tf_weapon_handgun_scout_primary")) {
		// Pistols
//		if (class == TFClass_Engineer) return 200; //que?
//		else //yes, engi has 200 reserved ammo, but that's a bit excessive for us
		return 36;
	} else if (StrEqual(classname, "tf_weapon_rocketlauncher")) {
		return 20;
	} else if (StrEqual(classname, "tf_weapon_flamethrower")) {
		return 200;
	} else if (StrEqual(classname, "tf_weapon_grenadelauncher")) {
		return 16;
	} else if (StrEqual(classname, "tf_weapon_pipebomblauncher")) {
		return 24;
	} else if (StrEqual(classname, "tf_weapon_minigun")) {
		return 200;
	} else if (StrEqual(classname, "tf_weapon_lunchbox")) {
		return 0;
	} else if (StrEqual(classname, "tf_weapon_syringegun_medic")) {
		return 150;
	} else if (StrEqual(classname, "tf_weapon_medigun")) {
		return 0;
	} else if (StrEqual(classname, "tf_weapon_sniperrifle")) {
		return 25;
	} else if (StrEqual(classname, "tf_weapon_smg")) {
		return 75;
	} else if (StrEqual(classname, "tf_weapon_revolver")) {
		return 24;
	} else { //includes melee
		return -1;
	}
}
/**
 * @param weapon entity
 * @return true if this weapon has ammo, false if only clip
 * @error if the entities supplied is not a weapon
 */
bool Impl_TF2rpu_HasAmmoEntity(int weapon) {
	char classname[64];
	if (!Entity_IsValid(weapon)) ThrowError("The supplied entitiy was not valid");
	Entity_GetClassName(weapon, classname, sizeof(classname));
	if ((StrContains(classname, "tf_weapon_")) == -1) ThrowError("The supplied entity was not a weapon (%s)", classname);
	return Impl_TF2rpu_HasAmmo(classname);
}
/**
 * @return true, if the weapon class has ammo to refill the clip
 */
bool Impl_TF2rpu_HasAmmo(const char[] classname) { //not provided by any used library
	if (StrEqual(classname, "tf_weapon_flamethrower") || StrEqual(classname, "tf_weapon_minigun") ||
		StrEqual(classname, "tf_weapon_lunchbox") || StrEqual(classname, "tf_weapon_lunchbox_drink") || 
		StrEqual(classname, "tf_weapon_sniperrifle") || StrEqual(classname, "tf_weapon_medigun") ||
		StrEqual(classname, "tf_weapon_bat") || StrEqual(classname, "tf_weapon_shovel") || 
		StrEqual(classname, "tf_weapon_fireaxe") || StrEqual(classname, "tf_weapon_bottle") || 
		StrEqual(classname, "tf_weapon_fists") || StrEqual(classname, "tf_weapon_wrench") || 
		StrEqual(classname, "tf_weapon_bonesaw") || StrEqual(classname, "tf_weapon_club") || 
		StrEqual(classname, "tf_weapon_knife")|| StrEqual(classname, "saxxy"))
			return false;
	return true;
}

/**
 * Retrieving the weapons classname by index and (if applicable) converts a weapon into a normal tier
 * compatible weapon for the specified class.
 * if playerClass is TF2Class_Unknown, only the classname will be extracted.
 * @param weaponIndex the weapon to analyze, writes back the modified weaponIndex
 * @param playerClass the class to convert weapons to, if applicable (currently shotgun,pistol)
 * @param classname extracts the weapons classname
 * @param sz_classname sizeof(classname)
 * @return true iif after conversion, the weaponIndex is supprted by the specified playerClass
 */
bool Impl_TF2rpu_WeaponConvertCompatible(int& weaponIndex, TFClassType playerClass=TFClass_Unknown, char classname[]="", int sz_classname=0) {
	if (!TF2Econ_IsValidItemDefinition(weaponIndex)) return false;
	char buffer[100]; //use internally for classname
	bool isNormal = false;
	isNormal = TF2Econ_GetItemRarity(weaponIndex) <= TF2Econ_DefaultRarityNormal;
	TF2Econ_GetItemClassName(weaponIndex, buffer, sizeof(buffer));
	if (sz_classname > 0) {
		strcopy(classname,sz_classname,buffer);
	}
	Impl_TF2rpu_GenerifyWeaponClass(buffer, sizeof(buffer));
	
	if (playerClass == TFClass_Unknown)
		return false; //can't convert if conversion target is unknown
	else if (TF2Econ_GetItemLoadoutSlot(weaponIndex, playerClass) != -1) //class can equip
		return true; //weaponIndex already ok
	else if (!isNormal)
		return false; //don't try to convert special items
	
	int replaceWith = -1;
	DataPack pack = new DataPack();
	pack.WriteString(buffer);
	pack.WriteCell(playerClass);
	
	ArrayList items = TF2Econ_GetItemList(_TF2rpu_TF2EconItemFilter_ByClassnameAndPlayerclass, pack);
	delete pack;
	if (items.Length > 0) replaceWith = view_as<int>(items.Get(0));
	delete items;
	
	if (replaceWith >= 0) {
		weaponIndex = replaceWith;
		return true; //we now have a weapon with valid animations
	} else {
		return false; //no replacement for that class
	}
}

// loaded by roleplay.games
int droppedWeaponClipOffset,droppedWeaponAmmoOffset;

void ModelIndexToString(int index, char[] model, int size) {
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}
//int FindModelIndex(int weaponIndex) {
//	int table = FindStringTable("modelprecache");
//	char clzname[64];
//	char fullpath[255];
//	char buffer[255];
//	if (!TF2Econ_GetItemClassName(weaponIndex, clzname, sizeof(clzname))) return -1;
//	if (StrContains(clzname, "tf_weapon_")!=0) return -1;
//	Format(fullpath, sizeof(fullpath), "weapons\w_models\w_%s.mdl", clzname[10]); //trim 10 chars away of class name
//	//reverse lookup the string table
//	int max = GetStringTableNumStrings(table);
//	for (int i=0;i<max;i++) {
//		ReadStringTable(table, index, buffer, sizeof(buffer))
//	}
//}

/** tries to set some weapon active, preferably in the specified slot. if no weapon seems valid, it will give fists to prevent t-posing
 * @param preferedWeaponSlot valid from 0-2, will seach for a weapon otherwise
 */
bool Impl_TF2rpu_SetActiveWeapon(int client, int preferedWeaponSlot) {
	int weapon;
	int slotNext = -1;
	if ( (preferedWeaponSlot >= 0) && (preferedWeaponSlot < 3) && ((weapon=Client_GetWeaponBySlot(client, preferedWeaponSlot)) != INVALID_ENT_REFERENCE) ) {
		slotNext = preferedWeaponSlot;
	}
	if (slotNext == -1) {
		for (int i = 0; i < 3; i++) {
			if ((weapon=Client_GetWeaponBySlot(client, i)) != INVALID_ENT_REFERENCE) {
				slotNext = i;
				break;
			}
		}
	}
	if (slotNext == -1) {
		//could not find a weapon on the player
		weapon=_GiveWeapon(client, WEAPON_HANDS); //definition index 5 = fists
		slotNext = 2;
	}
	Client_SetActiveWeapon(client, weapon);
}

/** @return the item definition index for the currently active weapon or -1 on error */
int Impl_TF2rpu_GetActiveWeapon(int client) {
	if (!Client_IsValid(client) || !IsClientInGame(client)) return -1;
	int weapon = Client_GetActiveWeapon(client);
	if (Entity_IsValid(weapon)) {
		return Impl_TF2rpu_GetWeapondDefinitionIndex(weapon);
	} else return -1;
}

/** 
 * A copy of Client_GetWeapon that exposes the exact match parameter.
 * 
 * @param client        the client to search
 * @param classname     the (partial) classname to search for
 * @param partialMatch  set to true, if you want to allow partial matched match
 * @return  the weapon entity index, or -1 if no weapon of this class was found
 */
int Impl_TF2rpu_GetWeaponType(int client, const char[] classname, bool partialMatch=false) {
	int offset = Client_GetWeaponsOffset(client) - 4;
	int weapon = INVALID_ENT_REFERENCE;
	for (int i=0; i < MAX_WEAPONS; i++) {
		offset += 4;

		weapon = GetEntDataEnt2(client, offset);

		if (!Weapon_IsValid(weapon)) {
			continue;
		}

		if (Entity_ClassNameMatches(weapon, classname, partialMatch)) {
			return weapon;
		}
	}

	return INVALID_ENT_REFERENCE;
}

int Impl_TF2rpu_DropWeapon(int client, int weapon) {
	if (!Client_IsValid(client) || !Weapon_IsValid(weapon)) return -1;
	if (Entity_ClassNameMatches(weapon, "tf_weapon_fists")) return -1; //can't drop fists
	if (Impl_TF2rpu_IsPhysGun(weapon)) {
		if (IsPlayerAlive(client)) TF2_RemoveWeaponSlot(client,1);
		return -1; //cannot be dropped anyways
	}
	float origin[3], angles[3], velocity[3];
	int worldEntity, weaponIndex, wModelIndex, quality, clip, ammo;
	char wModel[PLATFORM_MAX_PATH];
	
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	GetAngleVectors(angles, velocity, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(velocity, 200.0);
	velocity[2]+=200;
	origin[2]-=24;
	
	weaponIndex = GetEntProp(weapon, Prop_Send, PROP_ITEMDEFINITIONINDEX);
//	level = GetEntProp(weapon, Prop_Send, PROP_ENTITYLEVEL);
	quality = GetEntProp(weapon, Prop_Send, PROP_ENTITYQUALITY);
	wModelIndex = GetEntProp(weapon, Prop_Send, PROP_WORLDMODELINDEX);
	ModelIndexToString(wModelIndex, wModel, sizeof(wModel));
	clip = Weapon_GetPrimaryClip(weapon);
	Client_GetWeaponPlayerAmmoEx(client, weapon, ammo);
	
	if ((worldEntity = Impl_TF2rpu_CreateDroppedWeapon(client, weaponIndex, wModel, quality, clip, ammo, origin, angles, velocity)) > 0) {
		if (IsPlayerAlive(client)) TF2_RemoveWeaponSlot(client, _CheckWeaponSlot(weaponIndex,TF2_GetPlayerClass(client)) );
		return worldEntity;
	}
	return -1;
}

int Impl_TF2rpu_SpawnWeaponAt(int client, int weaponDefinitionIndex) {
	if (!Client_IsValid(client)) return -1;
	char classname[64];
	char fullpath[PLATFORM_MAX_PATH];
	int quality;
	int clip, ammo=0;
	float origin[3], angles[3];
	//fetch tf2econ data
	if (!TF2Econ_GetItemClassName(weaponDefinitionIndex, classname, sizeof(classname))) return -1;
	quality = TF2Econ_GetItemQuality(weaponDefinitionIndex);
	//guess world model path
	if (!String_StartsWith(classname, "tf_weapon_")) return -1;
	Format(fullpath, sizeof(fullpath), "models/weapons/c_models/c_%s/c_%s.mdl", classname[10], classname[10]); //trim 10 chars away of class name
	if (!IsModelPrecached(fullpath)) return -1; //guessing the model path failed / should not require caching
	//fetch ammo
	clip = Impl_TF2rpu_GetMaxAmmo(classname);
	if (Impl_TF2rpu_HasAmmo(classname)) { ammo=clip;clip=0; }
	//where to spawn the weapon
	GetClientEyePosition(client, origin);
	GetClientEyeAngles(client, angles);
	origin[2]-=24;
	//spawn it
	return Impl_TF2rpu_CreateDroppedWeapon(client, weaponDefinitionIndex, fullpath, quality, clip, ammo, origin, angles, NULL_VECTOR);
}

int Impl_TF2rpu_CreateDroppedWeapon(int client, int weaponDefinitionIndex, const char[] worldModel, int quality, int clip, int ammo, const float origin[3], const float angles[3], const float velocity[3]) {
//	if (!gcSpawnCheck()) return -1;
	int entity = CreateEntityByName("tf_dropped_weapon");
	SetEntProp(entity, Prop_Send, PROP_ITEMDEFINITIONINDEX, weaponDefinitionIndex);
	SetEntProp(entity, Prop_Send, PROP_ENTITYLEVEL, -127);
	SetEntProp(entity, Prop_Send, PROP_ENTITYQUALITY, quality);
	SetEntProp(entity, Prop_Send, PROP_ACCOUNTID, GetSteamAccountID(client));
	SetEntProp(entity, Prop_Send, "m_bInitialized", 1);
	TeleportEntity(entity, origin, angles, velocity);
	SetEntityModel(entity, worldModel);
	DispatchSpawn(entity);
	TeleportEntity(entity, origin, angles, velocity);
	SetEntData(entity, droppedWeaponClipOffset, clip, _, true);
	SetEntData(entity, droppedWeaponAmmoOffset, ammo, _, true);
	//PrintToServer("Weapon properties: wdi:%i wmi:%i lvl:%i qty:%i ammo:%i/%i", weaponDefinitionIndex, worldModelIndex, level, quality, clip, ammo);
	return entity;
}

// replacement for TF2Items_GiveWeapons TF2Items_CheckWeaponSlot
tf2WeaponSlot _CheckWeaponSlot( int itemIndex, TFClassType class = TFClass_Unknown ) {
	if (!TF2Econ_IsValidItemDefinition(itemIndex)) return TF2WeaponSlot_Unknown;
	int loadoutSlot = TF2Econ_GetItemLoadoutSlot(itemIndex, class);
	if (loadoutSlot < 0) {
		loadoutSlot = TF2Econ_GetItemDefaultLoadoutSlot(itemIndex);
	}
	char slotname[12];
	TF2Econ_TranslateLoadoutSlotIndexToName(loadoutSlot, slotname, sizeof(slotname));
//	char weaponclass[64];
//	TF2Econ_GetItemClassName(itemIndex, weaponclass, sizeof(weaponclass));
//	if( StrContains(weaponclass, "tf_weapon_")!=0 ) return -1;
	
	if( StrEqual( slotname, "primary", false ) )
		return TF2WeaponSlot_Main;
	else if( StrEqual( slotname, "secondary", false ) )
		return ( class == TFClass_Spy ) ? TF2WeaponSlot_Main : TF2WeaponSlot_Side ;
	else if( StrEqual( slotname, "melee", false ) )
		return TF2WeaponSlot_Melee;
	else if( StrEqual( slotname, "pda", false ) )
		return TF2WeaponSlot_PDA;
	else if( StrEqual( slotname, "pda2", false ) )
		return TF2WeaponSlot_PDA2;
	else if( StrEqual( slotname, "building", false ) )
		return ( class == TFClass_Spy ) ? TF2WeaponSlot_Side : TF2WeaponSlot_Building ;
//	else if( StrEqual( slotname, "action", false ) )
//		return 7;
	else
		return TF2WeaponSlot_Unknown;
}

// replacement for TF2Items_GiveWeapons TF2Items_GiveWeapon
int _GiveWeapon(int client, int itemIndex) {
	//based on https://forums.alliedmods.net/showthread.php?p=1353985
	
//	if (!TF2Econ_IsValidItemDefinition(itemIndex)) return INVALID_ENT_REFERENCE;
	TFClassType playerClass = TF2_GetPlayerClass(client);
	
	char classname[96];
	if (!TF2Econ_GetItemClassName(itemIndex, classname, sizeof(classname))) return INVALID_ENT_REFERENCE;
	if (StrContains(classname, "tf_weapon_")!=0 && !StrEqual(classname,"tf_wearable") && !StrEqual(classname,"saxxy")) return INVALID_ENT_REFERENCE; //start with
	if (!TF2Econ_TranslateWeaponEntForClass(classname, sizeof(classname), playerClass)) return INVALID_ENT_REFERENCE;
	
	tf2WeaponSlot weaponSlot = _CheckWeaponSlot( itemIndex, playerClass );
	if (weaponSlot == TF2WeaponSlot_Unknown) return INVALID_ENT_REFERENCE; // can not assign a weapon slot
	
	Handle newItem = TF2Items_CreateItem(OVERRIDE_ALL);
	int Flags = 0;
	
	TF2Items_SetItemIndex(newItem, itemIndex);
	
	int lvMin, lvMax;
	TF2Econ_GetItemLevelRange(itemIndex, lvMin, lvMax);
	TF2Items_SetLevel(newItem, lvMin);
	Flags |= OVERRIDE_ITEM_LEVEL;
	
	TF2Items_SetQuality(newItem, TF2Econ_GetItemQuality(itemIndex));
	Flags |= OVERRIDE_ITEM_QUALITY;
	
	Flags |= PRESERVE_ATTRIBUTES;
	TF2Items_SetFlags(newItem, Flags);
	
	TF2Items_SetClassname(newItem, classname);
	
	TF2_RemoveWeaponSlot(client, weaponSlot);
	int entity = TF2Items_GiveNamedItem(client, newItem);
	delete newItem;
	if (IsValidEntity(entity)) {
		EquipPlayerWeapon(client, entity);
	}
	
	return entity;
}