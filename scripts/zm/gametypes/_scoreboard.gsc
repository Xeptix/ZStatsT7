// Stock _scoreboard.gsc with ZStats startup registrations added.
// _load.gsc imports this owner before gameplay systems register, which keeps
// T7x host/client script initialization in the same phase as the stock game.

#using scripts\codescripts\struct;
#using scripts\shared\callbacks_shared;
#using scripts\shared\system_shared;
#using scripts\zstats\main;

#namespace scoreboard;

function autoexec __init__sytem__()
{
    system::register( "scoreboard", &__init__, undefined, undefined );
}

function __init__()
{
    // Stock registration.
    callback::on_start_gametype( &main );

    // ZStats is idempotent. The player callbacks also cover clients which
    // attach the mod zone after the start-gametype callback has fired.
    callback::on_start_gametype( &zstats::init );
    callback::on_connect( &zstats::init );
    callback::on_spawned( &zstats::on_spawned );
}

// Stock _scoreboard.gsc body, preserved verbatim in behavior.
function main()
{
    setdvar( "g_ScoresColor_Spectator", ".25 .25 .25" );
    setdvar( "g_ScoresColor_Free", ".76 .78 .10" );
    setdvar( "g_teamColor_MyTeam", ".4 .7 .4" );
    setdvar( "g_teamColor_EnemyTeam", "1 .315 0.35" );
    setdvar( "g_teamColor_MyTeamAlt", ".35 1 1" );
    setdvar( "g_teamColor_EnemyTeamAlt", "1 .5 0" );
    setdvar( "g_teamColor_Squad", ".315 0.35 1" );

    if ( sessionmodeiszombiesgame() )
    {
        setdvar( "g_TeamIcon_Axis", "faction_cia" );
        setdvar( "g_TeamIcon_Allies", "faction_cdc" );
    }
    else
    {
        setdvar( "g_TeamIcon_Axis", game["icons"]["axis"] );
        setdvar( "g_TeamIcon_Allies", game["icons"]["allies"] );
    }
}
