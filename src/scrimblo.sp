#include <sourcemod>
#include <clients>
#include <tf2_stocks>
#include <entity>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
    name        = "Scrimblo",
    author      = "VIORA",
    description = "A better implementation of the scrambling algorithm",
    version     = "0.1.0",
    url         = "https://github.com/crescentrose/tf2-scrimblo"
};

enum struct Player {
    int clientId;
    int score;

    void ChangeTeam(TFTeam team) {
        TF2_ChangeClientTeam(this.clientId, team);
    }
}

ConVar g_cvarRestartGame;

public void OnPluginStart() {
    RegAdminCmd("sm_scrimblo", Command_Scramble, ADMFLAG_VOTE, "Scramble the teams");
    g_cvarRestartGame = FindConVar("mp_restartgame");
}

public Action Command_Scramble(int client, int args) {
    ArrayList players = new ArrayList(sizeof(Player));
    GetPlayerScores(players);
    SortPlayerScores(players);

    for (int i = 0; i < players.Length; i += 2) {
        // in case of an odd number of players on teams, leave the last player where they are
        if ((players.Length - 1) == i)
            break;

        // split players between teams
        Player red, blue;
        players.GetArray(i, red);
        players.GetArray(i + 1, blue);

        red.ChangeTeam(TFTeam_Red);
        blue.ChangeTeam(TFTeam_Blue);
    }

    g_cvarRestartGame.IntValue = 1;

    return Plugin_Handled;
}

void GetPlayerScores(ArrayList players) {
    players.Clear();

    int playerResourceEntity = GetPlayerResourceEntity();

    for (int i = 0; i < MaxClients; i++) {
        if (i == 0 || !IsClientConnected(i))
            continue;

        if (!IsClientInGame(i))
            continue;

        if (IsClientObserver(i) || IsClientReplay(i) || IsClientSourceTV(i))
            continue;

        int score = GetEntProp(playerResourceEntity, Prop_Send, "m_iTotalScore", _, i);
        Player player;
        player.clientId = i;
        player.score = score;

        players.PushArray(player);
    }
} 

void SortPlayerScores(ArrayList players) {
    players.SortCustom(SortPlayerScoresInner);
}

int SortPlayerScoresInner(int i1, int i2, Handle array, Handle handle = null) {
    Player e1, e2;
    view_as<ArrayList>(array).GetArray(i1, e1);
    view_as<ArrayList>(array).GetArray(i2, e2);

    if (e1.score > e2.score) {
        return -1; // first goes before second
    } else if (e1.score < e2.score) {
        return 1; // first goes after second
    } else {
        return 0;
    }
}
