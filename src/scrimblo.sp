#include <sourcemod>
#include <clients>
#include <tf2_stocks>
#include <entity>
#include <logging>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.1.0"

public Plugin myinfo = {
    name        = "Scrimblo",
    author      = "VIORA",
    description = "A better implementation of the scrambling algorithm",
    version     = PLUGIN_VERSION,
    url         = "https://github.com/crescentrose/tf2-scrimblo"
};

enum struct Player {
    int ClientId;
    int Score;
    int Samples;
    float AverageScore; // `Score` over `Samples` (score per minute)

    void ChangeTeam(TFTeam team) {
        TF2_ChangeClientTeam(this.ClientId, team);
    }

    void Update() {
        int playerResourceEntity = GetPlayerResourceEntity();
        this.Score = GetEntProp(playerResourceEntity, Prop_Send, "m_iTotalScore", _, this.ClientId);
        
        // only start the averages once the player actually does something
        if (this.Score > 0) {
            this.AverageScore = float(this.Score) / float(this.Samples);
            this.Samples++;
        } else {
            this.AverageScore = 0.0;
            this.Samples = 0;
        }
    }
}

methodmap PlayerList < ArrayList {
    public PlayerList() {
        return view_as<PlayerList>(new ArrayList(sizeof(Player)));
    }

    public void Reset() {
        this.Clear();

        for (int i = 0; i < MaxClients; i++) {
            if (!IsClientValid(i))
                continue;

            Player player;
            player.ClientId = i;
            player.Update();
            this.PushArray(player);
        }
    } 

    public void UpdateAll() {
        for (int i = 0; i < this.Length; i++) {
            Player player;
            this.GetArray(i, player);

            if (IsClientValid(player.ClientId))
                player.Update();
            
            this.SetArray(i, player);
        }
    }
    
    public void Remove(int clientId) {
        for (int i = 0; i < this.Length; i++) {
            Player player;
            this.GetArray(i, player);

            if (player.ClientId == clientId) {
                this.Erase(i);
                i--; // since Erase shifts the index down 
            }
        }
    }

    public void Add(int clientId) {
        this.Remove(clientId); // ensure no duplicates before adding a new client

        if (!IsClientValid(clientId))
            return;

        Player player;
        player.ClientId = clientId;
        player.Update();
        this.PushArray(player);
    }

    public void SortByScore() {
        this.SortCustom(SortPlayerScoresInner);
    }
}

ConVar g_cvarRestartGame;
PlayerList g_playerList;
Handle g_scoreUpdateTimer;

public void OnPluginStart() {
    CreateConVar("scrimblo_version", PLUGIN_VERSION, "Scrimblo version", FCVAR_DONTRECORD);
    RegAdminCmd("sm_scrimblo", Command_Scramble, ADMFLAG_VOTE, "Scramble the teams");
    g_cvarRestartGame = FindConVar("mp_restartgame_immediate");
    g_playerList = new PlayerList();
}

public void OnMapStart() {
    g_playerList.Reset();
    g_scoreUpdateTimer = CreateTimer(60.0, Timer_UpdateScores, _, TIMER_REPEAT);
}

public void OnClientPostAdminCheck(int clientId) {
    g_playerList.Add(clientId);
}

public void OnClientDisconnect(int clientId) {
    g_playerList.Remove(clientId);
}

public void OnMapEnd() {
    if (g_scoreUpdateTimer != null) {
        TriggerTimer(g_scoreUpdateTimer, true);
        KillTimer(g_scoreUpdateTimer);
    }
}

public Action Timer_UpdateScores(Handle timer) {
    g_playerList.UpdateAll();
    g_playerList.SortByScore();

    for (int i = 0; i < g_playerList.Length; i++) {
        char name[255];
        Player player;
        g_playerList.GetArray(i, player);
        GetClientName(player.ClientId, name, sizeof(name));
        PrintToChatAll("Player %s (%i) had score %i with an average of %.2f over %i samples.", name, player.ClientId, player.Score, player.AverageScore, player.Samples);
    }

    return Plugin_Continue;
}

public Action Command_Scramble(int client, int args) {
    LogAction(client, -1, "scrambled teams");
    PlayerList players = new PlayerList();
    players.Reset();

    DoScramble(players);

    delete players;

    g_cvarRestartGame.IntValue = 1;

    return Plugin_Handled;
}

int SortPlayerScoresInner(int i1, int i2, Handle array, Handle handle = null) {
    Player e1, e2;
    view_as<ArrayList>(array).GetArray(i1, e1);
    view_as<ArrayList>(array).GetArray(i2, e2);

    if (e1.AverageScore > e2.AverageScore) {
        return -1; // first goes before second
    } else if (e1.AverageScore < e2.AverageScore) {
        return 1; // first goes after second
    } else {
        return 0;
    }
}

bool IsClientValid(int clientId) {
    if (clientId == 0 || !IsClientConnected(clientId) || !IsClientInGame(clientId) || IsClientObserver(clientId) || IsClientReplay(clientId) || IsClientSourceTV(clientId))
        return false;

    return true;
}

void DoScramble(PlayerList players) {
    players.SortByScore();

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
}
