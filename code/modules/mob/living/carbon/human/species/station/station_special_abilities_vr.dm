/mob/living/carbon/human/proc/begin_reconstitute_form() //Scree's race ability.in exchange for: No cloning.
	set name = "Reconstitute Form"
	set category = "Abilities"

	if(world.time < last_special)
		return

	last_special = world.time + 50 //To prevent button spam.

	var/confirm = alert(usr, "Are you sure you want to completely reconstruct your form? This process can take up to twenty minutes, depending on how hungry you are, and you will be unable to move.", "Confirm Regeneration", "Yes", "No")
	if(confirm == "Yes")
		chimera_regenerate()

/mob/living/carbon/human/proc/chimera_regenerate()
	var/nutrition_used = nutrition/2

	if(reviving == TRUE) //If they're already unable to
		to_chat(src, "You are already reconstructing, or your body is currently recovering from the intense process of your previous reconstitution.")
		return

	if(stat == DEAD) //Uh oh, you died!
		if(hasnutriment()) //Let's hope you have nutriment in you.... If not
			var/time = (240+960/(1 + nutrition_used/75))
			reviving = TRUE
			to_chat(src, "You begin to reconstruct your form. You will not be able to move during this time. It should take aproximately [round(time)] seconds.")
			//don't need all the weakened, does_not_breathe, canmove, heal IB crap here like you do for live ones'cause they're DEAD.

			spawn(time SECONDS)
				if(src) //Runtime prevention.
					if (stat == DEAD) // let's make sure they've not been defibbed or whatever
						to_chat(src, "<span class='notice'>Consciousness begins to stir as your new body awakens, ready to hatch.</span>")
						verbs += /mob/living/carbon/human/proc/hatch
						return
					else // their revive got aborted by being made not-dead. Remove their cooldown.
						to_chat(src, "<span class='notice'>Your body has recovered from its ordeal, ready to regenerate itself again.</span>")
						reviving = FALSE
						return
				else
					return //Something went wrong.
		else //Dead until nutrition injected.
			to_chat(src, "Your body is too damaged to regenerate without additional nutrients to feed what few living cells remain.")
			return

	else if(stat != DEAD) //If they're alive at the time of regenerating.
		var/time = (240+960/(1 + nutrition_used/75))
		weakened = 10000 //Since it takes 1 tick to lose one weaken. Due to prior rounding errors, you'd sometimes unweaken before regenning. This fixes that.
		reviving = TRUE
		canmove = 0 //Make them unable to move. In case they somehow get up before the delay.
		to_chat(src, "You begin to reconstruct your form. You will not be able to move during this time. It should take aproximately [round(time)] seconds.")
		does_not_breathe = 1 //effectively makes them spaceworthy while regenning

		spawn(time SECONDS)
			if(stat != DEAD) //If they're still alive after regenning.
				to_chat(src, "<span class='notice'>Consciousness begins to stir as your new body awakens, ready to hatch..</span>")
				verbs += /mob/living/carbon/human/proc/hatch
				return
			else if(stat == DEAD)
				if(hasnutriment()) //Let's hope you have nutriment in you.... If not
					to_chat(src, "<span class='notice'>Consciousness begins to stir as your new body awakens, ready to hatch..</span>")
					verbs += /mob/living/carbon/human/proc/hatch
					return
				else //Dead until nutrition injected.
					to_chat(src, "Your body was unable to regenerate, what few living cells remain require additional nutrients to complete the process.")
					reviving = FALSE // so they can try again when they're given a kickstart
					return
			else
				return //Something went wrong
	else
		return //Something went wrong

/mob/living/carbon/human/proc/hasnutriment()
	if (bloodstr.has_reagent("nutriment", 30) || src.bloodstr.has_reagent("protein", 15)) //protein needs half as much. For reference, a steak contains 9u protein.
		return 1
	else if (ingested.has_reagent("nutriment", 60) || src.ingested.has_reagent("protein", 30)) //try forcefeeding them, why not. Less effective.
		return 1
	else return 0


/mob/living/carbon/human/proc/hatch()
	set name = "Hatch"
	set category = "Abilities"

	if(world.time < last_special)
		return

	last_special = world.time + 50 //To prevent button spam.

	var/confirm = alert(usr, "Are you sure you want to hatch right now? This will be very obvious to anyone in view.", "Confirm Regeneration", "Yes", "No")
	if(confirm == "Yes")
		if(stat == DEAD) //Uh oh, you died!
			if(hasnutriment()) //Let's hope you have nutriment in you.... If not
				if(src) //Runtime prevention.
					chimera_hatch()
					visible_message("<span class='danger'><p><font size=4>The lifeless husk of [src] bursts open, revealing a new, intact copy in the pool of viscera.</font></p></span>") //Bloody hell...
					brainloss += 10 //Reviving from dead means you take a lil' brainloss on top of whatever was healed in the revive.
					return
				else
					return //Runtime prevention
			else //don't have nutriment to hatch! Or you somehow died in between completing your revive and hitting hatch.
				to_chat(src, "Your body was unable to regenerate, what few living cells remain require additional nutrients to complete the process.")
				reviving = FALSE // so they can try again when they're given a kickstart
				return

		else if(stat != DEAD) //If they're alive at the time of regenerating.
			chimera_hatch()
			visible_message("<span class='danger'><p><font size=4>The dormant husk of [src] bursts open, revealing a new, intact copy in the pool of viscera.</font></p></span>") //Bloody hell...
			return
		else
			return //Runtime prevention.

