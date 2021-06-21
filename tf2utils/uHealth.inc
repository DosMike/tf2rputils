
// this is to disable overheal decay - attrib didn't do the job
int clientOverhealth[MAXPLAYERS+1];
bool isClientOverheal[MAXPLAYERS+1];

/** Use -1 for health if you don't want to change the hp
 * Has to be called once (spawn-)loadout is finalized, otherwise weapon attribts might be wrong
 */
void Impl_TF2rpu_SetHealthEx(int client, int health=-1, int maxhealth=-1, bool disableDecay=false) {
	if (health <= 0) {
		health = Entity_GetHealth(client);
	}
	if (maxhealth > 0) {
		Impl_TF2rpu_SetClientMaxHealth(client, maxhealth);
	}
	Entity_SetHealth(client, health, true);
	if (disableDecay) {
		isClientOverheal[client] = true;
		clientOverhealth[client] = health;
	} else {
		isClientOverheal[client] = false;
	}
}

int Impl_TF2rpu_GetClientMaxHealth(int client) {
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}

void _TF2rpu_thinkOverheal() {
	for (int client=0;client<MaxClients;client++) {
		if (Client_IsValid(client) && IsClientInGame(client) && isClientOverheal[client]) {
			if (!IsPlayerAlive(client) || clientOverhealth[client] < 0) {
				isClientOverheal[client] = false;
			} else if (Entity_GetHealth(client) < clientOverhealth[client]) {
				Entity_SetHealth(client, clientOverhealth[client], true);
			}
		}
	}
}
void _TF2rpu_damageOverheal(int client, int damage) {
	if (!isClientOverheal[client]) return;
	if (!Client_IsValid(client) || !IsPlayerAlive(client)) {
		isClientOverheal[client] = false;
		return;
	}
	clientOverhealth[client] -= damage;
	if (clientOverhealth[client] < 0 || clientOverhealth[client] < Impl_TF2rpu_GetClientMaxHealth(client)) {
		isClientOverheal[client] = false;
	}
}

/**
 * Change client max health, tries to keep the current hp in case max hp increases and prevents overcharge by capping hp to the new max.
 * If you want to increate hp and max hp use Impl_TF2rpu_SetHealthEx(client, hp, hp)
 * Has to be called once (spawn-)loadout is finalized, otherwise weapon attribts might be wrong
 * @param forceUpdate DO NOT SET - this is an internal flag for the timer callback
 */
void Impl_TF2rpu_SetClientMaxHealth(int client, int maxhealth) {
	Impl_TF2rpu_ResetMaxHealth(client);
	if (TF2_GetPlayerClass(client) == TFClass_Unknown || !IsPlayerAlive(client)) {
		return;
	}
	
	int defaultMaxHp[10] = { 100, 125, 125, 200, 175, 150, 300, 175, 125, 125 };
	int diff = maxhealth-defaultMaxHp[TF2_GetPlayerClass(client)];
//	PrintToChat(client, "%i -> %i :: %i", defaultMaxHp[TF2_GetPlayerClass(client)], maxhealth, diff);
	if (diff != 0) TF2Attrib_SetByDefIndex(client, diff > 0 ? 26 : 125, float(diff));
	
//	PrintToChat(client, "ensure hp %i <= %i", Entity_GetHealth(client), maxhealth);
	if (Entity_GetHealth(client) > maxhealth) Entity_SetHealth(client, maxhealth, true, false);
}
void Impl_TF2rpu_ResetMaxHealth(int client) {
	if (!Client_IsValid(client)) return;
	TF2Attrib_RemoveByDefIndex(client, 517); //set bonus max health bonus
	TF2Attrib_RemoveByDefIndex(client, 140); //hidden max health bonus - non-buffed
	TF2Attrib_RemoveByDefIndex(client, 125); //max health additive penality
	TF2Attrib_RemoveByDefIndex(client, 26); //max health additive bonus
//	TF2Attrib_SetByDefIndex(client, 14, float(-1)); //overheal decay disable
}