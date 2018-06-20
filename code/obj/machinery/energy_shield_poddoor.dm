/obj/machinery/shieldgenerator/energy_shield_poddoor
	name = "Podbay Energy-Shield Generator"
	desc = "Solid matter can pass through the shields generated by this generator."
	icon = 'icons/obj/meteor_shield.dmi'
	icon_state = "podbay-EnergyShield"
	MAX_POWER_LEVEL = 2
	MIN_POWER_LEVEL = 1
	density = 0
	power_usage = 5 //default
	anchored = 1
	range = 0
	connected = 1	//supposed to check if it's over a @wire in parent, but we'll fudge it here because these will only be placed from the editor and we don't want to re-wire things to get this working
	
	var/id
	var/list/obj/machinery/door/poddoor/doors //list of poddoors to create force fields for when opened

	New()
		..()
		display_active.icon_state = "energyShieldOn"
		src.PCEL = null					//Not sure if we should have it start with a power cell or not. I want it to just use station power for now.

	examine()
		if(usr.client)
			boutput(usr, "The unit will consume [30 * (src.power_level * src.power_level)] power per forcefield generated per second.")
			boutput(usr, "The unit is emitting [src.range] force fields.")
	
	set_range()
		set hidden = 1
		boutput(usr, "You feel around for a panel that will allow you to manually set the range, but you can't find one.")
		return

	//need to override to keep this type of generator anchored
	//not sure if I
	shield_off(var/failed = 0)
		..()
		doors = null
		range = 0
		anchored = 1
		if (failed)
			src.visible_message("The <b>[src.name]</b> fails, and shuts down!")
			playsound(src.loc,'sound/voice/Oh_Man_Oh_God_Oh_Man.ogg', 50, 1)
		else
			playsound(src.loc, src.sound_off, 50, 1)


	shield_on()
		range = max(src.deployed_shields.len, 0) //just in cases
		if (!powered()) //if NOT connected to power grid and there is power
			src.power_usage = 0
			shield_off()
			
		else //no power cell, not connected to grid: power down if active, do nothing otherwise
			src.power_usage = 30 * (src.range) * (power_level * power_level)
			generate_shield()
			
		return

	//Manual off switch
	attack_hand(mob/user as mob)
		boutput(usr, "You punch [src]\'s manual off switch.")

		if (src.active)
			src.shield_off()
		return
		
	//Code for placing the shields and adding them to the generator's shield list
	proc/generate_shield()
		if (doors)
			DOOR_LOOP:
				for (var/obj/machinery/door/poddoor/D in doors)

					//OK, I know what you're thinking, it should be !D.density, except no because door.open() has a spawn that makes it take a while to
					//change the density. And unless I'm going to throw more sleeps/spawns around I'd have to do this.
					if (D.density || D.operating)

						//Search the turf of the current door, if it has a energyshield already on it, don't draw another, just in case. 
						//A bit inefficient, but more efficient than drawing another shield accidentally.
						for (var/obj/forcefield/energyshield/E in D.loc.contents)
							continue DOOR_LOOP

						var/obj/forcefield/energyshield/S = new /obj/forcefield/energyshield ( locate((D.x),(D.y),D.z), src , 1 )
						if (D.dir == NORTH | D.dir == SOUTH)
							S.dir = NORTH
						else if (D.dir == EAST | D.dir == WEST)
							S.dir = EAST
						src.deployed_shields += S
						range++


					else	//loop through forcefields to find field at current turf and delete it
							//this is required because switches just flip open values. open = !open, instead of explicitely giving an "open" or "close" command. 
							//so some doors can be open while others in the same area can be closed
						for (var/obj/forcefield/energyshield/S in deployed_shields)

							if (D.loc == S.loc)
								src.deployed_shields -= S
								S:deployer = null
								qdel(S)

								src.deployed_shields.Remove(S)
								doors -= D
								range--
								continue


		if (power_level == 1)
			display_active.color = "#0000FA"
		else if (power_level == 2)
			display_active.color = "#00FF00"


		if (src.deployed_shields.len)
			src.active = 1
			playsound(src.loc, src.sound_on, 50, 1)
		else
			src.active = 0
			shield_off()

		
		build_icon()