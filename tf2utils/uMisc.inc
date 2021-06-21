#pragma unused Impl_TF2rpu_ClientPhysGunActive

void Impl_TF2rpu_SetClientModel(int client, const char[] model)
{
	if (strlen(model)) {
		SetVariantString(model);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", false); //true if static model
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", true); //true if actual class model
		SetEntProp(client, Prop_Send, "m_nBody", 0x00); //hide no body groups
	} else {
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 0);
		SetVariantString("ParticleEffectStop");
		AcceptEntityInput(client, "DispatchEffect");
	}
}

//phys cannon detection copied from tf2 physics gun as they don't provide an include
static const int g_iPhysicsGunWeaponIndex = 423;//Choose Saxxy(423) because the player movement won't become a villager
static const int g_iPhysicsGunQuality = 1;
static const int g_iPhysicsGunLevel = 99-128;	//Level displays as 99 but negative level ensures this is unique
bool Impl_TF2rpu_ClientPhysGunActive(int client) {
	int iWeapon = GetPlayerWeaponSlot(client, 1);
	int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	return (IsValidEntity(iWeapon) && iWeapon == iActiveWeapon && Impl_TF2rpu_IsPhysGun(iActiveWeapon));
}
bool Impl_TF2rpu_IsPhysGun(int weapon, int& weaponIndex=-1) {
	if (GetEntSendPropOffs(weapon, "m_iItemDefinitionIndex", true) <= 0) return false;
	return (weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) == g_iPhysicsGunWeaponIndex
		&& GetEntProp(weapon, Prop_Send, "m_iEntityQuality") == g_iPhysicsGunQuality
		&& GetEntProp(weapon, Prop_Send, "m_iEntityLevel") == g_iPhysicsGunLevel;
}

public void TF2_OnConditionAdded(int client, TFCond condition) {
	if (condition == TFCond_SpawnOutline || TF2_GetPlayerClass(client) == TFClass_DemoMan && condition == TFCond_Charging) {
		TF2_RemoveCondition(client, condition);
	}
}

void Impl_TF2rpu_ClientHideScoreboard(int client, int flags = USERMSG_RELIABLE|USERMSG_BLOCKHOOKS) {
	Handle handle = StartMessageOne("VGUIMenu", client, flags);

	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf) {
		PbSetString(handle, "name", "scores");
		PbSetBool(handle, "show", false);
	} else {
		BfWriteString(handle, "scores");
		BfWriteByte(handle, 0); // Show
		BfWriteByte(handle, 0); // subkeys count
	}

	EndMessage();
}

//enum ScorePropertyType {
//	ScoreProp_Frags,
//	ScoreProp_KillStreak,
//	ScoreProp_Dominated,
//	ScoreProp_DominatingMe,
//	ScoreProp_Dominations,
//	ScoreProp_Score
//};
//static const char _ScorePropertyNames[ScorePropertyType][] = {
//	"m_iFrags",
//	"m_nStreaks",
//	"m_bPlayerDominated",
//	"m_bPlayerDominatingMe",
//	"m_iActiveDominations",
//	"m_iTotalScore"
//};
//void updateClientScoreProp(int client, ScorePropertyType prop, int value) {
//	switch (prop) {
//		case ScoreProp_Frags:
//			SetEntProp(client, Prop_Data, _ScorePropertyNames[prop], value);
//		case ScoreProp_KillStreak:
//			SetEntProp(client, Prop_Send, _ScorePropertyNames[prop], value);
//		case ScoreProp_Dominations,ScoreProp_Score: {
//			SetEntProp(GetPlayerResourceEntity(), Prop_Send, _ScorePropertyNames[prop], value, _, client);
////			SetEntProp(client, Prop_Send, "m_RoundScoreData", value, _, 5);
////			SetEntProp(client, Prop_Send, "m_ScoreData", value, _, 5);
////		}
////		case ScoreProp_Score: {
////			SetEntProp(GetPlayerResourceEntity(), Prop_Send, _ScorePropertyNames[prop], value, _, client);
//		}
//		default:
//			ThrowError("Sorry, didn't sus out %s(%i) yet", _ScorePropertyNames[prop],prop);
//	}
//}