/mob/living/carbon/human/proc/chimera_hatch()
	nutrition -= nutrition/2 //Cut their nutrition in half.
	var/old_nutrition = nutrition //Since the game is being annoying.
	to_chat(src, "<span class='notice'>Your new body awakens, bursting free from your old skin.</span>")
	var/T = get_turf(src)
	new /obj/effect/gibspawner/human/scree(T)
	var/braindamage = brainloss/2 //If you have 100 brainloss, it gives you 50.
	does_not_breathe = 0 //start breathing again
	revive() // I did have special snowflake code, but this is easier.
	weakened = 2 //Not going to let you get up immediately. 2 ticks before you get up. Overrides the above 10000 weaken.
	mutations.Remove(HUSK)
	nutrition = old_nutrition
	brainloss = braindamage //Gives them half their prior brain damage.
	update_canmove()
	for(var/obj/item/W in src)
		drop_from_inventory(W)
	spawn(3600 SECONDS) //1 hour wait until you can revive.
		reviving = FALSE
		to_chat(src, "Your body has recovered from the strenuous effort of rebuilding itself.")
	verbs -= /mob/living/carbon/human/proc/hatch
	return

/obj/effect/gibspawner/human/scree
	fleshcolor = "#14AD8B" //Scree blood.
	bloodcolor = "#14AD8B"

/mob/living/carbon/human/proc/getlightlevel() //easier than having the same code in like three places
	if(isturf(src.loc)) //else, there's considered to be no light
		var/turf/T = src.loc
		return T.get_lumcount() * 5
	else return 0

