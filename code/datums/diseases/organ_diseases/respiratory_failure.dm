//unfinished
/datum/ailment/disease/respiratory_failure
	name = "Respiratory Failure"
	scantype = "Medical Emergency"
	max_stages = 3
	spread = "The patient's respiratory is starting to fail"
	cure = "Organ Drug Class 1"
	reagentcure = list("organ_drug1")
	recureprob = 10
	affected_species = list("Human")
	stage_prob = 1
	var/robo_restart = 0

	on_remove()

/datum/ailment/disease/respiratory_failure/stage_act(var/mob/living/affected_mob,var/datum/ailment_data/D)
	if (..())
		return

	if (!ishuman(affected_mob))
		return
	var/mob/living/carbon/human/H = affected_mob

	//to cure, gotta remove BOTH lungs. Don't want to make it too easy for ya
	if (!H.organHolder|| (!H.organHolder.left_lung && !H.organHolder.right_lung))
		H.cure_disease(D)
		return

	//if one lung is dead, you're in stage 3 resp failure, no exceptions. Need to fix with lung surgery to replace the dead one.
	if ((H.organHolder.left_lung && H.organHolder.left_lung.get_damage() >= 100) || (H.organHolder.right_lung && H.organHolder.right_lung.get_damage() >= 100))
		D.stage = 3

		//handle roborespiratory failuer. should do some stuff I guess
		// else if (H.organHolder.respiratory && H.organHolder.respiratory.robotic && !H.organHolder.heart.health > 0)

	switch (D.stage)
		if (1)
			if (prob(1) && prob(10))
				boutput(affected_mob, "<span style=\"color:blue\">You feel better.</span>")
				affected_mob.cure_disease(D)
				return
			if (prob(8)) affected_mob.emote(pick("pale", "shudder"))
			if (prob(5))
				boutput(affected_mob, "<span style=\"color:red\">Your ribs hurt!</span>")
		if (2)
			if (prob(1) && prob(10))
				boutput(affected_mob, "<span style=\"color:blue\">You feel better.</span>")
				affected_mob.resistances += src.type
				affected_mob.ailments -= src
				return
			if (prob(8)) affected_mob.emote(pick("pale", "groan"))
			if (prob(10))
				boutput(affected_mob, "<span style=\"color:red\">It hurts to breathe!</span>")
				H.losebreath++

			if (prob(5)) affected_mob.emote(pick("faint", "collapse", "groan"))
		if (3)
			if (prob(8)) affected_mob.emote(pick("twitch", "gasp"))
				
			if (prob(20)) 
				affected_mob.emote(pick("twitch", "gasp"))
				boutput(affected_mob, "<span style=\"color:red\">You can hardly breathe due to the pain!</span>")

				H.organHolder.damage_organs(0, 0, 3, 60, list("left_lung", "right_lung"))
				H.losebreath+=2

			affected_mob.take_oxygen_deprivation(1)
			affected_mob.updatehealth()
