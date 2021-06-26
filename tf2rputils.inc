#if defined _inc_tf2rpu
#endinput
#endif
#define _inc_tf2rpu

#include <tf2>

enum tf2WeaponSlot { //lower case for implicit int conversion
	TF2WeaponSlot_Unknown = -1,
	TF2WeaponSlot_Main, //main weapon, mostly primary, but secondary for spy
	TF2WeaponSlot_Side, //side weapon, mostly secondaries, but sapper for spy
	TF2WeaponSlot_Melee, //melee weapons
	TF2WeaponSlot_Building = 4, //probably shouldn't be replaced, used for holding a constuction blueprint
	TF2WeaponSlot_PDA,
	TF2WeaponSlot_PDA2
};

// --== FORWARDS ==--

/**
 * Notifies you when a client tries to actively drop a weapon.
 * 
 * @param client          the player
 * @param weapon          the weapon entity
 * @param definitionIndex the item definition index of the weapon
 * @return Plugin_Handled to prevent the weapon from being removed
 */
forward Action TF2rpu_OnClientDropWeapon(int client, int weapon, int definitionIndex);

/**
 * Notifies you when a player owned weapon would be spawned. Fires on death drops as well.
 * Use this forward to prevent the dropped weapon from spawning.
 * 
 * @param client          the player
 * @param weapon          the weapon entity
 * @param definitionIndex the item definition index of the weapon
 * @return Plugin_Handled to prevent the weapon from spawning
 */
forward Action TF2rpu_OnClientDroppedWeaponSpawn(int client, int weapon, int definitionIndex);

/**
 * Notifies you that a weapon was removed (Post) by actively dropping it.
 * 
 * @param client          the player
 * @param weapon          the weapon entity
 * @param definitionIndex the item definition index of the weapon
 * @noreturn
 */
forward void TF2rpu_OnClientDropWeaponPost(int client, int weapon, int definitionIndex);

/**
 * Notifies you when a client tries to pick up a weapon.
 * 
 * @param client          the player
 * @param weapon          the weapon entity
 * @param definitionIndex the item definition index of the weapon
 * @return Plugin_Handled to prevent the weapon from being taken
 */
forward Action TF2rpu_OnClientPickupWeapon(int client, int weapon, int definitionIndex);

/**
 * Notifies you when a client picked up a weapon.
 * 
 * @param client          the player
 * @param weapon          the weapon entity
 * @param definitionIndex the item definition index of the weapon
 * @noreturn
 */
forward void TF2rpu_OnClientPickupWeaponPost(int client, int weapon, int definitionIndex);

/**
 * Notifies you that a client wants to switch to a specific class.
 * Meant to be used for instant class switching, but can be used to block single classes.
 * 
 * This is fired from withing the class change command hooks. 
 * Plugins can still assign arbitrary classes without triggering hooks!
 * 
 * @param class unknown denotes a random class
 */
forward Action TF2rpu_OnClientClassChangePre(int client, TFClassType& class);
/**
 * Notifies that the player will now be assigned the new class, followed by a respawn.
 * I require this notif to prepare some flags in the roleplay plugin.
 * 
 * Like pre, this is still fired from within the class change command hook.
 */
forward void TF2rpu_OnClientClassChange(int client, TFClassType class);
/**
 * Specifically notifies you one tick after the client respawned, that the class change is done.
 * I again need this in the roleplay plugin to further process the changed class.
 */
forward void TF2rpu_OnClientClassChangePost(int client, TFClassType class);

/**
 * Called when the player holsters a weapon, or -1 if they unholster
 */
forward void TF2rpu_OnClientHolsterWeapon(int client, int definitionIndex);

// --== NATIVES ==--

/**
 * Tries to estimate the slot for stock WeaponSlot function.
 * This function fails on non-weapon items
 * 
 * @param weaponIndex  the weapon to check
 * @param playerclass  some items use different slots depending on playerclass
 * @return slot index or -1 if not supported.
 */
native tf2WeaponSlot TF2rpu_GetWeaponSlot(int weaponIndex, TFClassType playerclass = TFClass_Unknown);

/**
 * Holster or unholster weapons. It's important to drop the holstered Weapon, if
 * admins give the client a new melee. Otherwise the new melee would be
 * immediately replaced with the holstered weapon.
 * 
 * @param client   the client to holster a weapon from
 * @param holser   true to holser, false to unholster
 * @param dropHolser if true and unholster, the holstered weapon will not be restored
 */