/mob/living/carbon/human/proc/handle_feral()
	if(handling_hal) return //avoid conflict with actual hallucinations
	handling_hal = 1

	if(client && feral >= 10) // largely a copy of handle_hallucinations() without the fake attackers. Unlike hallucinations, only fires once - if they're still feral they'll get hit again anyway.
		spawn(rand(200,500)/(feral/10))
			if(!feral) return //just to avoid fuckery in the event that they un-feral in the time it takes for the spawn to proc
			var/halpick = rand(1,100)
			switch(halpick)
				if(0 to 15) //15% chance
					//Screwy HUD
					//src << "Screwy HUD"
					hal_screwyhud = pick(1,2,3,3,4,4)
					spawn(rand(100,250))
						hal_screwyhud = 0
				if(16 to 25) //10% chance
					//Strange items
					//src << "Traitor Items"
					if(!halitem)
						halitem = new
						var/list/slots_free = list(ui_lhand,ui_rhand)
						if(l_hand) slots_free -= ui_lhand
						if(r_hand) slots_free -= ui_rhand
						if(istype(src,/mob/living/carbon/human))
							var/mob/living/carbon/human/H = src
							if(!H.belt) slots_free += ui_belt
							if(!H.l_store) slots_free += ui_storage1
							if(!H.r_store) slots_free += ui_storage2
						if(slots_free.len)
							halitem.screen_loc = pick(slots_free)
							halitem.layer = 50
							switch(rand(1,6))
								if(1) //revolver
									halitem.icon = 'icons/obj/gun.dmi'
									halitem.icon_state = "revolver"
									halitem.name = "Revolver"
								if(2) //c4
									halitem.icon = 'icons/obj/assemblies.dmi'
									halitem.icon_state = "plastic-explosive0"
									halitem.name = "Mysterious Package"
									if(prob(25))
										halitem.icon_state = "c4small_1"
								if(3) //sword
									halitem.icon = 'icons/obj/weapons.dmi'
									halitem.icon_state = "sword1"
									halitem.name = "Sword"
								if(4) //stun baton
									halitem.icon = 'icons/obj/weapons.dmi'
									halitem.icon_state = "stunbaton"
									halitem.name = "Stun Baton"
								if(5) //emag
									halitem.icon = 'icons/obj/card.dmi'
									halitem.icon_state = "emag"
									halitem.name = "Cryptographic Sequencer"
								if(6) //flashbang
									halitem.icon = 'icons/obj/grenade.dmi'
									halitem.icon_state = "flashbang1"
									halitem.name = "Flashbang"
							if(client) client.screen += halitem
							spawn(rand(100,250))
								if(client)
									client.screen -= halitem
								halitem = null
				if(26 to 35) //10% chance
					//Flashes of danger
					//src << "Danger Flash"
					if(!halimage)
						var/list/possible_points = list()
						for(var/turf/simulated/floor/F in view(src,world.view))
							possible_points += F
						if(possible_points.len)
							var/turf/simulated/floor/target = pick(possible_points)

							switch(rand(1,3))
								if(1)
									//src << "Space"
									halimage = image('icons/turf/space.dmi',target,"[rand(1,25)]",TURF_LAYER)
								if(2)
									//src << "Fire"
									halimage = image('icons/effects/fire.dmi',target,"1",TURF_LAYER)
								if(3)
									//src << "C4"
									halimage = image('icons/obj/assemblies.dmi',target,"plastic-explosive2",OBJ_LAYER+0.01)


							if(client) client.images += halimage
							spawn(rand(10,50)) //Only seen for a brief moment.
								if(client) client.images -= halimage
								halimage = null

				if(36 to 55) //20% chance
					//Strange audio
					//src << "Strange Audio"
					switch(rand(1,12))
						if(1) src << 'sound/machines/airlock.ogg'
						if(2)
							if(prob(50))src << 'sound/effects/Explosion1.ogg'
							else src << 'sound/effects/Explosion2.ogg'
						if(3) src << 'sound/effects/explosionfar.ogg'
						if(4) src << 'sound/effects/Glassbr1.ogg'
						if(5) src << 'sound/effects/Glassbr2.ogg'
						if(6) src << 'sound/effects/Glassbr3.ogg'
						if(7) src << 'sound/machines/twobeep.ogg'
						if(8) src << 'sound/machines/windowdoor.ogg'
						if(9)
							//To make it more realistic, I added two gunshots (enough to kill)
							src << 'sound/weapons/Gunshot.ogg'
							spawn(rand(10,30))
								src << 'sound/weapons/Gunshot.ogg'
						if(10) src << 'sound/weapons/smash.ogg'
						if(11)
							//Same as above, but with tasers.
							src << 'sound/weapons/Taser.ogg'
							spawn(rand(10,30))
								src << 'sound/weapons/Taser.ogg'
					//Rare audio
						if(12)
	//These sounds are (mostly) taken from Hidden: Source
							var/list/creepyasssounds = list('sound/effects/ghost.ogg', 'sound/effects/ghost2.ogg', 'sound/effects/Heart Beat.ogg', 'sound/effects/screech.ogg',\
								'sound/hallucinations/behind_you1.ogg', 'sound/hallucinations/behind_you2.ogg', 'sound/hallucinations/far_noise.ogg', 'sound/hallucinations/growl1.ogg', 'sound/hallucinations/growl2.ogg',\
								'sound/hallucinations/growl3.ogg', 'sound/hallucinations/im_here1.ogg', 'sound/hallucinations/im_here2.ogg', 'sound/hallucinations/i_see_you1.ogg', 'sound/hallucinations/i_see_you2.ogg',\
								'sound/hallucinations/look_up1.ogg', 'sound/hallucinations/look_up2.ogg', 'sound/hallucinations/over_here1.ogg', 'sound/hallucinations/over_here2.ogg', 'sound/hallucinations/over_here3.ogg',\
								'sound/hallucinations/turn_around1.ogg', 'sound/hallucinations/turn_around2.ogg', 'sound/hallucinations/veryfar_noise.ogg', 'sound/hallucinations/wail.ogg')
							src << pick(creepyasssounds)
				if(56 to 60) //5% chance
					//Flashes of danger
					//src << "Danger Flash"
					if(!halbody)
						var/list/possible_points = list()
						for(var/turf/simulated/floor/F in view(src,world.view))
							possible_points += F
						if(possible_points.len)
							var/turf/simulated/floor/target = pick(possible_points)
							switch(rand(1,4))
								if(1)
									halbody = image('icons/mob/human.dmi',target,"husk_l",TURF_LAYER)
								if(2,3)
									halbody = image('icons/mob/human.dmi',target,"husk_s",TURF_LAYER)
								if(4)
									halbody = image('icons/mob/alien.dmi',target,"alienother",TURF_LAYER)
		//						if(5)
		//							halbody = image('xcomalien.dmi',target,"chryssalid",TURF_LAYER)

							if(client) client.images += halbody
							spawn(rand(50,80)) //Only seen for a brief moment.
								if(client) client.images -= halbody
								halbody = null
				if(61 to 85) //25% chance
					//food
					if(!halbody)
						var/list/possible_points = list()
						for(var/turf/simulated/floor/F in view(src,world.view))
							possible_points += F
						if(possible_points.len)
							var/turf/simulated/floor/target = pick(possible_points)
							switch(rand(1,10))
								if(1)
									halbody = image('icons/mob/animal.dmi',target,"cow",TURF_LAYER)
								if(2)
									halbody = image('icons/mob/animal.dmi',target,"chicken",TURF_LAYER)
								if(3)
									halbody = image('icons/obj/food.dmi',target,"bigbiteburger",TURF_LAYER)
								if(4)
									halbody = image('icons/obj/food.dmi',target,"meatbreadslice",TURF_LAYER)
								if(5)
									halbody = image('icons/obj/food.dmi',target,"sausage",TURF_LAYER)
								if(6)
									halbody = image('icons/obj/food.dmi',target,"bearmeat",TURF_LAYER)
								if(7)
									halbody = image('icons/obj/food.dmi',target,"fishfillet",TURF_LAYER)
								if(8)
									halbody = image('icons/obj/food.dmi',target,"meat",TURF_LAYER)
								if(9)
									halbody = image('icons/obj/food.dmi',target,"meatstake",TURF_LAYER)
								if(10)
									halbody = image('icons/obj/food.dmi',target,"monkeysdelight",TURF_LAYER)

							if(client) client.images += halbody
							spawn(rand(50,80)) //Only seen for a brief moment.
								if(client) client.images -= halbody
								halbody = null
				if(86 to 100) //15% chance
					//hear voices. Could make the voice pick from nearby creatures, but nearby creatures make feral hallucinations rare so don't bother.
					var/list/hiddenspeakers = list("Someone distant", "A voice nearby","A familiar voice", "An echoing voice", "A cautious voice", "A scared voice", "Someone around the corner", "Someone", "Something", "Something scary", "An urgent voice", "An angry voice")
					var/list/speakerverbs = list("calls out", "yells", "screams", "exclaims", "shrieks", "shouts", "hisses", "snarls")
					var/list/spookyphrases = list("It's over here!","Stop it!", "Hunt it down!", "Get it!", "Quick, over here!", "Anyone there?", "Who's there?", "Catch that thing!", "Stop it! Kill it!", "Anyone there?", "Where is it?", "Find it!", "There it is!")
					to_chat(src, "<span class='game say'><span class='name'>[pick(hiddenspeakers)]</span> [pick(speakerverbs)], \"[pick(spookyphrases)]\"</span>")


	handling_hal = 0
	return


