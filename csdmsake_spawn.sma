/**
 * csdm_spawn_preset.sma
 * Allows for Counter-Strike to be played as DeathMatch.

 * CSDM Spawn Method - Preset Spawning
 * by Freecode and BAILOPAN
 * (C)2003-2005 David "BAILOPAN" Anderson
 *
 *  Give credit where due.
 *  Share the source - it sets you free
 *  http://www.opensource.org/
 *  http://www.gnu.org/
 * 
 * Edited by sake
 * Just removed original CSDM dependencies and added
 * extra functionality for proper spawnsounds.
 */
 
#define	MAX_SPAWNS	60
#define GUNPICKUP_SOUND "items/gunpickup2.wav"
#define SND_FLAG (1<<32)

//Tampering with the author and name lines will violate copyrights
#define PLUGINNAME "CSDM Mod | csdmsake_spawn"
#define VERSION "2.00 | 1.1e"
#define AUTHORS "CSDM Team | sake"

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <fakemeta>

new Float:g_SpawnVecs[MAX_SPAWNS][3];
new Float:g_SpawnAngles[MAX_SPAWNS][3];
new Float:g_SpawnVAngles[MAX_SPAWNS][3];
new g_TotalSpawns;

public plugin_init()
{
	register_plugin(PLUGINNAME,VERSION,AUTHORS);
	registerHamHooks();
	registerForwards();
	readSpawns();
}

registerHamHooks()
{
	RegisterHam(Ham_Spawn, "player", "playerSpawned", 1);
}

registerForwards()
{
	register_forward(FM_EmitSound, "fm_emitSound");
}

public playerSpawned(id)
{
	//don't do anything if it is one of the roundendblockers who has been spawned or the user is not alive (spectator?)
	if(pev(id, pev_flags) == FL_CUSTOMENTITY || !is_user_alive(id))
	{
		return;
	}
	spawn_Preset(id,1);
	//Play spawnsound.
	engfunc(EngFunc_EmitSound, id, CHAN_ITEM, GUNPICKUP_SOUND, VOL_NORM, ATTN_NORM, SND_FLAG, PITCH_NORM);
}

public fm_emitSound(ent, iChannel, const szSample[], Float:fVolume, Float:fAttenuation, iFlags, iPitch)
{
	if(equal(szSample,GUNPICKUP_SOUND) && !(iFlags & SND_FLAG))
	{
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

readSpawns()
{
	//-617 2648 179 16 -22 0 0 -5 -22 0
	// Origin (x,y,z), Angles (x,y,z), vAngles(x,y,z), Team (0 = ALL) - ignore
	// :TODO: Implement team specific spawns
	
	new Map[32], config[32],  MapFile[64];
	
	get_mapname(Map, 31)
	get_configsdir(config, 31 )
	format(MapFile, 63, "%s\csdm\%s.spawns.cfg", config, Map);
	g_TotalSpawns = 0;
	
	if (file_exists(MapFile)) 
	{
		new Data[124], len;
    		new line = 0;
    		new pos[12][8];
    		
		while(g_TotalSpawns < MAX_SPAWNS && (line = read_file(MapFile , line , Data , 123 , len) ) != 0 ) 
		{
			if (strlen(Data)<2 || Data[0] == '[')
				continue;

			parse(Data, pos[1], 7, pos[2], 7, pos[3], 7, pos[4], 7, pos[5], 7, pos[6], 7, pos[7], 7, pos[8], 7, pos[9], 7, pos[10], 7);
			
			g_TotalSpawns++;
			
			// Origin
			g_SpawnVecs[g_TotalSpawns][0] = str_to_float(pos[1]);
			g_SpawnVecs[g_TotalSpawns][1] = str_to_float(pos[2]);
			g_SpawnVecs[g_TotalSpawns][2] = str_to_float(pos[3]);
			
			//Angles
			g_SpawnAngles[g_TotalSpawns][0] = str_to_float(pos[4]);
			g_SpawnAngles[g_TotalSpawns][1] = str_to_float(pos[5]);
			g_SpawnAngles[g_TotalSpawns][2] = str_to_float(pos[6]);
			
			//v-Angles
			g_SpawnVAngles[g_TotalSpawns][0] = str_to_float(pos[7]);
			g_SpawnVAngles[g_TotalSpawns][1] = str_to_float(pos[8]);
			g_SpawnVAngles[g_TotalSpawns][2] = str_to_float(pos[9]);
			
			//Team - ignore
		}
		
		log_amx("Loaded %d spawn points for map %s.", g_TotalSpawns, Map)
	} else {
		log_amx("No spawn points file found (%s)", MapFile)
	}
	
	return 1;
}

public spawn_Preset(id, num)
{
	if (g_TotalSpawns < 2)
		return PLUGIN_CONTINUE
	
	new list[MAX_SPAWNS];
	new num = 0; 
	new final = -1; 
	new total=0; 
	new players[32], n, x = 0;
	new Float:loc[32][3], locnum
	
	//cache locations
	get_players(players, num)
	for (new i=0; i<num; i++)
	{
		if (is_user_alive(players[i]) && players[i] != id)
		{
			entity_get_vector(players[i], EV_VEC_origin, loc[locnum])
			locnum++
		}
	}
	
	num = 0
	while (num <= g_TotalSpawns)
	{
		//have we visited all the spawns yet?
		if (num == g_TotalSpawns)
			break;
		//get a random spawn
		n = random_num(0, g_TotalSpawns-1);
		//have we visited this spawn yet?
		if (!list[n])
		{
			//yes, set the flag to true, and inc the number of spawns we've visited
			list[n] = 1;
			num++;
		} 
		else 
		{
	        //this was a useless loop, so add to the infinite loop prevention counter
			total++;
			if (total > 100) // don't search forever
				break;
			continue;   //don't check again
		}

		new trace  = trace_hull(g_SpawnVecs[n],1);
		if (trace)
			continue;
		
		if (locnum < 1)
		{
			final = n
			break
		}
		
		final = n
		for (x = 0; x < locnum; x++)
		{
			new Float:distance = get_distance_f(g_SpawnVecs[n], loc[x]);
			if (distance < 250.0)
			{
				//invalidate
				final = -1;
				break;
			}
		}
		
		if (final != -1)
			break
	}
	
	if (final != -1)
	{
		entity_set_origin(id, g_SpawnVecs[final]);
		entity_set_int(id, EV_INT_fixangle, 1);
		entity_set_vector(id, EV_VEC_angles, g_SpawnAngles[final]);
		entity_set_vector(id, EV_VEC_v_angle, g_SpawnVAngles[final]);
		entity_set_int(id, EV_INT_fixangle, 1);
		
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}
