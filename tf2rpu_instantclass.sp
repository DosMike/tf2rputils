bool clientClassChange[MAXPLAYERS + 1]; //suppress dropping items through class change
float clientClassChangeTime[MAXPLAYERS + 1]; //prevent super fast switching breaking timers
//force respawning in the same location when changing class
float clientForcedRespawnLocation[MAXPLAYERS + 1][2][3];
int clientForcedRespawnHealth[MAXPLAYERS + 1];

#define CHANGECLASS_COOLDOWN 1.0

public Action commandChangeClass(int client, const char[] command, int argc) {
	if (!Client_IsValid(client) || !Client_IsIngame(client)) return Plugin_Continue;
	if (!canClientContinue(client, cvar_InstantClass)) return Plugin_Continue;
	
	if (argc > 0) {
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		TFClassType classtype = TF2_GetClass(arg1);
		
		if (!Fire_ClientClassChangeCheck(client, classtype)) return Plugin_Handled;
		
		if (TF2_GetPlayerClass(client)!=TFClass_Unknown && IsPlayerAlive(client)) { //is alive and already assigned a class (not admin)
			if (classtype == TFClass_Unknown) classtype = view_as<TFClassType>(GetRandomInt(1,9));
			if (TF2_GetPlayerClass(client)==classtype) return Plugin_Handled; //already there
			float vel[3];
			Entity_GetAbsVelocity(client,vel);
			if (GetVectorLength(vel, true)>1) {
				Impl_TF2rpu_HudNotificationCustom(client, _, _, true, formatted(client, "%t", "action invalid while moving"));
				return Plugin_Handled;
			}
			if (GetGameTime() - clientClassChangeTime[client] < CHANGECLASS_COOLDOWN) { // change class cooldown
				Impl_TF2rpu_HudNotificationCustom(client, "ico_notify_ten_seconds", _, _, formatted(client, "%t", "class switch cooldown"));
				return Plugin_Handled;
			}
			if ((Entity_GetFlags(client)&FL_DUCKING) || (GetClientButtons(client)&IN_DUCK)) {
				Impl_TF2rpu_HudNotificationCustom(client, _, _, _, formatted(client, "%t", "action invalid while crouched"));
				return Plugin_Handled;
			}
			clientClassChangeTime[client] = GetGameTime();
			Impl_TF2rpu_ForcePlayerClass(client, 1 << view_as<int>(classtype));
			clientClassChange[client] = true;
			Entity_GetAbsOrigin(client, clientForcedRespawnLocation[client][0]);
			GetClientEyeAngles(client, clientForcedRespawnLocation[client][1]);
			
			if (canClientContinue(client, cvar_InstantClassForceHealth, true))
				clientForcedRespawnHealth[client] = GetClientHealth(client);
			RequestFrame(_ForceRespawnClient, client);
			TF2_SetPlayerClass(client, classtype);
			
			return Plugin_Handled;
		}// else get ingame / default change behaviour while dead
	}// else show menu
	return Plugin_Continue;
}

static void _ForceRespawnClient(any data) {
	int client = view_as<int>(data);
	if (!Client_IsValid(client) || !IsClientInGame(client)) return;
	TF2_RespawnPlayer(client);
	
	Fire_ClientClassChangePost(client, TF2_GetPlayerClass(client));
}

void Impl_TF2rpu_ForcePlayerClass(int client, int classes) {
	if (!Client_IsValid(client) || !Client_IsIngame(client)) return ;
	int class = view_as<int>(TF2_GetPlayerClass(client));
	if (classes == 0 || (classes & (1<<class))!=0 ) return;
	class = 1;
	while (!(classes & (1<<class)) && class < 9) { class++; }
	TF2_SetPlayerClass(client, view_as<TFClassType>(class));
//	if (IsPlayerAlive(client)) {
//		if (!clientClassChange[client]) {
//			clientClassChange[client] = true; //don't double
//			Entity_GetAbsOrigin(client, clientForcedRespawnLocation[client][0]);
//			GetClientEyeAngles(client, clientForcedRespawnLocation[client][1]);
//			clientForcedRespawnHealth[client] = GetClientHealth(client);
//			RequestFrame(_ForceRespawnClient, client);
//		}
//		TF2_RespawnPlayer(client);
//	}
}