/mob/living/carbon/human/proc/bloodsuck()
	set name = "Partially Drain prey of blood"
	set desc = "Bites prey and drains them of a significant portion of blood, feeding you in the process. You may only do this once per minute."
	set category = "Abilities"

	if(last_special > world.time)
		return

	if(stat || paralysis || stunned || weakened || lying || restrained() || buckled)
		src << "You cannot bite anyone in your current state!"
		return

	var/list/choices = list()
	for(var/mob/living/carbon/human/M in view(1,src))
		if(!istype(M,/mob/living/silicon) && Adjacent(M))
			choices += M
	choices -= src

	var/mob/living/carbon/human/B = input(src,"Who do you wish to bite?") as null|anything in choices

	if(!B || !src || src.stat) return

	if(!Adjacent(B)) return

	if(last_special > world.time) return

	if(stat || paralysis || stunned || weakened || lying || restrained() || buckled)
		src << "You cannot bite in your current state."
		return
	if(B.vessel.total_volume <= 0 || B.isSynthetic()) //Do they have any blood in the first place, and are they synthetic?
		src << "<font color='red'>There appears to be no blood in this prey...</font>"
		return

	last_special = world.time + 600
	src.visible_message("<font color='red'><b>[src] moves their head next to [B]'s neck, seemingly looking for something!</b></font>")

	if(do_after(src, 300, B)) //Thrirty seconds.
		if(!Adjacent(B)) return
		src.visible_message("<font color='red'><b>[src] suddenly extends their fangs and plunges them down into [B]'s neck!</b></font>")
		B.apply_damage(5, BRUTE, BP_HEAD) //You're getting fangs pushed into your neck. What do you expect????
		B.drip(80) //Remove enough blood to make them a bit woozy, but not take oxyloss.
		src.nutrition += 400
		sleep(50)
		B.drip(1)
		sleep(50)
		B.drip(1)


//Welcome to the adapted changeling absorb code.
/mob/living/carbon/human/proc/succubus_drain()
	set name = "Drain prey of nutrition"
	set desc = "Slowly drain prey of all the nutrition in their body, feeding you in the process. You may only do this to one person at a time."
	set category = "Abilities"
	if(!ishuman(src))
		return //If you're not a human you don't have permission to do this.
	var/mob/living/carbon/human/C = src
	var/obj/item/weapon/grab/G = src.get_active_hand()
	if(!istype(G))
		to_chat(C, "<span class='warning'>You must be grabbing a creature in your active hand to absorb them.</span>")
		return

	var/mob/living/carbon/human/T = G.affecting // I must say, this is a quite ingenious way of doing it. Props to the original coders.
	if(!istype(T) || T.isSynthetic())
		to_chat(src, "<span class='warning'>\The [T] is not able to be drained.</span>")
		return

	if(G.state != GRAB_NECK)
		to_chat(C, "<span class='warning'>You must have a tighter grip to drain this creature.</span>")
		return

	if(C.absorbing_prey)
		to_chat(C, "<span class='warning'>You are already draining someone!</span>")
		return

	C.absorbing_prey = 1
	for(var/stage = 1, stage<=100, stage++) //100 stages.
		switch(stage)
			if(1)
				to_chat(C, "<span class='notice'>You begin to drain [T]...</span>")
				to_chat(T, "<span class='danger'>An odd sensation flows through your body as [C] begins to drain you!</span>")
				C.nutrition = (C.nutrition + (T.nutrition*0.05)) //Drain a small bit at first. 5% of the prey's nutrition.
				T.nutrition = T.nutrition*0.95
			if(2)
				to_chat(C, "<span class='notice'>You feel stronger with every passing moment of draining [T].</span>")
				src.visible_message("<span class='danger'>[C] seems to be doing something to [T], resulting in [T]'s body looking weaker with every passing moment!</span>")
				to_chat(T, "<span class='danger'>You feel weaker with every passing moment as [C] drains you!</span>")
				C.nutrition = (C.nutrition + (T.nutrition*0.1))
				T.nutrition = T.nutrition*0.9
			if(3 to 99)
				C.nutrition = (C.nutrition + (T.nutrition*0.1)) //Just keep draining them.
				T.nutrition = T.nutrition*0.9
				T.eye_blurry += 5 //Some eye blurry just to signify to the prey that they are still being drained. This'll stack up over time, leave the prey a bit more "weakened" after the deed is done.
				if(T.nutrition < 100 && stage < 99 && C.drain_finalized == 1)//Did they drop below 100 nutrition? If so, immediately jump to stage 99 so it can advance to 100.
					stage = 99
				if(C.drain_finalized != 1 && stage == 99) //Are they not finalizing and the stage hit 100? If so, go back to stage 3 until they finalize it.
					stage = 3
			if(100)
				C.nutrition = (C.nutrition + T.nutrition)
				T.nutrition = 0 //Completely drained of everything.
				var/damage_to_be_applied = T.species.total_health //Get their max health.
				T.apply_damage(damage_to_be_applied, HALLOSS) //Knock em out.
				C.absorbing_prey = 0
				to_chat(C, "<span class='notice'>You have completely drained [T], causing them to pass out.</span>")
				to_chat(T, "<span class='danger'>You feel weak, as if you have no control over your body whatsoever as [C] finishes draining you.!</span>")
				add_attack_logs(C,T,"Succubus drained")
				return

		if(!do_mob(src, T, 50) || G.state != GRAB_NECK) //One drain tick every 5 seconds.
			to_chat(src, "<span class='warning'>Your draining of [T] has been interrupted!</span>")
			C.absorbing_prey = 0
			return

