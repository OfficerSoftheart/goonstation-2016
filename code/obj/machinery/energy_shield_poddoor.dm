/obj/machinery/shieldgenerator/energy_shield_poddoor
	icon_state = "energyShieldWall"
	var/id
	var/const/MAX_POWER_LEVEL = 3
	var/const/MIN_POWER_LEVEL = 1
	var/list/x_locations = new/list()		//list of locations to draw the forcefield on
	var/list/y_locations = new/list()

	New()
		..()
		display_active.icon_state = "energyShieldOn"
		src.power_usage = 5
		src.anchored = 1
		src.PCEL = null					//Not sure if we should have it start with a power cell or not. I want it to just use station power.
		src.range = 0

	proc/add_xy_to_list(var/x, var/y)
		x_locations.Add(x)
		y_locations.Add(y)
		range++
	
	proc/reset_xy_lists()
		x_locations = new/list()
		y_locations = new/list()
		range = 0

	shield_off()
		..()
		reset_xy_lists()

	examine()
		if(usr.client)
			var/charge_percentage = 0
			if (PCEL && PCEL.charge > 0 && PCEL.maxcharge > 0)
				charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
				boutput(usr, "It has [PCEL.charge]/[PCEL.maxcharge] ([charge_percentage]%) battery power left.")
			else
				boutput(usr, "It seems to be missing a usable battery.")
			boutput(usr, "The unit will consume [30 * src.range * (src.power_level * src.power_level)] power a second.")
			boutput(usr, "The unit is emitting [src.range] force fields.")

	//need to override to keep this type of generator anchored
	shield_off()
		..()
		src.anchored = 1

	shield_on()
		if (!PCEL)
			if (!powered()) //if NOT connected to power grid and there is power
				src.power_usage = 0
				return
			else //no power cell, not connected to grid: power down if active, do nothing otherwise
				src.power_usage = 30 * (src.range + 1) * (power_level * power_level)
				generate_shield()
				return
		else
			if (PCEL.charge > 0)
				generate_shield()
				return

	//Code for placing the shields and adding them to the generator's shield list
	proc/generate_shield()
		if (x_locations.len == y_locations.len)
			for(var/i = 1 to x_locations.len)
				var/obj/forcefield/energyshield/S = new /obj/forcefield/energyshield ( locate((x),(y),z), src , 1 )
				display_active.color = "#0000FA"
				src.deployed_shields += S
				range++
			    
		src.active = 1

		playsound(src.loc, src.sound_on, 50, 1)
		build_icon()

	//this is so long because I wanted the tiles to look like one seamless object. Otherwise it could just be a single line 
	// proc/createForcefieldObject(var/xa as num, var/ya as num)
	// 	var/obj/forcefield/energyshield/S = new /obj/forcefield/energyshield (locate((src.x + xa),(src.y + ya),src.z), src, 1 ) //1 update tiles
	// 	if (xa == -range)
	// 		S.dir = SOUTHWEST
	// 	else if (xa == range)
	// 		S.dir = SOUTHEAST
	// 	else if (ya == -range)
	// 		S.dir = NORTHWEST
	// 	else if (ya == range)
	// 		S.dir = NORTHEAST
	// 	else if (orientation)
	// 		S.dir = NORTH
	// 	else if (!orientation)
	// 		S.dir = EAST

	// 	src.deployed_shields += S

	// 	return S
