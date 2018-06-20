/obj/machinery/shieldgenerator
	name = "Shield generator parent"
	desc = "blah blah blah."
	density = 1
	opacity = 0
	anchored = 0
	mats = 9
	var/obj/item/cell/PCEL = null
	var/coveropen = 0
	var/active = 0
	var/range = 2
	var/min_range = 1
	var/max_range = 6
	var/battery_level = 0
	var/power_level = 1	//unused in meteor, used in energy shield
	var/image/display_active = null
	var/image/display_battery = null
	var/image/display_panel = null
	var/sound/sound_on = 'sound/effects/shielddown.ogg'
	var/sound/sound_off = 'sound/effects/shielddown2.ogg'
	var/sound/sound_shieldhit = 'sound/effects/shieldhit2.ogg'
	var/sound/sound_battwarning = 'sound/machines/pod_alarm.ogg'
	var/list/deployed_shields = list()
	var/direction = ""	//for building the icon, always north or directional
	var/connected = 0	//determine if gen is wrenched over a wire.
	var/backup = 0		//if equip power went out while connected to wire, this should be true. Used to automatically turn gen back on if power is restored
	var/first = 0		//tic when the power goes out. 
	var/MAX_POWER_LEVEL = 1
	var/MIN_POWER_LEVEL = 1

	New()
		PCEL = new /obj/item/cell/supercell(src)
		PCEL.charge = PCEL.maxcharge

		src.display_active = image('icons/obj/meteor_shield.dmi', "on")
		src.display_battery = image('icons/obj/meteor_shield.dmi', "")
		src.display_panel = image('icons/obj/meteor_shield.dmi', "")
		..()

	disposing()
		shield_off(1)
		if (PCEL)
			PCEL.dispose()
		PCEL = null
		display_active = null
		display_battery = null
		display_panel = null
		sound_on = null
		sound_off = null
		sound_battwarning = null
		sound_shieldhit = null
		deployed_shields = list()
		..()

	process()
		if (src.active)
			if(PCEL && !connected)
				process_battery()
			else
				process_wired()
			
		if (backup)
			src.active = !src.active


	proc/process_wired()
		//must be wrenched on top of a wire
		if (!connected)
			return

		if (powered()) //if connected to power grid and there is power
			src.power_usage = 30 * (src.range + 1) * (power_level * power_level)
			use_power(src.power_usage)

			//automatically turn back on if gen was deactivated due to power outage
			if (backup)
				backup = !backup
				src.shield_on()

			src.battery_level = 3
			src.build_icon()

			return
		else //connected grid has no power
			if (!backup)
				backup = !backup
				first = 1
			//this iff is for testing the auto turn back on
			if (src.active && first)
				first = 0
				src.shield_off()
			return

	proc/process_battery()
		PCEL.charge -= 30 * src.range * (power_level * power_level)
		var/charge_percentage = 0
		var/current_battery_level = 0
		if (PCEL && PCEL.charge > 0 && PCEL.maxcharge > 0)
			charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
			switch(charge_percentage)
				if (75 to 100)
					current_battery_level = 3
				if (35 to 74)
					current_battery_level = 2
				else
					current_battery_level = 1

		if (current_battery_level != src.battery_level)
			src.battery_level = current_battery_level
			src.build_icon()
			if (src.battery_level == 1)
				playsound(src.loc, src.sound_battwarning, 50, 1)
				src.visible_message("<span style=\"color:red\">The <b>[src.name] emits a low battery alarm!</b></span>")
		
		if (PCEL.charge < 0)
			src.visible_message("The <b>[src.name]</b> runs out of power and shuts down.")
			src.shield_off()
			return

	examine()
		..()
		if(usr.client)
			var/charge_percentage = 0
			if (PCEL && PCEL.charge > 0 && PCEL.maxcharge > 0)
				charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
				boutput(usr, "It has [PCEL.charge]/[PCEL.maxcharge] ([charge_percentage]%) battery power left.")
				boutput(usr, "The range setting is set to [src.range].")
				boutput(usr, "The unit will consume [30 * src.range] power a second, and [60 * src.range] per meteor strike against the projected shield.")
			else
				boutput(usr, "It seems to be missing a usable battery.")

	attack_hand(mob/user as mob)
		if (src.coveropen && src.PCEL)
			src.PCEL.set_loc(src.loc)
			src.PCEL = null
			boutput(user, "You remove the power cell.")
			if (src.active)
				src.shield_off()
		else
			if (src.active)
				src.shield_off()
				src.visible_message("<b>[user.name]</b> powers down the [src.name].")
			else
				if (PCEL)
					if (PCEL.charge > 0)
						src.shield_on()
						src.visible_message("<b>[user.name]</b> powers up the [src.name].")
					else
						boutput(user, "The [src.name]'s battery light flickers briefly.")
				else	//turn on power if connected to a power grid with power in it
					if (powered() && connected)
						src.shield_on()
						src.visible_message("<b>[user.name]</b> powers up the [src.name].")
					else
						boutput(user, "The [src.name]'s battery light flickers briefly.")
		build_icon()

	attackby(obj/item/W as obj, mob/user as mob)
		if (istype(W, /obj/item/screwdriver))
			if (!active)
				src.coveropen = !src.coveropen
				src.visible_message("<b>[user.name]</b> [src.coveropen ? "opens" : "closes"] [src.name]'s cell cover.")
			else
				boutput(user, "You don't think you should mess around with the [src.name] while it's active.")
				return

		else if (istype(W, /obj/item/wrench))
			if (PCEL)
				boutput(user, "You can't think of a reason to attach the [src.name] to a wire when it already has a battery.")
				return

			//just checking if it's placed on any wire, like powersink
			var/obj/cable/C = locate() in get_turf(src)
			if (C) //if generator is on wire
				src.connected = !src.connected
				src.anchored = !src.anchored
				src.backup = 0
				src.visible_message("<b>[user.name]</b> [src.connected ? "connects" : "disconnects"] [src.name] [src.connected ? "to" : "from"] the wire.")
				playsound(src.loc, "sound/items/Ratchet.ogg", 50, 1)
			else
				boutput(user, "There is no cable to connect to.")


		else if (src.coveropen && !src.PCEL)
			if (istype(W,/obj/item/cell/))
				if (connected)
					boutput(user, "You think it's a bad idea to attach a battery to the [src.name] while it's connected to a wire.")
					return

				user.drop_item()
				W.set_loc(src)
				src.PCEL = W
				boutput(user, "You insert the power cell.")


		else
			..()

		build_icon()

	attack_ai(mob/user as mob)
		return attack_hand(user)		

	verb/set_range()
		set src in view(1)
		set name = "Set Range"

		if (!istype(usr,/mob/living/))
			boutput(usr, "<span style=\"color:red\">Your ghostly arms phase right through the [src.name] and you sadly contemplate the state of your existence.</span>")
			boutput(usr, "<span style=\"color:red\">That's what happens when you try to be a smartass, you dead sack of crap.</span>")
			return

		if (get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You need to be closer to do that.</span>")
			return

		var/the_range = input("Enter a range from [src.min_range]-[src.max_range]. Higher ranges use more power.","[src.name]",2) as null|num
		if (!the_range)
			return
		if (get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You flail your arms at [src.name] from across the room like a complete muppet. Move closer, genius!</span>")
			return
		the_range = max(src.min_range,min(the_range,src.max_range))
		src.range = the_range
		var/outcome_text = "You set the range to [src.range]."
		if (src.active)
			outcome_text += " The generator shuts down for a brief moment to recalibrate."
			shield_off()
			sleep(5)
			shield_on()
		boutput(usr, "<span style=\"color:blue\">[outcome_text]</span>")

	verb/set_power_level()
		set src in view(1)
		set name = "Set Power Level"

		if (active)
			boutput(usr, "<span style=\"color:red\">You can't change the power level while the generator is active.</span>")
			return

		if (get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You need to be closer to do that.</span>")
			return
		var/the_level = input("Enter a power level from [src.MIN_POWER_LEVEL]-[src.MAX_POWER_LEVEL]. Higher ranges use more power.","[src.name]",1) as null|num
		if (!the_level)
			return
		if (get_dist(usr,src) > 1)
			boutput(usr, "<span style=\"color:red\">You flail your arms at [src] from across the room like a complete muppet. Move closer, genius!</span>")
			return
		the_level = max(MIN_POWER_LEVEL,min(the_level,MAX_POWER_LEVEL))
		src.power_level = the_level
		boutput(usr, "<span style=\"color:blue\">You set the power level to [src.power_level].</span>")


	proc/build_icon()
		src.overlays = null
		if (src.coveropen)
			if (istype(src.PCEL,/obj/item/cell/))
				src.display_panel.icon_state = "panel-batt[direction]"
			else
				src.display_panel.icon_state = "panel-nobatt[direction]"

			src.overlays += src.display_panel

		if (src.active)
			src.overlays += src.display_active
			if (istype(src.PCEL,/obj/item/cell))
				var/charge_percentage = null
				if (PCEL.charge > 0 && PCEL.maxcharge > 0)
					charge_percentage = round((PCEL.charge/PCEL.maxcharge)*100)
					switch(charge_percentage)
						if (75 to 100)
							src.display_battery.icon_state = "batt-3[direction]"
						if (35 to 74)
							src.display_battery.icon_state = "batt-2[direction]"
						else
							src.display_battery.icon_state = "batt-1[direction]"
				else
					src.display_battery.icon_state = "batt-3[direction]"
				src.overlays += src.display_battery

	//this method should be overridden. Currenlty just draws single tile meteor shield
	proc/shield_on()
		if (!PCEL)
			return
		if (PCEL.charge < 0)
			return

		var/turf/T = locate((src.x),(src.y),src.z)
		var/obj/forcefield/meteorshield/S = new /obj/forcefield/meteorshield(T)
		S.deployer = src
		src.deployed_shields += S

		src.anchored = 1
		src.active = 1
		playsound(src.loc, src.sound_on, 50, 1)
		build_icon()


	proc/shield_off(var/failed = 0)
		for(var/obj/forcefield/S in src.deployed_shields)
			src.deployed_shields -= S
			S:deployer = null	//There is no parent forcefield object and I'm not gonna be the one to make it so ":"
			qdel(S)

		if (!connected)
			src.anchored = 0
		src.active = 0
		
		//currently only the e-shield interacts with atmos
		// if (istype(src,/obj/machinery/shieldgenerator/energy_shield))
		// 	update_nearby_tiles()
		if (failed)
			src.visible_message("The <b>[src.name]</b> fails, and shuts down!")
		playsound(src.loc, src.sound_off, 50, 1)
		build_icon()

//Force field objects for various generators
/obj/forcefield/meteorshield
	name = "Impact Forcefield"
	desc = "A force field deployed to stop meteors and other high velocity masses."
	icon = 'icons/obj/meteor_shield.dmi'
	icon_state = "shield"
	var/sound/sound_shieldhit = 'sound/effects/shieldhit2.ogg'
	var/obj/machinery/shieldgenerator/meteorshield/deployer = null

	meteorhit(obj/O as obj)
		if (istype(deployer, /obj/machinery/shieldgenerator/meteorshield))
			var/obj/machinery/shieldgenerator/meteorshield/MS = deployer
			if (MS.PCEL)
				MS.PCEL.charge -= 60 * MS.range
				playsound(src.loc, src.sound_shieldhit, 50, 1)
			else
				deployer = null
				qdel(src)

		else if (istype(deployer, /obj/machinery/shieldgenerator))
			var/obj/machinery/shieldgenerator/SG = deployer
			if ((SG.stat & (NOPOWER|BROKEN)) || !SG.powered())
				deployer = null
				qdel(src)
			SG.use_power(10)
			playsound(src.loc, src.sound_shieldhit, 50, 1)

		else
			deployer = null
			qdel(src)

/obj/forcefield/energyshield
	name = "Forcefield"
	desc = "A force field that can block various states of matter."
	icon = 'icons/obj/meteor_shield.dmi'
	icon_state = "shieldw"

	var/sound/sound_shieldhit = 'sound/effects/shieldhit2.ogg'
	var/obj/machinery/shieldgenerator/deployer = null
	var/update_tiles
	
	New(Loc, var/obj/machinery/shieldgenerator/deployer, var/update_tiles)
		..()
		src.update_tiles = update_tiles
		src.deployer = deployer

		if (update_tiles)
			update_nearby_tiles()
		
		if (deployer != null && deployer.power_level == 1)
			src.name = "Atmospheric Forcefield"
			src.desc = "A force field that prevents gas from passing through it."
			src.icon_state = "shieldw" //change colour or something for different power levels
			src.color = "#0000FA"
		else if (deployer.power_level == 2)
			src.name = "Atmospheric/Liquid Forcefield"
			src.desc = "A force field that prevents gas and liquids from passing through it."
			src.icon_state = "shieldw" //change colour or something for different power levels
			src.color = "#33FF33"
		else
			src.name = "Energy Forcefield"
			src.desc = "A force field that prevents matter from passing through it."
			src.icon_state = "shieldw" //change colour or something for different power levels
			src.color = "#FF3333"

	disposing()
		if(update_tiles)
			update_nearby_tiles()



	proc/update_nearby_tiles(need_rebuild)
		var/turf/simulated/source = loc
		if (istype(source))
			return source.update_nearby_tiles(need_rebuild)

		return 1

	CanPass(atom/A, turf/T)
		if (deployer == null) return 0

		var/level = deployer.power_level

		switch(level)
			//power level one, atmos shield. Only atmos is blocked by this forcefield
			if(1)
				if (ismob(A)) return 1
				if (isobj(A)) return 1
				// if (isliquid(A)) return 1			//change this to the proc to check if it's liquid/////////////

			//power level 2, liquid shield. Only liquids are blocked by this forcefield
			if(2)
				if (ismob(A)) return 1
				if (isobj(A)) return 1
				// if (isliquid(A)) return 0			//change this to the proc to check if it's liquid//////////////////

			//power level 3, solid shield. Nothing can pass by this shield
			if(3)
				return 0

		if (deployer.power_level == 1 || deployer.power_level == 2)
			if (ismob(A)) return 1
			if (isobj(A)) return 1
		else return 0

	meteorhit(obj/O as obj)
		if (istype(deployer, /obj/machinery/shieldgenerator/energy_shield))
			var/obj/machinery/shieldgenerator/energy_shield/ES = deployer
			//unless the power level is 3, which blocks solid objects, meteors should pass through unmolested
			if (ES.power_level == 3)
				if (ES.PCEL)	//Technically these shields can be used as emergency meteor shields, but they are very bad a blocking them
					ES.PCEL.charge -= 10 * ES.range * (ES.power_level * ES.power_level)
					playsound(src.loc, src.sound_shieldhit, 50, 1)
				else
					deployer = null
					qdel(src)

		else
			deployer = null
			qdel(src)