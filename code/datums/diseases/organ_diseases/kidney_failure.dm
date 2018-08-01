//unfinished
/datum/ailment/disease/kidney_failure
	name = "Kidney Failure"
	scantype = "Medical Emergency"
	max_stages = 3
	spread = "The patient's kidneys are starting to fail"
	cure = "Organ Drug Class 2"
	reagentcure = list("organ_drug2")
	recureprob = 10
	affected_species = list("Human")
	stage_prob = 1
	var/robo_restart = 0

/datum/ailment/disease/kidney_failure/stage_act(var/mob/living/affected_mob,var/datum/ailment_data/D)
	if (..())
		return

	if (ishuman(affected_mob))
		var/mob/living/carbon/human/H = affected_mob
		
		if (!H.organHolder)
			H.cure_disease(D)
			return

		var/datum/organHolder/oH = H.organHolder
		if (!oH.kidney)
			H.cure_disease(D)
			return

		//handle robokidney failuer. should do some stuff I guess
		// else if (oH.kidney && oH.kidney.robotic && !oH.heart.health > 0)

	switch (D.stage)
		if (1)
			if (prob(1) && prob(10))
				boutput(affected_mob, "<span style=\"color:blue\">You feel better.</span>")
				affected_mob.cure_disease(D)
				return
			if (prob(8)) affected_mob.emote(pick("pale", "shudder"))
			if (prob(5))
				boutput(affected_mob, "<span style=\"color:red\">Your abdomen area hurts!</span>")
		if (2)
			if (prob(1) && prob(10))
				boutput(affected_mob, "<span style=\"color:blue\">You feel better.</span>")
				affected_mob.resistances += src.type
				affected_mob.ailments -= src
				return
			if (prob(8)) affected_mob.emote(pick("pale", "groan"))
			if (prob(5))
				boutput(affected_mob, "<span style=\"color:red\">Your back aches terribly!</span>")
			if (prob(3))
				boutput(affected_mob, "<span style=\"color:red\">You feel excruciating pain in your upper-right adbomen!</span>")
				// oH.takekidney

			if (prob(5)) affected_mob.emote(pick("faint", "collapse", "groan"))
		if (3)
			if (prob(8)) affected_mob.emote(pick("twitch", "gasp"))
				
			if (prob(20)) 
				affected_mob.emote(pick("twitch", "gasp"))
				H.damage_organs(3, 20, list("left_kidney", "right_kidney"))
				H.losebreath++

			affected_mob.take_oxygen_deprivation(1)
			affected_mob.updatehealth()