/mob/living/carbon/human/proc/succubus_drain_lethal()
	set name = "Lethally drain prey" //Provide a warning that THIS WILL KILL YOUR PREY.
	set desc = "Slowly drain prey of all the nutrition in their body, feeding you in the process. Once prey run out of nutrition, you will begin to drain them lethally. You may only do this to one person at a time."
	set category = "Abilities"
	if(!ishuman(src))
		return //If you're not a human you don't have permission to do this.

	var/obj/item/weapon/grab/G = src.get_active_hand()
	if(!istype(G))
		to_chat(src, "<span class='warning'>You must be grabbing a creature in your active hand to drain them.</span>")
		return

	var/mob/living/carbon/human/T = G.affecting // I must say, this is a quite ingenious way of doing it. Props to the original coders.
	if(!istype(T) || T.isSynthetic())
		to_chat(src, "<span class='warning'>\The [T] is not able to be drained.</span>")
		return

	if(G.state != GRAB_NECK)
		to_chat(src, "<span class='warning'>You must have a tighter grip to drain this creature.</span>")
		return

	if(absorbing_prey)
		to_chat(src, "<span class='warning'>You are already draining someone!</span>")
		return

	absorbing_prey = 1
	for(var/stage = 1, stage<=100, stage++) //100 stages.
		switch(stage)
			if(1)
				if(T.stat == DEAD)
					to_chat(src, "<span class='warning'>[T] is dead and can not be drained..</span>")
					return
				to_chat(src, "<span class='notice'>You begin to drain [T]...</span>")
				to_chat(T, "<span class='danger'>An odd sensation flows through your body as [src] begins to drain you!</span>")
				nutrition = (nutrition + (T.nutrition*0.05)) //Drain a small bit at first. 5% of the prey's nutrition.
				T.nutrition = T.nutrition*0.95
			if(2)
				to_chat(src, "<span class='notice'>You feel stronger with every passing moment as you drain [T].</span>")
				visible_message("<span class='danger'>[src] seems to be doing something to [T], resulting in [T]'s body looking weaker with every passing moment!</span>")
				to_chat(T, "<span class='danger'>You feel weaker with every passing moment as [src] drains you!</span>")
				nutrition = (nutrition + (T.nutrition*0.1))
				T.nutrition = T.nutrition*0.9
			if(3 to 48) //Should be more than enough to get under 100.
				nutrition = (nutrition + (T.nutrition*0.1)) //Just keep draining them.
				T.nutrition = T.nutrition*0.9
				T.eye_blurry += 5 //Some eye blurry just to signify to the prey that they are still being drained. This'll stack up over time, leave the prey a bit more "weakened" after the deed is done.
				if(T.nutrition < 100)//Did they drop below 100 nutrition? If so, do one last check then jump to stage 50 (Lethal!)
					stage = 49
			if(49)
				if(T.nutrition < 100)//Did they somehow not get drained below 100 nutrition yet? If not, go back to stage 3 and repeat until they get drained.
					stage = 3 //Otherwise, advance to stage 50 (Lethal draining.)
			if(50)
				if(!T.digestable)
					to_chat(src, "<span class='danger'>You feel invigorated as you completely drain [T] and begin to move onto draining them lethally before realizing they are too strong for you to do so!</span>")
					to_chat(T, "<span class='danger'>You feel completely drained as [src] finishes draining you and begins to move onto draining you lethally, but you are too strong for them to do so!</span>")
					nutrition = (nutrition + T.nutrition)
					T.nutrition = 0 //Completely drained of everything.
					var/damage_to_be_applied = T.species.total_health //Get their max health.
					T.apply_damage(damage_to_be_applied, HALLOSS) //Knock em out.
					absorbing_prey = 0 //Clean this up before we return
					return
				to_chat(src, "<span class='notice'>You begin to drain [T] completely...</span>")
				to_chat(T, "<span class='danger'>An odd sensation flows through your body as you as [src] begins to drain you to dangerous levels!</span>")
			if(51 to 98)
				if(T.stat == DEAD)
					T.apply_damage(500, OXY) //Bit of fluff.
					absorbing_prey = 0
					to_chat(src, "<span class='notice'>You have completely drained [T], killing them.</span>")
					to_chat(T, "<span class='danger'size='5'>You feel... So... Weak...</span>")
					add_attack_logs(src,T,"Succubus drained (almost lethal)")
					return
				if(drain_finalized == 1 || T.getBrainLoss() < 55) //Let's not kill them with this unless the drain is finalized. This will still stack up to 55, since 60 is lethal.
					T.adjustBrainLoss(5) //Will kill them after a short bit!
				T.eye_blurry += 20 //A lot of eye blurry just to signify to the prey that they are still being drained. This'll stack up over time, leave the prey a bit more "weakened" after the deed is done. More than non-lethal due to their lifeforce being sucked out
				nutrition = (nutrition + 25) //Assuming brain damage kills at 60, this gives 300 nutrition.
			if(99)
				if(drain_finalized != 1)
					stage = 51
			if(100) //They shouldn't  survive long enough to get here, but just in case.
				T.apply_damage(500, OXY) //Kill them.
				absorbing_prey = 0
				to_chat(src, "<span class='notice'>You have completely drained [T], killing them in the process.</span>")
				to_chat(T, "<span class='danger'><font size='7'>You... Feel... So... Weak...</font></span>")
				visible_message("<span class='danger'>[src] seems to finish whatever they were doing to [T].</span>")
				add_attack_logs(src,T,"Succubus drained (lethal)")
				return

		if(!do_mob(src, T, 50) || G.state != GRAB_NECK) //One drain tick every 5 seconds.
			to_chat(src, "<span class='warning'>Your draining of [T] has been interrupted!</span>")
			absorbing_prey = 0
			return

