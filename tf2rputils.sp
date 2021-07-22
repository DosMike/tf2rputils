#if defined _natives_TF2RPUtils
 #endinput
#endif
#define _natives_TF2RPUtils

#define GAMEDATA_FILE_NAME "roleplay.games"

#define PROP_ITEMDEFINITIONINDEX "m_iItemDefinitionIndex"
#define PROP_ACCOUNTID "m_iAccountID"
#define PROP_ENTITYLEVEL "m_iEntityLevel"
#define PROP_ENTITYQUALITY "m_iEntityQuality"
#define PROP_WORLDMODELINDEX "m_iWorldModelIndex"

// see items/items_game.txt - i don't want to query for a name that might change to get the normal quality
#define TF2Econ_DefaultRarityNormal 0

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <smlib>
#include "morecolors.inc"

#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <tf_econ_data>
#include "tf2hudmsg.inc"

// --== CONVARS ==--

ConVar cvar_WeaponDrop;
ConVar cvar_WeaponDropCommands;
ConVar cvar_WeaponDropNoAmmo;
ConVar cvar_WeaponPickup;
ConVar cvar_WeaponPickupIgnoreClass;
ConVar cvar_WeaponHolster;
ConVar cvar_WeaponHolsterNoFistdamage;
ConVar cvar_InstantClass;
ConVar cvar_InstantClassForceHealth;

// --== FORWARDS ==--

GlobalForward gfwd_ClientHolsterWeapon;
GlobalForward gfwd_ClientDropWeaponCheck;
GlobalForward gfwd_DroppedWeaponSpawn;
GlobalForward gfwd_ClientDropWeaponPost;
GlobalForward gfwd_ClientPickupWeaponCheck;
GlobalForward gfwd_ClientPickupWeaponPost;
GlobalForward gfwd_ClientClassChangePre;
GlobalForward gfwd_ClientClassChange;
GlobalForward gfwd_ClientClassChangePost;

// --== IMPLEMENTATION ==--

#include "tf2utils/uWeapons.inc"
#include "tf2utils/uHealth.inc"
#include "tf2utils/uMisc.inc"

#include "tf2rpu_weapons.sp"
#include "tf2rpu_instantclass.sp"
#include "tf2rpu_commands.sp"

// Some usefull links:
// all dumps: https://github.com/powerlord/tf2-data

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = {
	name = "[TF2] RP Utils",
	author = "reBane",
	description = "Library providing TF2 functions for my own (in)sanity",
	version = "21w29a",
	url = "N/A"
}