native void TF2rpu_ClientHolsterWeapon(int client, bool holster, bool dropHolster=false);
/**
 * Retrieves the weapon definition index of the melee weapon, currently hosltered by this client.
 * The equipped/active melee weapon while having a holstered weapon is 5 for Hands to prevent T-Posing.
 * 
 * @param client   the client to holster a weapon from
 * @return the holstered weapons definition index or -1 if unholstered
 */
native int TF2rpu_GetClientHolsteredWeapon(int client);

/**
 * Get the weapon definition index unchecked.
 * 
 * @throw invalid entity or property not found
 */
native int TF2rpu_GetWeapondDefinitionIndex(int weapon);

/**
 * Tries to generify the weapon class name. since the generic name is usually shorter
 * it will write back into the same var.
 * This function is mainly important for the class weapon converter
 */
native void TF2rpu_GenerifyWeaponClass(char[] classname, int maxlen);

/**
 * Gives the weapon by definition index and optionally (default) switches to it
 * 
 * @param client                 The client to give a weapon
 * @param weaponDefinitionIndex  The weapon to give
 * @param switchTo               true if the player should switch to the weapon
 * @return weapon entity ref or -1
 */
native int TF2rpu_GiveWeaponEx(int client, int weaponDefinitionIndex, bool switchTo=true);

/**
 * @param classname the weapon classname to check. Should be the generic classname
 * @return the weapon definition index for the base weapon based on the weapon class name or -1 if none was found
 */
native int TF2rpu_GetDefaultIndexFromWeaponClass(const char[] classname);

/**
 * Get's a default weapon index for the provided weapon classname, converts that into a
 * player class variant if applicable and gives the weapon to the client.
 * 
 * @param client    The client to bless with a gun
 * @param classname Weapon classname to look up
 * @return The weapon entity given to the player
 */
native int TF2rpu_GiveWeapon(int client, const char[] classname);

/**
 * Like Client_GetWeapon, but checks for the weapon definition index, instead
 * of the weapon class name.
 * 
 * @param client the client to check
 * @param weaponIndex the weapon definition index to search
 * @return weapon or INVALID_ENT_REFERENCE if the player does not have that weapon
 */
native int TF2rpu_GetWeapon(int client, int weaponIndex);

/**
 * return the max ammo per weapon ignoring the clip
 * carefull with the tf_weapon_flamethrower tf_weapon_minigun tf_weapon_sniperrifle, it does not have ammo, the returned value there will be clip
 * NOTE: Some weapon classname append the player class despite the classname listed in the wiki, so use StrContains()==0 when uncertain
 * Additionally, class differences like the engineers 200 pistol ammo is ignored in favour of the smaller limit.
 * @return max ammo, 0 if not available, -1 if weapon not recognized (not all available classes are recognizes, e.g. meele, because that'd only waste time)
 */
native int TF2rpu_GetMaxAmmo(const char[] classname);
/**
 * @param weapon entity
 * @return true if this weapon has ammo, false if only clip
 * @error if the entities supplied is not a weapon
 */
native bool TF2rpu_HasAmmoEntity(int weapon);
/**
 * @return true, if the weapon class has ammo to refill the clip
 */
native bool TF2rpu_HasAmmo(const char[] classname);

/**
 * Retrieving the weapons classname by index and (if applicable) converts a weapon into a normal tier
 * compatible weapon for the specified class.
 * if playerClass is TF2Class_Unknown, only the classname will be extracted.
 * 
 * @param weaponIndex   The weapon to analyze, writes back the modified weaponIndex
 * @param playerClass   The class to convert weapons to, if applicable (currently shotgun,pistol)
 * @param classname     Extracts the weapons classname
 * @param sz_classname  sizeof(classname)
 * @return true iif after conversion, the weaponIndex is supprted by the specified playerClass
 */
native bool TF2rpu_WeaponConvertCompatible(int& weaponIndex, TFClassType playerClass=TFClass_Unknown, char classname[]="", int sz_classname=0);

/** 
 * Tries to set some weapon active, preferably in the specified slot. if no weapon seems valid, it will give fists to prevent t-posing
 * @param client             The client to set the active weapon on 
 * @param preferedWeaponSlot Valid from 0-2, will seach for a weapon otherwise
 * @noreturn
 */