/mob/living/carbon/human/proc/slime_feed()
	set name = "Feed prey with self"
	set desc = "Slowly feed prey with your body, draining you in the process. You may only do this to one person at a time."
	set category = "Abilities"
	if(!ishuman(src))
		return //If you're not a human you don't have permission to do this.
	var/mob/living/carbon/human/C = src
	var/obj/item/weapon/grab/G = src.get_active_hand()
	if(!istype(G))
		to_chat(C, "<span class='warning'>You must be grabbing a creature in your active hand to feed them.</span>")
		return

	var/mob/living/carbon/human/T = G.affecting // I must say, this is a quite ingenious way of doing it. Props to the original coders.
	if(!istype(T) || T.isSynthetic())
		to_chat(src, "<span class='warning'>\The [T] is not able to be fed.</span>")
		return

	if(!G.state) //This should never occur. But alright
		return

	if(C.absorbing_prey)
		to_chat(C, "<span class='warning'>You are already feeding someone!</span>")
		return

	C.absorbing_prey = 1
	for(var/stage = 1, stage<=100, stage++) //100 stages.
		switch(stage)
			if(1)
				to_chat(C, "<span class='notice'>You begin to feed [T]...</span>")
				to_chat(T, "<span class='notice'>An odd sensation flows through your body as [C] begins to feed you!</span>")
				T.nutrition = (T.nutrition + (C.nutrition*0.05)) //Drain a small bit at first. 5% of the prey's nutrition.
				C.nutrition = C.nutrition*0.95
			if(2)
				to_chat(C, "<span class='notice'>You feel weaker with every passing moment of feeding [T].</span>")
				src.visible_message("<span class='notice'>[C] seems to be doing something to [T], resulting in [T]'s body looking stronger with every passing moment!</span>")
				to_chat(T, "<span class='notice'>You feel stronger with every passing moment as [C] feeds you!</span>")
				T.nutrition = (T.nutrition + (C.nutrition*0.1))
				C.nutrition = C.nutrition*0.90
			if(3 to 99)
				T.nutrition = (T.nutrition + (C.nutrition*0.1)) //Just keep draining them.
				C.nutrition = C.nutrition*0.9
				T.eye_blurry += 1 //Eating a slime's body is odd and will make your vision a bit blurry!
				if(C.nutrition < 100 && stage < 99 && C.drain_finalized == 1)//Did they drop below 100 nutrition? If so, immediately jump to stage 99 so it can advance to 100.
					stage = 99
				if(C.drain_finalized != 1 && stage == 99) //Are they not finalizing and the stage hit 100? If so, go back to stage 3 until they finalize it.
					stage = 3
			if(100)
				T.nutrition = (T.nutrition + C.nutrition)
				C.nutrition = 0 //Completely drained of everything.
				C.absorbing_prey = 0
				to_chat(C, "<span class='danger'>You have completely fed [T] every part of your body!</span>")
				to_chat(T, "<span class='notice'>You feel quite strong and well fed, as [C] finishes feeding \himself to you!</span>")
				add_attack_logs(C,T,"Slime fed")
				C.feed_grabbed_to_self_falling_nom(T,C) //Reused this proc instead of making a new one to cut down on code usage.
				return

		if(!do_mob(src, T, 50) || !G.state) //One drain tick every 5 seconds.
			to_chat(src, "<span class='warning'>Your feeding of [T] has been interrupted!</span>")
			C.absorbing_prey = 0
			return

/mob/living/carbon/human/proc/succubus_drain_finalize()
	set name = "Drain/Feed Finalization"
	set desc = "Toggle to allow for draining to be prolonged. Turn this on to make it so prey will be knocked out/die while being drained, or you will feed yourself to the prey's selected stomach if you're feeding them. Can be toggled at any time."
	set category = "Abilities"

	var/mob/living/carbon/human/C = src
	C.drain_finalized = !C.drain_finalized
	to_chat(C, "<span class='notice'>You will [C.drain_finalized?"now":"not"] finalize draining/feeding.</span>")


//Test to see if we can shred a mob. Some child override needs to pass us a target. We'll return it if you can.
/mob/living/var/vore_shred_time = 45 SECONDS
/mob/living/proc/can_shred(var/mob/living/carbon/human/target)
	//Needs to have organs to be able to shred them.
	if(!istype(target))
		to_chat(src,"<span class='warning'>You can't shred that type of creature.</span>")
		return FALSE
	//Needs to be capable (replace with incapacitated call?)
	if(stat || paralysis || stunned || weakened || lying || restrained() || buckled)
		to_chat(src,"<span class='warning'>You cannot do that in your current state!</span>")
		return FALSE
	//Needs to be adjacent, at the very least.
	if(!Adjacent(target))
		to_chat(src,"<span class='warning'>You must be next to your target.</span>")
		return FALSE
	//Cooldown on abilities
	if(last_special > world.time)
		to_chat(src,"<span class='warning'>You can't perform an ability again so soon!</span>")
		return FALSE

	return target

//Human test for shreddability, returns the mob if they can be shredded.
/mob/living/carbon/human/vore_shred_time = 10 SECONDS
/mob/living/carbon/human/can_shred()
	//Humans need a grab
	var/obj/item/weapon/grab/G = get_active_hand()
	if(!istype(G))
		to_chat(src,"<span class='warning'>You have to have a very strong grip on someone first!</span>")
		return FALSE
	if(G.state != GRAB_NECK)
		to_chat(src,"<span class='warning'>You must have a tighter grip to severely damage this creature!</span>")
		return FALSE

	return ..(G.affecting)

//PAIs don't need a grab or anything
/mob/living/silicon/pai/can_shred(var/mob/living/carbon/human/target)
	if(!target)
		var/list/choices = list()
		for(var/mob/living/carbon/human/M in oviewers(1))
			choices += M
		
		if(!choices.len)
			to_chat(src,"<span class='warning'>There's nobody nearby to use this on.</span>")

		target = input(src,"Who do you wish to target?","Damage/Remove Prey's Organ") as null|anything in choices
	if(!istype(target))
		return FALSE

	return ..(target)

