#include <sourcemod>
#include <sdktools>

new Handle:WelcomeTimers[MAXPLAYERS+1];
enum PCommType {
    PCommType_PMute = 0,
    PCommType_PUnMute,
    PCommType_PGag,
    PCommType_PUnGag,
    PCommType_PSilence,
    PCommType_PUnSilence,
    PCommType_NumTypes
};

stock bool:PluginExists(const String:plugin_name[]) {
    new Handle:iter = GetPluginIterator();
    new Handle:plugin = INVALID_HANDLE;
    decl String:name[64];

    while (MorePlugins(iter)) {
	plugin = ReadPlugin(iter);
	GetPluginFilename(plugin, name, sizeof(name));
	if (StrEqual(name, plugin_name)) {
	    CloseHandle(iter);
	    return true;
	}
    }

    CloseHandle(iter);
    return false;
}
 
public Plugin:myinfo =
{
	name = "PTS Plugin",
	author = "PhilmacFLy",
	description = "Plugin that allows automatic Management of PTS Requests",
	version = "1.0.0.0",
	url = "http://www.binary-kitchen.de"
}
	new bool:pts_active = true;
	
public OnPluginStart()
{
	RegAdminCmd("sm_myslap", Command_MySlap, ADMFLAG_SLAY);
	LoadTranslations("common.phrases");
	if (!PluginExists("basecomm.smx")) {
        LogError("FATAL: This plugin requires basecomm. Please load basecomm and try loading this plugin again.");
        SetFailState("This plugin requires basecomm. Please load basecomm and try loading this plugin again.");
    }
	
	PrintToServer("PTS Plugin sucessfully loaded");
}

stock PerformPMute(client, target, PCommType:type) {
    decl String:cmd[32];
    new target_userid = GetClientUserId(target);
    decl String:target_name[MAX_NAME_LENGTH];
    GetClientName(target, target_name, sizeof(target_name));

    switch (type) {
	case PCommType_PMute: {
	    Format(cmd, sizeof(cmd), "sm_mute #%d", target_userid);
	    ServerCommand(cmd);
	    if (client) {
		ShowActivity2(client, "[PERMAMUTE] ", "Permanently Muted %N", target);
	    }
	}
	case PCommType_PUnMute: {
	    Format(cmd, sizeof(cmd), "sm_unmute #%d", target_userid);
	    ServerCommand(cmd);
	    if (client) {
		ShowActivity2(client, "[PERMAMUTE] ", "Permanently UnMuted %N", target);
	    }
	}
	case PCommType_PGag: {
	    Format(cmd, sizeof(cmd), "sm_gag #%d", target_userid);
	    ServerCommand(cmd);
	    if (client) {
		ShowActivity2(client, "[PERMAMUTE] ", "Permanently Gagged %N", target);
	    }
	}
	case PCommType_PUnGag: {
	    Format(cmd, sizeof(cmd), "sm_ungag #%d", target_userid);
	    ServerCommand(cmd);
	    if (client) {
		ShowActivity2(client, "[PERMAMUTE] ", "Permanently UnGagged %N", target);
	    }
	}
	case PCommType_PSilence: {
	    PerformPMute(client, target, PCommType_PMute);
	    PerformPMute(client, target, PCommType_PGag);
	}
	case PCommType_PUnSilence: {
	    PerformPMute(client, target, PCommType_PUnMute);
	    PerformPMute(client, target, PCommType_PUnGag);
	}
    }

}

stock TargetedAction(client, PCommType:type, const String:target_string[]) {
    decl String:target_name[MAX_TARGET_LENGTH];
    decl target_list[MAXPLAYERS];
    decl target_count;
    decl bool:tn_is_ml;

    if ((target_count = ProcessTargetString(
	target_string,
	client,
	target_list,
	MAXPLAYERS,
	0,
	target_name,
	sizeof(target_name),
	tn_is_ml)) <= 0) {
	ReplyToTargetError(client, target_count);
	return;
    }

    for (new i = 0; i < target_count; i++) {
	PerformPMute(client, target_list[i], type);
    }
}

public OnClientPutInServer(client)
{
	if ((pts_active) && (GetUserFlagBits(client) & ADMFLAG))
	{
	WelcomeTimers[client] = CreateTimer(10.0, MuteNewPlayer, client);
	}
	return Plugin_Handled;
} 

public Action:MuteNewPlayer(Handle:timer, any:client)
{
	PerformPMute(0, client, PCommType_PMute);
	WelcomeTimers[client] = INVALID_HANDLE;
}

public Action::MuteAllPlayers()
{
    static iClient = -1, iMaxClients = 0;
    iMaxClients = GetMaxClients ();
    for (iClient = 1; iClient <= iMaxClients; iClient++)
    {
	if (IsClientConnected (iClient) && IsClientInGame (iClient))
	{
	  PerformPMute(0, iClient, PCommType_PMute);  
	}
    }
}

public OnClientDisconnect(client)
{
	if (WelcomeTimers[client] != INVALID_HANDLE)
	{
		KillTimer(WelcomeTimers[client]);
		WelcomeTimers[client] = INVALID_HANDLE;
	}
}