native void TF2rpu_SetActiveWeapon(int client, int preferedWeaponSlot);

/**
 * @param client  The client to get the active weapon from
 * @return the item definition index for the currently active weapon or -1 on error 
 */
native int TF2rpu_GetActiveWeapon(int client);

/** 
 * A copy of Client_GetWeapon that exposes the exact match parameter.
 * 
 * @param client        The client to search
 * @param classname     The (partial) classname to search for
 * @param partialMatch  Set to true, if you want to allow partial matched match
 * @return              The weapon entity index, or -1 if no weapon of this class was found
 */
native int TF2rpu_GetWeaponType(int client, const char[] classname, bool partialMatch=false);

/**
 * Force a client to drop a weapon, unless it's fists.
 * The physgun is removed but not dropped.
 * Preserves most weapon attributes when dropping.
 * 
 * @param client  The player to remove the weapon from
 * @param weapon  The weapon to remove by entity ref
 * @return        The entity ref of the dropped weapon or -1
 */
native int TF2rpu_DropWeapon(int client, int weapon);

/**
 * Create a spawned weapon, marked as previously owned by the client, at the client with as much default values as possible
 * 
 * @param client                 The client to spawn the weapon at
 * @param weaponDefinitionIndex  What weapon to spawn
 * @return                       The weapon ent ref or -1
 */
native int TF2rpu_SpawnWeaponAt(int client, int weaponDefinitionIndex);

/**
 * Create a spawned weapon in the world. The weapons level is fixed to -127!
 * 
 * @param client                 The player that will be assigned as the former owner of this weapon
 * @param weaponDefinitionIndex  The weapon to create by index
 * @param worldModel             The world model to assign the model (not automatically looked up)
 * @param quality                Set the weapons quality
 * @param clip                   The primary clip value for this weapons
 * @param ammo                   The primary ammo value for this weapons
 * @param origin                 Where to spawn the weapon
 * @param angles                 The orientation to spawn it with
 * @param velocity               The velocity to apply to the weapon
 * @return                       The weapon entity ref or -1 if edict limit is reached
 */ 
native int TF2rpu_CreateDroppedWeapon(int client, int weaponDefinitionIndex, const char[] worldModel, int quality, int clip, int ammo, const float origin[3], const float angles[3], const float velocity[3]);

/**
 * For a player into one of the specified player classes
 * if they're not already in one of them
 * 
 * @param client   the client to change class
 * @param classes  bit array of (1<<TFClassType) that the client should have
 */
native void TF2rpu_ForcePlayerClass(int client, int classes);

/**
 * set or clear the playermodel (similar to tf2 mm)
 * @param model the model path or empty string to clear
 */
native void TF2rpu_SetClientModel(int client, const char[] model);

//phys cannon detection copied from tf2 physics gun as they don't provide an include
/**
 * @return true if the client is currently holding the physgun
 */
native bool TF2rpu_ClientPhysGunActive(int client);
/** 
 * @param weaponIndex  [out] the definition index of the weapon (or -1 if invalid)
 * @return true if the weapon is the phys gun
 */
native bool TF2rpu_IsPhysGun(int weapon, int& weaponIndex=-1);

/**
 * Does what it sais, reverse of Client_ShowScoreboard
 */