/mob/living/proc/shred_limb()
	set name = "Damage/Remove Prey's Organ"
	set desc = "Severely damages prey's organ. If the limb is already severely damaged, it will be torn off."
	set category = "Abilities"

	//can_shred() will return a mob we can shred, if we can shred any.
	var/mob/living/carbon/human/T = can_shred()
	if(!istype(T))
		return //Silent, because can_shred does messages.

	//Let them pick any of the target's external organs
	var/obj/item/organ/external/T_ext = input(src,"What do you wish to severely damage?") as null|anything in T.organs //D for destroy.
	if(!T_ext) //Picking something here is critical.
		return
	if(T_ext.vital)
		if(alert("Are you sure you wish to severely damage their [T_ext]? It will likely kill [T]...",,"Yes", "No") != "Yes")
			return //If they reconsider, don't continue.

	//Any internal organ, if there are any
	var/obj/item/organ/internal/T_int = input(src,"Do you wish to severely damage an internal organ, as well? If not, click 'cancel'") as null|anything in T_ext.internal_organs
	if(T_int && T_int.vital)
		if(alert("Are you sure you wish to severely damage their [T_int]? It will likely kill [T]...",,"Yes", "No") != "Yes")
			return //If they reconsider, don't continue.

	//And a belly, if they want
	var/obj/belly/B = input(src,"Do you wish to swallow the organ if you tear if out? If not, click 'cancel'") as null|anything in vore_organs

	if(can_shred(T) != T)
		to_chat(src,"<span class='warning'>Looks like you lost your chance...</span>")
		return

	last_special = world.time + vore_shred_time
	visible_message("<span class='danger'>[src] appears to be preparing to do something to [T]!</span>") //Let everyone know that bad times are ahead

	if(do_after(src, vore_shred_time, T)) //Ten seconds. You have to be in a neckgrab for this, so you're already in a bad position.
		if(can_shred(T) != T)
			to_chat(src,"<span class='warning'>Looks like you lost your chance...</span>")
			return
		
		//Removing an internal organ
		if(T_int && T_int.damage >= 25) //Internal organ and it's been severely damaged
			T.apply_damage(15, BRUTE, T_ext) //Damage the external organ they're going through.
			T_int.removed()
			if(B)
				T_int.forceMove(B) //Move to pred's gut
				visible_message("<span class='danger'>[src] severely damages [T_int.name] of [T]!</span>")
			else
				T_int.forceMove(T.loc)
				visible_message("<span class='danger'>[src] severely damages [T_ext.name] of [T], resulting in their [T_int.name] coming out!</span>","<span class='warning'>You tear out [T]'s [T_int.name]!</span>")

		//Removing an external organ
		else if(!T_int && (T_ext.damage >= 25 || T_ext.brute_dam >= 25))
			T_ext.droplimb(1,DROPLIMB_EDGE) //Clean cut so it doesn't kill the prey completely.
			
			//Is it groin/chest? You can't remove those.
			if(T_ext.cannot_amputate)
				T.apply_damage(25, BRUTE, T_ext)
				visible_message("<span class='danger'>[src] severely damages [T]'s [T_ext.name]!</span>")
			else if(B)
				T_ext.forceMove(B)
				visible_message("<span class='warning'>[src] swallows [T]'s [T_ext.name] into their [lowertext(B.name)]!</span>")
			else
				T_ext.forceMove(T.loc)
				visible_message("<span class='warning'>[src] tears off [T]'s [T_ext.name]!</span>","<span class='warning'>You tear off [T]'s [T_ext.name]!</span>")

		//Not targeting an internal organ w/ > 25 damage , and the limb doesn't have < 25 damage.
		else 
			if(T_int)
				T_int.damage = 25 //Internal organs can only take damage, not brute damage.
			T.apply_damage(25, BRUTE, T_ext)
			visible_message("<span class='danger'>[src] severely damages [T]'s [T_ext.name]!</span>")
		
		add_attack_logs(src,T,"Shredded (hardvore)")

/mob/living/proc/flying_toggle()
	set name = "Toggle Flight"
	set desc = "While flying over open spaces, you will use up some nutrition. If you run out nutrition, you will fall. Additionally, you can't fly if you are too heavy."
	set category = "Abilities"

	var/mob/living/carbon/human/C = src
	if(!C.wing_style) //The species var isn't taken into account here, as it's only purpose is to give this proc to a person.
		to_chat(src, "You cannot fly without wings!!")
		return
	if(C.incapacitated(INCAPACITATION_ALL))
		to_chat(src, "You cannot fly in this state!")
		return
	if(C.nutrition < 25 && !C.flying) //Don't have any food in you?" You can't fly.
		to_chat(C, "<span class='notice'>You lack the nutrition to fly.</span>")
		return
	if(C.nutrition > 1000 && !C.flying)
		to_chat(C, "<span class='notice'>You have eaten too much to fly! You need to lose some nutrition.</span>")
		return

	C.flying = !C.flying
	update_floating()
	to_chat(C, "<span class='notice'>You have [C.flying?"started":"stopped"] flying.</span>")

//Proc to stop inertial_drift. Exchange nutrition in order to stop gliding around.
/mob/living/proc/start_wings_hovering()
	set name = "Hover"
	set desc = "Allows you to stop gliding and hover. This will take a fair amount of nutrition to perform."
	set category = "Abilities"

	var/mob/living/carbon/human/C = src
	if(!C.wing_style) //The species var isn't taken into account here, as it's only purpose is to give this proc to a person.
		to_chat(src, "You don't have wings!")
		return
	if(!C.flying)
		to_chat(src, "You must be flying to hover!")
		return
	if(C.incapacitated(INCAPACITATION_ALL))
		to_chat(src, "You cannot hover in your current state!")
		return
	if(C.nutrition < 50 && !C.flying) //Don't have any food in you?" You can't hover, since it takes up 25 nutrition. And it's not 25 since we don't want them to immediately fall.
		to_chat(C, "<span class='notice'>You lack the nutrition to fly.</span>")
		return
	if(C.anchored)
		to_chat(C, "<span class='notice'>You are already hovering and/or anchored in place!</span>")
		return

	if(!C.anchored && !C.pulledby) //Not currently anchored, and not pulled by anyone.
		C.anchored = 1 //This is the only way to stop the inertial_drift.
		C.nutrition -= 25
		update_floating()
		to_chat(C, "<span class='notice'>You hover in place.</span>")
		spawn(6) //.6 seconds.
			C.anchored = 0
	else
		return

