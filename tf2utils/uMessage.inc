// https://forums.alliedmods.net/showthread.php?p=1946768

#define MAX_ANNOTATION_COUNT 50*MAXPLAYERS

#define MAX_ANNOTATION_LENGTH 256

enum struct AnnotationData {
	int followEntity;
	bool idused;
	float pos[3];
	float lifetime;
	int visibility;
	char text[MAX_ANNOTATION_LENGTH];
	bool isDeployed;
	any plugindata;
	
	void VisibleFor(int client, bool visible=true) {
		//this will not work with more than 32 clients
		if (visible) this.visibility |= (1<<client);
		else this.visibility &=~ (1<<client);
	}
	void SetText(const char[] text) {
		strcopy(this.text, MAX_ANNOTATION_LENGTH, text);
	}
	void SetParent(int entity) {
		if (!IsValidEdict(entity)) this.followEntity = INVALID_ENT_REFERENCE;
		else this.followEntity = (entity >= 0) ? EntIndexToEntRef(entity) : entity;
	}
	/** @return true if the annotaion was sent to clients */
	bool Send(int selfIndex, const char[] sound, bool showEffect = false) {
		if (!(this.isDeployed = !!this.visibility)) return false;
		Event event = CreateEvent("show_annotation");
		if (event == INVALID_HANDLE) return false;
		event.SetFloat("worldPosX", this.pos[0]);
		event.SetFloat("worldPosY", this.pos[1]);
		event.SetFloat("worldPosZ", this.pos[2]);
		event.SetFloat("lifetime", this.lifetime);
		event.SetInt("id", selfIndex);
		if (!strlen(this.text)) //prevent default *AnnotationPannel_Callout
			event.SetString("text", " ");
		else
			event.SetString("text", this.text);
		event.SetString("play_sound", sound);
		if (this.followEntity != INVALID_ENT_REFERENCE) event.SetInt("follow_entindex", EntRefToEntIndex(this.followEntity));
		if (this.visibility != -1) event.SetInt("visibilityBitfield", this.visibility);
		if (showEffect) event.SetBool("show_effect", showEffect);
		event.Fire();
		return true;
	}
	/** @return true if the annotation is hidden after call */
	bool Hide(int selfIndex) {
		if (!this.isDeployed) return true;
		Event event = CreateEvent("hide_annotation");
		if (event == INVALID_HANDLE) return false;
		event.SetInt("id", selfIndex);
		event.Fire();
		this.isDeployed = false;
		return true;
	}
}
AnnotationData annotations[MAX_ANNOTATION_COUNT];
any Impl_CursorAnnotation_new(int index = -1, bool reset=false) {
	if (index < 0) {
		//find free index
		for (int i;i<MAX_ANNOTATION_COUNT;i++) {
			if (!annotations[i].idused) {
				index = i;
				break;
			}
		}
	}
	if (index < 0 || index >= MAX_ANNOTATION_COUNT) {
		return -1;
	}
	if (!annotations[index].idused || reset) {
		float zero[3];
		annotations[index].visibility = -1;
		annotations[index].followEntity = INVALID_ENT_REFERENCE;
		annotations[index].lifetime = 1000.0;
		annotations[index].SetText("< ERROR >");
		annotations[index].pos = zero;
		annotations[index].idused = true;
		annotations[index].plugindata = 0;
		if (annotations[index].isDeployed) {
			annotations[index].Hide(index);
		}
	}
	return index;
}

// move that back to rp actually
///**
// * displayType: 0 origin, 1 center, 2 above
// * showeffect: green becon at annotation location, will force update
// */
//bool Impl_TF2rpu_CursorAnnotationUpdate(int client, const char[] text, int entity, bool follow=false, int displayType=0, bool showEffect=false) {
//	// find annotation and validate entity
//	Annotation annotation = Annotation(ANNOTATION_CURSOR_OFFSET + client);
//	if (!annotation.IsValid) return false; // could not get annotations
//	
//	if (!IsValidEdict(entity)) { // entity went away?
//		annotation.Close();
//		return false;
//	} else if (annotation.Data != entity) {
//		float origin[3];
//		Entity_GetAbsOrigin(entity, origin);
//		if (displayType >= 1) {
//			float vec1[3], vec2[3];
//			Entity_GetMinSize(entity, vec1);
//			Entity_GetMaxSize(entity, vec2);
//			AddVectors(origin, vec1, origin); //make origin abs min
//			SubtractVectors(vec2, vec1, vec2); //vec2 is not dims
//			vec1=vec2;
//			ScaleVector(vec1, 0.5); //vec1 is now center offset
//			if (displayType == 2) {
//				vec1[2] = vec2[2]; //pull back to top
//			}
//			AddVectors(origin, vec1, origin); //absolute position into origin
//		}
//		annotation.SetPosition(origin);
//		annotation.SetVisibleAll(false);
//		annotation.SetVisibleFor(client, true);
//		annotation.Data = entity;
//		if (follow) annotation.ParentEntity = entity;
//	} 
//	if (annotation.SetText(text) || showEffect) {
//		annotation.Update(_, showEffect);
//	}
//	return true;
//}
//void Impl_TF2rpu_CursorAnnotationClose(int client) {
//	Annotation annotation = Annotation(ANNOTATION_CURSOR_OFFSET + client);
//	if (!annotation.IsValid) return; // could not get annotations
//	
//	annotation.Close();
//}

/**
 * Displays a HudNotification (centered, bottom half) for the client
 * This element will NOT show with minimal hud!
 * https://forums.alliedmods.net/showthread.php?t=155911
 * @param icon taken from mod_textures.txt
 * @param background (Use a TFTeam or -1 for client team color)
 * @param message (+ format)
 */
void Impl_TF2rpu_HudNotificationCustom(int client, const char[] icon="voice_self", int background=-1, bool stripMoreColors=false, const char[] message) {
	if (!IsClientInGame(client) || IsFakeClient(client)) return;
	
	char msg[MAX_MESSAGE_LENGTH];
	strcopy(msg, sizeof(msg), message)
	if (stripMoreColors) CReplaceColorCodes(msg, client, true, sizeof(msg));
	ReplaceString(msg,sizeof(msg),"\"","'");
	if (background < 0) background = view_as<int>(TF2_GetClientTeam(client));
	
	Handle hdl = StartMessageOne("HudNotifyCustom", client);
	BfWriteString(hdl, msg);
	BfWriteString(hdl, icon);
	BfWriteByte(hdl, background);
	EndMessage();
}