public void OnPluginStart() {
	
	GameData gamedata = LoadGameConfigFile(GAMEDATA_FILE_NAME);
	if (gamedata != INVALID_HANDLE) {
		droppedWeaponClipOffset = gamedata.GetOffset("DroppedWeaponClip");
		droppedWeaponAmmoOffset = gamedata.GetOffset("DroppedWeaponAmmo");
		delete gamedata;
	}
	
	LoadTranslations("tf2rpu.phrases");
	LoadTranslations("common.phrases");
	
	cvar_WeaponDrop =                CreateConVar("tfrpu_weapondrop_enable", "0", "Enables the weapon drop system", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_WeaponDropCommands =        CreateConVar("tfrpu_weapondrop_command", "2", "Allows players to actively drop weapons, value 2 will allow only admin", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvar_WeaponDropNoAmmo =          CreateConVar("tfrpu_weapondrop_noammo", "1", "Disable ammo boxes from dropping", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_WeaponPickup =              CreateConVar("tfrpu_weaponpickup_enable", "0", "Allow players to pick up weapons from the ground with +use", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_WeaponPickupIgnoreClass =   CreateConVar("tfrpu_weaponpickup_ignoreclass", "0", "Any player can pick up any weapons on the ground, value 2 will allow only admin", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvar_WeaponHolster =             CreateConVar("tfrpu_weaponholster_enable", "0", "Players can use !holster to put their melee away", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_WeaponHolsterNoFistdamage = CreateConVar("tfrpu_weaponholster_nodamage", "1", "Fists (given by !holster) do not deal any damage", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_InstantClass =              CreateConVar("tfrpu_instantclass_enable", "0", "Allows players to change class without cooldown / death, value 2 will only enable this for admins", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	cvar_InstantClassForceHealth =   CreateConVar("tfrpu_instantclass_keephp", "1", "Changin class does not heal, but \"duck\" hp to the new max, value 2 will on apply to non-admins", FCVAR_ARCHIVE|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	
	gfwd_ClientHolsterWeapon =     new GlobalForward("TF2rpu_OnClientHolsterWeapon", ET_Ignore, Param_Cell, Param_Cell);
	gfwd_ClientDropWeaponCheck =   new GlobalForward("TF2rpu_OnClientDropWeapon", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	gfwd_DroppedWeaponSpawn =      new GlobalForward("TF2rpu_OnClientDroppedWeaponSpawn", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	gfwd_ClientDropWeaponPost =    new GlobalForward("TF2rpu_OnClientDropWeaponPost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	gfwd_ClientPickupWeaponCheck = new GlobalForward("TF2rpu_OnClientPickupWeapon", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	gfwd_ClientPickupWeaponPost =  new GlobalForward("TF2rpu_OnClientPickupWeaponPost", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	gfwd_ClientClassChangePre =    new GlobalForward("TF2rpu_OnClientClassChangePre", ET_Event, Param_Cell, Param_CellByRef);
	gfwd_ClientClassChange =       new GlobalForward("TF2rpu_OnClientClassChange", ET_Ignore, Param_Cell, Param_Cell);
	gfwd_ClientClassChangePost =   new GlobalForward("TF2rpu_OnClientClassChangePost", ET_Ignore, Param_Cell, Param_Cell);
	
	AddCommandListener(commandDropItem, "dropitem");
	AddCommandListener(commandChangeClass, "changeclass");
	AddCommandListener(commandChangeClass, "joinclass");
	AddCommandListener(commandChangeClass, "join_class");
	
	RegConsoleCmd("sm_dropweapon", commandDropWeapon, "Drop the weapon you're currently holding");
	RegConsoleCmd("sm_dropit",     commandDropWeapon, "Drop the weapon you're currently holding");
	RegConsoleCmd("sm_hands",      commandHolsterWeapon, "Put your weapons away and show hands");
	RegConsoleCmd("sm_holster",    commandHolsterWeapon, "Put your weapons away and show hands");
	RegAdminCmd("sm_spawnweapon",  commandCreateDroppedWeapon, ADMFLAG_CHEATS, "Create a weapon and drop it in the world - Only supports normal rarity items");
	RegAdminCmd("sm_spawngun",     commandCreateDroppedWeapon, ADMFLAG_CHEATS, "Create a weapon and drop it in the world - Only supports normal rarity items");
	RegAdminCmd("sm_resupply",     commandRegenerateSelf, ADMFLAG_CHEATS, "<#userid|name> - Regenerate yourself as if you used a resupply locker");
	//were originally placed in roleplay
	RegAdminCmd("sm_give",         commandGiveWeapon, ADMFLAG_CHEATS, "<#userid|name> <weapon> - Weapon is the item index or classname, tf_weapon_ is optional");
	RegAdminCmd("sm_fakegive",     commandGiveWeapon, ADMFLAG_CHEATS, "<#userid|name> <weapon> - Pretends to give a weapon");
	RegAdminCmd("sm_god",          commandGod, ADMFLAG_ROOT, "<#userid|name> <1/0> - Enables or disables god mode on a player");
	RegAdminCmd("sm_hp",           commandHp, ADMFLAG_ROOT, "<#userid|name> <health|'RESET'> ['MAX'|'FIX'] - Sets health of a player, FIX will prevent overheal decay");
	
	HookEvent("player_death", Event_ClientDeathPost);
	HookEvent("post_inventory_application", Event_ClientInventoryRegeneratePost);
	
	for(int i = 1; i <= MaxClients; i++) {
		if (!IsClientConnected(i)) continue;
		initializeClientVars(i);
		if (!IsClientInGame(i)) continue;
		hookClient(i);
	}
}

public void OnPluginEnd() {
	for(int i = 1; i <= MaxClients; i++) {
		if (Client_IsIngame(i)) {
			Impl_TF2rpu_ClientHolsterWeapon(i,false,true);
			Impl_TF2rpu_ResetMaxHealth(i);
		}
	}
}

public void OnGameFrame() {
	_TF2rpu_thinkOverheal();
}

public void OnClientAuthorized(int client, const char[] auth) {
	initializeClientVars(client);
}


public void OnClientDisconnect(int client) {
	initializeClientVars(client);
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (!IsValidEntity(entity)) return;
	
	if (StrEqual(classname, "player")) {
		hookClient(entity);
	} else if (IsValidEntity(entity) && StrEqual(classname, "tf_ammo_pack") && cvar_WeaponDropNoAmmo.BoolValue) {
		if (GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity")) // returns the client that dropped this ammo pack to not remove map ammo
			AcceptEntityInput(entity, "kill");
	} else if (StrEqual(classname, "tf_dropped_weapon") && cvar_WeaponDrop.BoolValue) {
		SDKHook(entity, SDKHook_SpawnPost, Event_WeaponDroppedPost);
	}
}

public Action OnClientCommandKeyValues(int client, KeyValues kvCommand) {
    char command[64];
    kvCommand.GetSectionName(command,sizeof(command));
    if (StrEqual(command,"+use_action_slot_item_server")) {
    	int entity = getClientViewTarget(client);
    	if (entity > 0 && pickUpWeapon(client, entity)) {
    		return Plugin_Handled;
    	}
    }
    return Plugin_Continue;
}

bool canClientContinue(int client, ConVar convar, bool membersOn2=false) {
	bool isAdmin = Client_IsAdmin(client);
	int active = convar.IntValue;
	if (active==2) return (isAdmin^membersOn2); //normally admins pass, with membersOn2 only normal players pass
	else return !!active;
}

char[] formatted(int client, const char[] format, any...) {
	SetGlobalTransTarget(client);
	char buf[MAX_MESSAGE_LENGTH];
	VFormat(buf, MAX_MESSAGE_LENGTH, format, 3);
	return buf;
}

void initializeClientVars(int client) {
	clientWeaponsHolstered[client] = false;
	isClientOverheal[client] = false;
	clientClassChange[client] = false;
}

void hookClient(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, Event_ClientTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamagePost, Event_ClientTakeDamagePost);
	SDKHook(client, SDKHook_PreThinkPost, Event_ClientPreThinkPost);
	SDKHook(client, SDKHook_SpawnPost, Event_ClientSpawnPost);
	SDKHook(client, SDKHook_WeaponSwitchPost, Event_ClientWeaponSwitchPost);
}

void clientRegen(int client) {
	if (!Client_IsIngame(client)) return;
	isClientOverheal[client] = false;
	Impl_TF2rpu_ClientHolsterWeapon(client, false, true);
}

public bool hitSelfFilter(int entity, int contentsMask, any data) {
	return entity != data;
}

int getClientViewTarget(int client, bool &didHit = false, float hitPos[3] = {0.0, 0.0, 0.0}, int flags = MASK_SOLID) {
	float pos[3], angles[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angles);
	Handle trace = TR_TraceRayFilterEx(pos, angles, flags, RayType_Infinite, hitSelfFilter, client);
	int result;
	if(!(result = TR_GetEntityIndex(trace))) { // bypass worldspawn
		result = -1;
	}
	didHit = TR_DidHit(trace);
	TR_GetEndPosition(hitPos, trace);
	delete trace;
	return result;
}

public void Event_ClientSpawnPost(int client) {
	clientRegen(client);
	if (TF2_GetPlayerClass(client) == TFClass_Unknown) return;
	if(!IsFakeClient(client)) {
		if (clientClassChange[client]) {
			TeleportEntity(client, clientForcedRespawnLocation[client][0], clientForcedRespawnLocation[client][1], NULL_VECTOR);
			
			if (clientForcedRespawnHealth[client]>0) {
				//forced respawn health should only apply when class changing
				Impl_TF2rpu_SetHealthEx(client, clientForcedRespawnHealth[client]);
				clientForcedRespawnHealth[client] = -1;
			}
			
			RequestFrame(TF2rpu_NotifyPostClassChangeRespawn, client);
		}
	}
	clientClassChangeTime[client] = GetGameTime(); //preven quick change after spawn
	clientClassChange[client] = false;
}

public void Event_ClientInventoryRegeneratePost(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	clientRegen(client);
}

public void Event_ClientPreThinkPost(int client) { // ALL BUTTONS https://sm.alliedmods.net/api/index.php?fastload=file&id=47&
	static int prevButtons[MAXPLAYERS + 1];
	int buttons = GetClientButtons(client);
	int entityDefaultMask = getClientViewTarget(client);
	
	if(IsPlayerAlive(client)) {
		if((buttons & IN_USE) && !(prevButtons[client] & IN_USE)) {
			if(entityDefaultMask != -1) {
				pickUpWeapon(client, entityDefaultMask);
			}
		}		
		prevButtons[client] = buttons;
	}
}

public void Event_ClientDeathPost(Event event, const char[] name, bool dontBroadcast) {
	int victim = GetClientOfUserId(event.GetInt("userid", 0));
	clientDeath(victim); // probably not required
}

public void Event_ClientTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup) {
	if(GetClientHealth(victim) > 0) { // alive
		_TF2rpu_damageOverheal(victim, RoundToNearest(damage)); //update "no-overheal" decay value
	} else {
		clientDeath(victim);
	}
}

void clientDeath(int client) {
	Impl_TF2rpu_ResetMaxHealth(client);
	if (cvar_WeaponDrop.BoolValue && !clientClassChange[client]) {
		int weapon = Client_GetActiveWeapon(client);
		if (Entity_IsValid(weapon)) {
			Impl_TF2rpu_DropWeapon(client, weapon);
		}
	}
}

void Event_WeaponDroppedPost(int entity) {
	int accountId = GetEntProp(entity, Prop_Send, PROP_ACCOUNTID);
	int level = GetEntProp(entity, Prop_Send, PROP_ENTITYLEVEL);
	//illegal spawn when weapon dropped on death. custom logic will spawn another weapon with account id attached
	if (accountId == 0 || level > 0) {
		AcceptEntityInput(entity, "kill");
		return;
	}
	//map account id on weapon to client
	int client = -1;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && (GetSteamAccountID(i)==accountId))
			client = i;
	
	if (client == -1) { //invalid client/accountid?
		AcceptEntityInput(entity, "Kill"); //don't drop weapon
		return;
	}
	
	if (!Fire_DroppedWeaponSpawn(client, entity, Impl_TF2rpu_GetWeapondDefinitionIndex(entity))) {
		AcceptEntityInput(entity, "Kill"); //don't drop weapon
	}
}

// --== FORWARD CALLS ==--

/** @return true the player is allowed to drop weapons */
void Fire_ClientHolsterWeapon(int client, int defindex) {
	Call_StartForward(gfwd_ClientHolsterWeapon);
	Call_PushCell(client);
	Call_PushCell(defindex);
	Call_Finish();
}

/** @return true the player is allowed to drop weapons */
bool Fire_ClientDropWeapon(int client, int weapon, int defindex) {
	Call_StartForward(gfwd_ClientDropWeaponCheck);
	Call_PushCell(client);
	Call_PushCell(weapon);
	Call_PushCell(defindex);
	Action result;
	Call_Finish(result);
	return result < Plugin_Handled;
}

/** @return true if the weapon is allowed to spawn, false if cancelled */
bool Fire_DroppedWeaponSpawn(int client, int weapon, int defindex) {
	Call_StartForward(gfwd_DroppedWeaponSpawn);
	Call_PushCell(client);
	Call_PushCell(weapon);
	Call_PushCell(defindex);
	Action result;
	Call_Finish(result);
	return result < Plugin_Handled;
}

/** @noreturn */
void Fire_ClientDropWeaponPost(int client, int weapon, int defindex) {
	Call_StartForward(gfwd_ClientDropWeaponPost);
	Call_PushCell(client);
	Call_PushCell(weapon);
	Call_PushCell(defindex);
	Call_Finish();
}

/** @return true the player is allowed to drop weapons */
bool Fire_ClientPickupWeapon(int client, int weapon, int defindex) {
	Call_StartForward(gfwd_ClientPickupWeaponCheck);
	Call_PushCell(client);
	Call_PushCell(weapon);
	Call_PushCell(defindex);
	Action result;
	Call_Finish(result);
	return result < Plugin_Handled;
}

/** @noreturn */
void Fire_ClientPickupWeaponPost(int client, int weapon, int defindex) {
	Call_StartForward(gfwd_ClientPickupWeaponPost);
	Call_PushCell(client);
	Call_PushCell(weapon);
	Call_PushCell(defindex);
	Call_Finish();
}

/** @return true if the weapon is allowed to spawn, false if cancelled */
bool Fire_ClientClassChangePre(int client, TFClassType& class) {
	Call_StartForward(gfwd_ClientClassChangePre);
	Call_PushCell(client);
	Call_PushCellRef(class);
	Action result;
	Call_Finish(result);
	return result < Plugin_Handled;
}

/** @noreturn */
void Fire_ClientClassChange(int client, TFClassType class) {
	Call_StartForward(gfwd_ClientClassChange);
	Call_PushCell(client);
	Call_PushCell(class);
	Call_Finish();
}

/** @noreturn */
void Fire_ClientClassChangePost(int client, TFClassType class) {
	Call_StartForward(gfwd_ClientClassChangePost);
	Call_PushCell(client);
	Call_PushCell(class);
	Call_Finish();
}

// --== NATIVES ==--

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("TF2rpu_GetWeaponSlot",                  Native_TF2rpu_GetWeaponSlot);
	CreateNative("TF2rpu_ClientHolsterWeapon",            Native_TF2rpu_ClientHolsterWeapon);
	CreateNative("TF2rpu_GetClientHolsteredWeapon",       Native_TF2rpu_GetClientHolsteredWeapon);
	CreateNative("TF2rpu_GetWeapondDefinitionIndex",      Native_TF2rpu_GetWeaponDefinitionIndex);
	CreateNative("TF2rpu_GenerifyWeaponClass",            Native_TF2rpu_GenerifyWeaponClass);
	CreateNative("TF2rpu_GiveWeapon",                     Native_TF2rpu_GiveWeapon);
	CreateNative("TF2rpu_GiveWeaponEx",                   Native_TF2rpu_GiveWeaponEx);
	CreateNative("TF2rpu_GetDefaultIndexFromWeaponClass", Native_TF2rpu_GetDefaultIndexFromWeaponClass);
	CreateNative("TF2rpu_GetWeapon",                      Native_TF2rpu_GetWeapon);
	CreateNative("TF2rpu_GetMaxAmmo",                     Native_TF2rpu_GetMaxAmmo);
	CreateNative("TF2rpu_HasAmmo",                        Native_TF2rpu_HasAmmo);
	CreateNative("TF2rpu_HasAmmoEntity",                  Native_TF2rpu_HasAmmoEntity);
	CreateNative("TF2rpu_WeaponConvertCompatible",        Native_TF2rpu_WeaponConvertCompatible);
	CreateNative("TF2rpu_SetActiveWeapon",                Native_TF2rpu_SetActiveWeapon);
	CreateNative("TF2rpu_GetActiveWeapon",                Native_TF2rpu_GetActiveWeapon);
	CreateNative("TF2rpu_GetWeaponType",                  Native_TF2rpu_GetWeaponType);
	CreateNative("TF2rpu_DropWeapon",                     Native_TF2rpu_DropWeapon);
	CreateNative("TF2rpu_SpawnWeaponAt",                  Native_TF2rpu_SpawnWeaponAt);
	CreateNative("TF2rpu_CreateDroppedWeapon",            Native_TF2rpu_CreateDroppedWeapon);
	CreateNative("TF2rpu_ForcePlayerClass",               Native_TF2rpu_ForcePlayerClass);
	CreateNative("TF2rpu_SetClientModel",                 Native_TF2rpu_SetClientModel);
	CreateNative("TF2rpu_ClientPhysGunActive",            Native_TF2rpu_ClientPhysGunActive);
	CreateNative("TF2rpu_IsPhysGun",                      Native_TF2rpu_IsPhysGun);
	CreateNative("TF2rpu_ClientHideScoreboard",           Native_TF2rpu_ClientHideScoreboard);
	CreateNative("TF2rpu_SetHealthEx",                    Native_TF2rpu_SetHealthEx);
	CreateNative("TF2rpu_GetClientMaxHealth",             Native_TF2rpu_GetClientMaxHealth);
	CreateNative("TF2rpu_SetClientMaxHealth",             Native_TF2rpu_SetClientMaxHealth);
	CreateNative("TF2rpu_ResetMaxHealth",                 Native_TF2rpu_ResetMaxHealth);
	RegPluginLibrary("tf2rpu");
	return APLRes_Success;
}

//native tf2WeaponSlot TF2rpu_GetWeaponSlot(int weaponIndex, TFClassType playerclass = TFClass_Unknown);
public any Native_TF2rpu_GetWeaponSlot(Handle plugin, int argc) {
	int weaponIndex = view_as<int>(GetNativeCell(1));
	TFClassType playerclass = view_as<TFClassType>(GetNativeCell(2));
	
	return _CheckWeaponSlot(weaponIndex, playerclass);
}

//native void TF2rpu_ClientHolsterWeapon(int client, bool holster, bool dropHolster=false);
public any Native_TF2rpu_ClientHolsterWeapon(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	bool holster = view_as<bool>(GetNativeCell(2));
	bool dropHolstered = view_as<bool>(GetNativeCell(3));
	
	Impl_TF2rpu_ClientHolsterWeapon(client, holster, dropHolstered);
}

//native int TF2rpu_GetClientHolsteredWeapon(int client);
public any Native_TF2rpu_GetClientHolsteredWeapon(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	
	return Impl_TF2rpu_GetClientHolsteredWeapon(client);
}

//native int TF2rpu_GetWeapondDefinitionIndex(int weapon);
public any Native_TF2rpu_GetWeaponDefinitionIndex(Handle plugin, int argc) {
	int weapon = view_as<int>(GetNativeCell(1));
	
	return Impl_TF2rpu_GetWeapondDefinitionIndex(weapon);
}

//native void TF2rpu_GenerifyWeaponClass(char[] classname, int maxlen);
public any Native_TF2rpu_GenerifyWeaponClass(Handle plugin, int argc) {
	int maxlen = view_as<int>(GetNativeCell(2));
	if (maxlen <= 0) return;
	char[] classname = new char[maxlen];
	int read;
	GetNativeString(1, classname, maxlen, read);
	if (read <= 0) return;
	
	Impl_TF2rpu_GenerifyWeaponClass(classname, maxlen);
	SetNativeString(1, classname, maxlen);
}

//native int TF2rpu_GiveWeapon(int client, const char[] classname);
public any Native_TF2rpu_GiveWeapon(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int maxlen;
	GetNativeStringLength(2,maxlen);
	if (maxlen <= 0) return -1;
	char[] weapon = new char[maxlen+1];
	GetNativeString(2,weapon,maxlen+1);
	
	return Impl_TF2rpu_GiveWeapon(client, weapon);
}

//native int TF2rpu_GiveWeaponEx(int client, int weaponDefinitionIndex, bool switchTo=true);
public any Native_TF2rpu_GiveWeaponEx(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int weapon = view_as<int>(GetNativeCell(2));
	bool switchTo = view_as<bool>(GetNativeCell(3));
	
	return Impl_TF2rpu_GiveWeaponEx(client, weapon, switchTo);
}

//native int TF2rpu_GetDefaultIndexFromWeaponClass(const char[] classname);
public any Native_TF2rpu_GetDefaultIndexFromWeaponClass(Handle plugin, int argc) {
	int maxlen;
	GetNativeStringLength(1,maxlen);
	if (maxlen <= 0) return -1;
	char[] weapon = new char[maxlen+1];
	GetNativeString(1,weapon,maxlen+1);
	
	return Impl_TF2rpu_GetDefaultIndexFromWeaponClass(weapon);
}

//native int TF2rpu_GetWeapon(int client, int weaponIndex);
public any Native_TF2rpu_GetWeapon(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int weapon = view_as<int>(GetNativeCell(2));
	
	return Impl_TF2rpu_GetWeapon(client, weapon);
}

//native int TF2rpu_GetMaxAmmo(const char[] classname);
public any Native_TF2rpu_GetMaxAmmo(Handle plugin, int argc) {
	int maxlen;
	GetNativeStringLength(1,maxlen);
	if (maxlen <= 0) return -1;
	char[] weapon = new char[maxlen+1];
	GetNativeString(1,weapon,maxlen+1);
	
	return Impl_TF2rpu_GetMaxAmmo(weapon);
}

//native bool TF2rpu_HasAmmoEntity(int weapon);
public any Native_TF2rpu_HasAmmoEntity(Handle plugin, int argc) {
	int weapon = view_as<int>(GetNativeCell(1));
	
	return Impl_TF2rpu_HasAmmoEntity(weapon);
}

//native bool TF2rpu_HasAmmo(const char[] classname);
public any Native_TF2rpu_HasAmmo(Handle plugin, int argc) {
	int maxlen;
	GetNativeStringLength(1,maxlen);
	if (maxlen <= 0) return false;
	char[] weapon = new char[maxlen+1];
	GetNativeString(1,weapon,maxlen+1);
	
	return Impl_TF2rpu_HasAmmo(weapon);
}

//native bool TF2rpu_WeaponConvertCompatible(int& weaponIndex, TFClassType playerClass=TFClass_Unknown, char classname[]="", int sz_classname=0);
public any Native_TF2rpu_WeaponConvertCompatible(Handle plugin, int argc) {
	int weapon = view_as<int>(GetNativeCellRef(1));
	TFClassType playerClass = view_as<TFClassType>(GetNativeCell(2));
	int clzSize = view_as<int>(GetNativeCell(4));
	int bufSize = (clzSize>0)?clzSize:1;
	char[] className = new char[bufSize];
	
	bool retvalue = Impl_TF2rpu_WeaponConvertCompatible(weapon, playerClass, className, clzSize);
	SetNativeCellRef(1, weapon);
	if (clzSize > 0) SetNativeString(3, className, bufSize);
	return retvalue;
}

//native void TF2rpu_SetActiveWeapon(int client, int preferedWeaponSlot);
public any Native_TF2rpu_SetActiveWeapon(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int slot = view_as<int>(GetNativeCell(2));
	
	Impl_TF2rpu_SetActiveWeapon(client, slot);
}

//native int TF2rpu_GetActiveWeapon(int client);
public any Native_TF2rpu_GetActiveWeapon(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	
	return Impl_TF2rpu_GetActiveWeapon(client);
}

//native int TF2rpu_GetWeaponType(int client, const char[] classname, bool partialMatch=false);
public any Native_TF2rpu_GetWeaponType(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int maxlen;
	GetNativeStringLength(2,maxlen);
	if (maxlen <= 0) return -1;
	char[] weapon = new char[maxlen+1];
	GetNativeString(2,weapon,maxlen+1);
	bool partialMatch = view_as<bool>(GetNativeCell(3));
	
	return Impl_TF2rpu_GetWeaponType(client, weapon, partialMatch);
}

//native int TF2rpu_DropWeapon(int client, int weapon);
public any Native_TF2rpu_DropWeapon(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int weapon = view_as<int>(GetNativeCell(2));
	
	return Impl_TF2rpu_DropWeapon(client,weapon);
}

//native int TF2rpu_SpawnWeaponAt(int client, int weaponDefinitionIndex);
public any Native_TF2rpu_SpawnWeaponAt(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int weapon = view_as<int>(GetNativeCell(2));
	
	return Impl_TF2rpu_SpawnWeaponAt(client, weapon);
}

//native int TF2rpu_CreateDroppedWeapon(int client, int weaponDefinitionIndex, const char[] worldModel, int quality, int clip, int ammo, const float origin[3], const float angles[3], const float velocity[3]);
public any Native_TF2rpu_CreateDroppedWeapon(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int weapon = view_as<int>(GetNativeCell(2));
	int maxlen;
	GetNativeStringLength(3,maxlen);
	if (maxlen < 0) return -1;
	char[] model = new char[maxlen+1];
	GetNativeString(3,model,maxlen+1);
	int quality = view_as<int>(GetNativeCell(4));
	int clip = view_as<int>(GetNativeCell(5));
	int ammo = view_as<int>(GetNativeCell(6));
	float origin[3],angles[3],velocity[3];
	GetNativeArray(7, origin, 3);
	GetNativeArray(8, angles, 3);
	GetNativeArray(9, velocity, 3);
	
	return Impl_TF2rpu_CreateDroppedWeapon(client, weapon, model, quality, clip, ammo, origin, angles, velocity);
}

//native void TF2rpu_ForcePlayerClass(int client, int classes);
public any Native_TF2rpu_ForcePlayerClass(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int classes = view_as<int>(GetNativeCell(2));
	
	Impl_TF2rpu_ForcePlayerClass(client, classes);
}

//native void TF2rpu_SetClientModel(int client, const char[] model);
public any Native_TF2rpu_SetClientModel(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int maxlen;
	GetNativeStringLength(2,maxlen);
	if (maxlen < 0) return -1;
	char[] model = new char[maxlen+1];
	GetNativeString(2,model,maxlen+1);
	
	Impl_TF2rpu_SetClientModel(client, model);
	return 0;
}

//native bool TF2rpu_ClientPhysGunActive(int client);
public any Native_TF2rpu_ClientPhysGunActive(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	
	return Impl_TF2rpu_ClientPhysGunActive(client);
}

//native bool TF2rpu_IsPhysGun(int weapon, int& weaponIndex=-1);
public any Native_TF2rpu_IsPhysGun(Handle plugin, int argc) {
	int weapon = view_as<int>(GetNativeCell(1));
	int index;
	
	bool retvalue = Impl_TF2rpu_IsPhysGun(weapon, index);
	SetNativeCellRef(2,index);
	return retvalue;
}

//native void TF2rpu_ClientHideScoreboard(int client, int flags = USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
public any Native_TF2rpu_ClientHideScoreboard(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int flags = view_as<int>(GetNativeCell(2));
	
	Impl_TF2rpu_ClientHideScoreboard(client, flags);
}

//native void TF2rpu_SetHealthEx(int client, int health=-1, int maxhealth=-1, bool disableDecay=false);
public any Native_TF2rpu_SetHealthEx(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int health = view_as<int>(GetNativeCell(2));
	int max = view_as<int>(GetNativeCell(3));
	bool stable = view_as<bool>(GetNativeCell(4));
	
	Impl_TF2rpu_SetHealthEx(client, health, max, stable);
}

//native int TF2rpu_GetClientMaxHealth(int client);
public any Native_TF2rpu_GetClientMaxHealth(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	
	return Impl_TF2rpu_GetClientMaxHealth(client);
}

//native void TF2rpu_SetClientMaxHealth(int client, int maxhealth);
public any Native_TF2rpu_SetClientMaxHealth(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	int health = view_as<int>(GetNativeCell(2));
	
	Impl_TF2rpu_SetClientMaxHealth(client, health);
}

//native void TF2rpu_ResetMaxHealth(int client)
public any Native_TF2rpu_ResetMaxHealth(Handle plugin, int argc) {
	int client = view_as<int>(GetNativeCell(1));
	
	Impl_TF2rpu_ResetMaxHealth(client);
}