/mob/living/proc/toggle_pass_table()
	set name = "Toggle Agility" //Dunno a better name for this. You have to be pretty agile to hop over stuff!!!
	set desc = "Allows you to start/stop hopping over things such as hydroponics trays, tables, and railings."
	set category = "Abilities"
	pass_flags ^= PASSTABLE //I dunno what this fancy ^= is but Aronai gave it to me.
	to_chat(src, "You [pass_flags&PASSTABLE ? "will" : "will NOT"] move over tables/railings/trays!")

/mob/living/carbon/human/proc/succubus_bite()
	set name = "Inject Prey"
	set desc = "Bite prey and inject them with various toxins."
	set category = "Abilities"

	if(last_special > world.time)
		return

	if(!ishuman(src))
		return //If you're not a human you don't have permission to do this.

	var/mob/living/carbon/human/C = src

	var/obj/item/weapon/grab/G = src.get_active_hand()

	if(!istype(G))
		to_chat(C, "<span class='warning'>You must be grabbing a creature in your active hand to bite them.</span>")
		return

	var/mob/living/carbon/human/T = G.affecting

	if(!istype(T) || T.isSynthetic())
		to_chat(src, "<span class='warning'>\The [T] is not able to be bitten.</span>")
		return

	if(G.state != GRAB_NECK)
		to_chat(C, "<span class='warning'>You must have a tighter grip to bite this creature.</span>")
		return

	var/choice = input(src, "What do you wish to inject?") as null|anything in list("Aphrodisiac", "Numbing", "Paralyzing")

	last_special = world.time + 600

	if(!choice)
		return

	src.visible_message("<font color='red'><b>[src] moves their head next to [T]'s neck, seemingly looking for something!</b></font>")

	if(do_after(src, 300, T)) //Thrirty seconds.
		if(choice == "Aphrodisiac")
			src.show_message("<span class='warning'>You sink your fangs into [T] and inject your aphrodisiac!</span>")
			src.visible_message("<font color='red'>[src] sinks their fangs into [T]!</font>")
			T.bloodstr.add_reagent("succubi_aphrodisiac",200)
			return 0
		else if(choice == "Numbing")
			src.show_message("<span class='warning'>You sink your fangs into [T] and inject your poison!</span>")
			src.visible_message("<font color='red'>[src] sinks their fangs into [T]!</font>")
			T.bloodstr.add_reagent("numbing_enzyme",50) //Poisons should work when more units are injected
		else if(choice == "Paralyzing")
			src.show_message("<span class='warning'>You sink your fangs into [T] and inject your poison!</span>")
			src.visible_message("<font color='red'>[src] sinks their fangs into [T]!</font>")
			T.bloodstr.add_reagent("succubi_paralize",50) //Poisons should work when more units are injected
		else
			return //Should never happen

/*
mob/living/carbon/proc/charmed() //TODO
	charmed = 1

	spawn(0)
		for(var/i = 1,i > 0, i--)
			src << "<font color='blue'><i>... [pick(charmed)] ...</i></font>"
		charmed = 0

*/

/datum/reagent/succubi_aphrodisiac
	name = "Aphrodisiac"
	id = "succubi_aphrodisiac"
	description = "A unknown liquid, it smells sweet"
	color = "#8A0829"
	scannable = 0

/datum/reagent/succubi_aphrodisiac/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(prob(7))
		M.show_message("<span class='warning'>You feel funny, and fall in love with the person in front of you</span>")
		M.emote(pick("blush", "moans", "giggles", "turns visibly red"))
		//M.charmed() //TODO
		return

/datum/reagent/succubi_numbing //Using numbing_enzyme instead.
	name = "Numbing Fluid"
	id = "succubi_numbing"
	description = "A unknown liquid, it doesn't smell"
	color = "#41029B"
	scannable = 0

/datum/reagent/succubi_numbing/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(prob(7))
		M.show_message("<span class='warning'>You start to feel weakened, your body seems heavy.</span>")
		M.eye_blurry = max(M.eye_blurry, 10)
		return

/datum/reagent/succubi_paralize
	name = "Paralyzing Fluid"
	id = "succubi_numbing"
	description = "A unknown liquid, it doesn't smell"
	color = "#41029B"
	scannable = 0

/datum/reagent/succubi_paralize/affect_blood(var/mob/living/carbon/M, var/alien, var/removed)
	if(prob(7))
		M.show_message("<span class='warning'>You lose sensation of your body.</span>")
		M.Weaken(20)
		return

/mob/living/carbon/human/proc/face_sit()
    set name = "Face Sit"
    set desc = "Sit on your Prey's Face"
    set category = "Abilities"

    if(last_special > world.time)
        return

    if(!ishuman(src))
        return //If you're not a human you don't have permission to do this.

    var/mob/living/carbon/human/C = src

    var/obj/item/weapon/grab/G = src.get_active_hand()

    if(!istype(G))
        to_chat(C, "<span class='warning'>You must be grabbing a creature in your active hand to sit on them.</span>")
        return

    var/mob/living/carbon/human/T = G.affecting

    if(!istype(T) || T.isSynthetic())
        to_chat(src, "<span class='warning'>\The [T] is not able to be sit on.</span>")
        return

    if(G.state != GRAB_AGGRESSIVE)
        to_chat(C, "<span class='warning'>You must have the creature pinned on the ground to sit on them </span>")
        return

    src.visible_message("<font color='red'><b>[src] moves their ass to [T]'s head, sitting down on them, making them unable to see anything else than [src]'s butt </b></font>")
    return