native void TF2rpu_HideScoreboard(int client, int flags = USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

/**
 * Displays a HudNotification (centered, bottom half) for the client
 * This element will NOT show with minimal hud!
 * https://forums.alliedmods.net/showthread.php?t=155911
 * @param client  The target player
 * @param icon    Icon name taken from mod_textures.txt (does not always resize correctly)
 * @param background (Use a TFTeam or -1 for client team color)
 * @param stripMoreColors set true to remove colors that might have been used in translation files
 * @param message (+ format)
 */
native void TF2rpu_HudNotificationCustom(int client, const char[] icon="voice_self", int background=-1, bool stripMoreColors=false, const char[] message, any ...);
/**
 * Displays a HudNotification (centered, bottom half) for all client
 * This element will NOT show with minimal hud!
 * https://forums.alliedmods.net/showthread.php?t=155911
 * @param icon    Icon name taken from mod_textures.txt (does not always resize correctly)
 * @param background (Use a TFTeam or -1 for client team color)
 * @param stripMoreColors set true to remove colors that might have been used in translation files
 * @param message (+ format)
 */
native void TF2rpu_HudNotificationCustomAll(const char[] icon="voice_self", int background=-1, bool stripMoreColors=false, const char[] message, any ...);

/** 
 * Set the players health (and optionally max health).
 * Use -1 for health if you don't want to change the hp
 * Has to be called once (spawn-)loadout is finalized, otherwise weapon attribts might overwrite
 * 
 * @param client       The client to poke around with
 * @param health       The new health value to set (ignores max health) or -1
 * @param maxhealth    New max health for the player (or -1 to not change)
 * @param disableDecy  Set true if you want to freeze the overheal decay at health
 * @noreturn
 */
native void TF2rpu_SetHealthEx(int client, int health=-1, int maxhealth=-1, bool disableDecay=false);

/**
 * Get the client's max health from the player resource manager.
 * This value is not always totally accurate, but works for most instances
 */
native int TF2rpu_GetClientMaxHealth(int client);

/**
 * Change client max health, tries to keep the current hp in case max hp increases and prevents overcharge by capping hp to the new max.
 * If you want to increase hp and max hp use TF2rpu_SetHealthEx(client, hp, hp)
 * Has to be called once (spawn-)loadout is finalized, otherwise weapon attribts might overwrite
 */
native void TF2rpu_SetClientMaxHealth(int client, int maxhealth);

/**
 * Removes all max health related attributes from a player
 */
native void TF2rpu_ResetMaxHealth(int client);

/**
 * Opposite of Client_ShowScoreboard
 */
native void TF2rpu_ClientHideScoreboard(int client, int flags = USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);

// --== Yay, CursorAnnotations for everyone ==--

/** Maximum length of an annotation message */
#define MAX_ANNOTATION_LENGTH 256

/**
 * While an annotation is not a handle, you can remove it by calling Close. You can not however use delete.
 * Changing any values will require you to call send, in order for the clients to receive the updated information.
 */
methodmap CursorAnnotation {
	
	/**
	 * Only use index and reset if you know what you're doing!
	 * 
	 * @param index  -1 to automatically find initialize an unused index, otherwise re-wraps the index
	 * @param reset  if index > 0 and the annotation is in use it will reset all values anyways
	 */
	public native CursorAnnotation(int index = -1, bool reset=false);
	
	public native void Close();
	property bool IsValid { 
		public native get();
	}
	
	/**
	 * set the visibility for a specific player;
	 */
	public native void SetVisibilityFor(int client, bool visible=true);
	/**
	 * set the visibility of this annotation for all players
	 */
	public native void SetVisibilityAll(bool visible);
	/**
	 * with a maximum of 32 players, this bitmask represents the client that can see this annotation
	 */
	property int VisibilityBitmask {
		public native get();
		public native set(int value);
	}
	/**
	 * Some additional data you can attach to the annotation
	 */
	property any Data {
		public native get();
		public native set(any value);
	}
	/** 
	 * Set the text for this annotation. Checks if the new message differs from the previously buffered to prevent flickering.
	 * @return true if the supplied text was different
	 */
	public native bool SetText(const char[] text);
	/**
	 * Set the position of this cursor annotation. Dunno if it can be used as offset to the parent entity.
	 */
	public native void SetPosition(const float vec[3]);
	/**
	 * Get the position of this cursor annotation. Dunno if it can be used as offset to the parent entity.
	 */
	public native void GetPosition(float vec[3]);
	/**
	 * Set the lifetime for this annotation in seconds. 
	 * Set it super high if you don't want it to go away. (1800.0 = 30 min)
	 */
	public native void SetLifetime(float lifetime);
	/**
	 * The Parent Entity is the Entity that this annotation follows
	 */
	property int ParentEntity {
		public native get();
		public native set(int value);
	}
	
	/** 
	 * Tries to estimate whether this annotation is currently "delivered"/playing
	 * using the annotations lifetime and the update/hide methods
	 */
	property bool IsPlaying { 
		public native get();
	}
	/**
	 * Update and show the annotation according to the currently set up data
	 * 
	 * @param sound the sound to play along the annotation
	 * @param showEffect emits a green radial becon
	 */
	public native void Update(const char[] sound = "misc/null.wav", bool showEffect=false);
	/**
	 * hides this annotation form all, until Update is called again
	 */
	public native void Hide();
}

public SharedPlugin __pl_tf2rputils = 
{
    name = "tf2rpu",
    file = "tf2rputils.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};