-- Garden Scene Script - Crystal Mystery
-- The Moonlit Garden: Where ancient secrets lie hidden beneath the fog
-- This is where the mystery is solved

-- Scene enter handler
function on_enter()
    print("Entering garden...")
    set_game_state("visited_garden", true)

    -- Play garden theme music
    play_music("garden_theme", 0.5)

    -- Play ambient sounds - night crickets, distant owl, water trickling
    play_ambient("garden_night", 0.35)

    -- First visit introduction
    if not get_game_state("garden_intro_shown") then
        set_game_state("garden_intro_shown", true)

        show_message("You step into the moonlit garden, where tendrils of fog curl between overgrown hedges.")
        show_message("The scent of night-blooming jasmine hangs heavy in the air.")

        -- Check for moonflower blooming (crystal is nearby)
        if get_game_state("moonflowers_blooming") or not get_game_state("crystal_found") then
            show_message("Pale moonflowers glow softly in their beds - they only bloom in the crystal's presence.")
            show_message("The Crystal of Luminus is here. Somewhere in this garden.")
            set_game_state("moonflowers_blooming", true)
        end

        -- Time-sensitive message
        if get_game_state("time_clue_found") then
            show_message("11:47 draws near. Whatever happens tonight, it happens here.")
        end
    else
        -- Return visit messages
        if has_item("crystal") and has_item("crystal_lens") then
            show_message("The fountain calls to you. The statue awaits. All the pieces are in place.")
        elseif get_game_state("statue_examined") and not has_item("crystal") then
            show_message("The statue's secret has been revealed. The crystal pulses with renewed energy in your possession.")
        end
    end
end

-- Fountain - the key to activation
function examine_fountain()
    show_message("A beautiful marble fountain carved with symbols matching those on the mysterious note.")
    show_message("Clear water bubbles from a lotus-shaped spout, moonlight dancing on its surface.")

    -- Set flag for quest objective
    set_game_state("at_fountain", true)

    if has_item("crystal") and has_item("crystal_lens") and get_game_state("activation_method_learned") then
        -- Full activation sequence
        show_message("You hold the crystal over the fountain, positioning the lens to focus moonlight through it...")
        show_message("The water begins to glow with an ethereal light!")
        show_message("The crystal resonates with the fountain's harmonic frequency - just as the grandfather described!")

        play_sound("success")
        set_game_state("fountain_activated", true)
        complete_quest_objective("final_revelation", "restore_crystal")

        -- Check for game completion
        check_victory()

    elseif has_item("crystal") and has_item("crystal_lens") then
        show_message("The crystal and lens respond to the fountain, but something is missing.")
        show_message("You need to understand the proper method of activation first.")

    elseif has_item("crystal") then
        show_message("The crystal pulses warmly as you hold it near the water.")
        show_message("It reacts to the fountain, but you need something to focus its energy.")

    elseif has_item("crystal_lens") then
        show_message("The lens catches moonlight and refracts it beautifully.")
        show_message("Without the crystal, though, there's nothing to focus the energy into.")

    else
        show_message("The fountain seems to be waiting for something special...")
        show_message("'Where light meets water, truth shall emerge.' The inscription on the bench...")

        if get_game_state("ritual_decoded") then
            show_message("The ritual requires the crystal to be placed here, at the proper alignment.")
        end
    end
end

-- Statue - hides the crystal
function examine_statue()
    show_message("A life-sized statue of a robed figure, arms outstretched to the heavens.")
    show_message("Its weathered features are smooth, but the hands remain detailed - cupped as if holding something precious.")

    if not get_game_state("statue_examined") then
        show_message("You examine the statue more closely...")

        -- Crystal discovery
        if not has_item("crystal") then
            show_message("There! Between the cupped fingers - a faint glow!")
            show_message("Hidden in the guardian's hands is the missing Crystal of Luminus!")
            show_message("It pulses with inner light, warm to the touch. The legendary crystal is yours.")

            add_to_inventory("crystal")
            play_sound("pickup")
            set_game_state("statue_examined", true)
            set_game_state("crystal_found", true)
            complete_quest_objective("find_crystal", "locate_crystal")

            -- Update quest
            show_message("But who placed it here? And why? The mystery deepens.")
        end

    elseif has_item("crystal_lens") and not get_game_state("activation_method_learned") then
        show_message("Using the crystal lens, you can see hidden markings etched into the statue's robes!")
        show_message("They depict a ritual: the crystal held over the fountain, light focused through a lens...")
        show_message("At the moment of alignment - 11:47 - the veil between worlds grows thin.")
        set_game_state("activation_method_learned", true)
        play_sound("success")

    elseif has_item("crystal") and not get_game_state("crystal_replaced") then
        show_message("The statue's hands are empty now. The crystal's rightful place, perhaps.")
        show_message("But first, the fountain must be activated. The ritual must be completed.")

    else
        show_message("The guardian statue watches over the garden, its purpose fulfilled.")
    end
end

-- Flowerbed with moonflowers
function examine_flowerbed()
    show_message("A carefully tended bed of rare moonflowers, their pale petals glowing softly.")

    if has_item("crystal") then
        show_message("The flowers lean toward you - toward the crystal - as if drawn by its energy.")
        show_message("The legends are true. These flowers track crystalline energy like a compass.")
    else
        show_message("According to legend, these flowers only bloom in the presence of crystalline energy.")
        show_message("Tonight, they bloom brilliantly. The crystal must be close...")
    end

    if not get_game_state("flowerbed_examined") then
        show_message("Among the flowers, you notice footprints in the soft earth.")
        show_message("Someone stood here recently, looking toward the statue. Watching. Waiting.")
        set_game_state("flowerbed_examined", true)
    end
end

-- Garden shed - requires garden key
function examine_garden_shed()
    show_message("A weathered wooden shed, its door secured with a rusty padlock.")
    show_message("Through a grimy window, you can make out gardening tools and... is that a lantern burning inside?")

    if has_item("garden_key") then
        show_message("The flower-shaped key fits the padlock perfectly!")
        play_sound("success")
        set_game_state("shed_unlocked", true)

        show_message("Inside you find evidence of recent occupation - a bedroll, food wrappers, notebooks.")
        show_message("Someone has been living here, watching the mansion. Waiting.")

        if not get_game_state("shed_searched") then
            show_message("Among the notes, you find detailed observations of the professor's schedule...")
            show_message("And a letter signed 'Your loving father' - addressed to Edmund Ashworth!")
            show_message("The letter speaks of protecting Edmund from the crystal's curse - he took it to save his son!")
            set_game_state("shed_searched", true)
            set_game_state("father_evidence_found", true)
            set_game_state("father_motive_understood", true)

            if get_game_state("father_theory_formed") then
                show_message("The father theory is confirmed! He's been watching, waiting for the right moment.")
            end
        end

    elseif has_item("brass_key") then
        show_message("The brass key doesn't fit this lock. You need something with a flower design.")
    else
        show_message("The padlock is rusted but sturdy. The keyhole has a distinctive flower shape.")
    end
end

-- Stone bench with inscription
function examine_bench()
    show_message("A moss-covered stone bench beneath an ancient oak tree.")

    if not get_game_state("bench_examined") then
        show_message("Carved into the seat: 'Where light meets water, truth shall emerge.'")
        show_message("Below, scratched more recently: '1847 - 11:47' The year the mansion was built...")
        set_game_state("bench_examined", true)
        set_game_state("inscription_found", true)

        if get_game_state("time_clue_found") then
            show_message("The same time as the stopped clock! This is no coincidence.")
        end
    else
        show_message("You sit for a moment, contemplating the inscription.")
        show_message("Light meets water... the crystal and the fountain. It all connects.")
    end
end

-- Lamp post - get the lamp
function examine_lamp_post()
    show_message("A tall iron lamp post, its gas flame sputtering weakly in the fog.")

    if not get_game_state("lamp_taken") then
        show_message("An oil lamp hangs from a hook at shoulder height. Still has fuel.")
        show_message("Its light might reveal what shadows hide...")

        if not has_item("lamp") then
            show_message("You take the lamp. Its flame burns with unusual steadiness.")
            add_to_inventory("lamp")
            play_sound("pickup")
            set_game_state("lamp_taken", true)
        end
    else
        show_message("The lamp post stands empty, its main light sputtering in the fog.")
    end
end

-- Hedge maze entrance - atmosphere
function examine_hedge_maze()
    show_message("The dark entrance to an elaborate hedge maze. Fog swirls beyond the archway.")
    show_message("You can hear something rustling in the hedges - probably just the wind.")

    if has_item("lamp") then
        show_message("Even with the lamp, the maze looks treacherous. Perhaps another time.")
    else
        show_message("Without better light, entering would be foolish.")
    end
end

-- Sundial with time clue
function examine_sundial()
    show_message("A brass sundial on a marble pedestal, inscribed with astronomical symbols.")

    if not get_game_state("sundial_examined") then
        show_message("One marking - the position for 11:47 - is worn smooth from repeated touching.")
        show_message("The grandfather must have stood here countless nights, tracing that mark...")
        set_game_state("sundial_examined", true)
        set_game_state("sundial_clue_found", true)
    end

    if has_item("mysterious_note") then
        show_message("The symbols on the sundial match those on your note!")
        show_message("It's a star chart - showing the alignment at 11:47 on specific dates.")
    end
end

-- Rose bush - atmospheric
function examine_rose_bush()
    show_message("A massive rose bush, easily a hundred years old, with fierce thorns.")
    show_message("Among the blood-red blooms, some petals shimmer with a crystalline quality.")

    if has_item("crystal") then
        show_message("The crystal-touched roses seem to pulse in response to your presence.")
        show_message("Generations of proximity to the crystal have changed them.")
    end

    if not get_game_state("roses_examined") then
        show_message("The scent is rich and heady, with an undertone of something metallic.")
        show_message("Caught on a thorn - a small scrap of dark fabric.")
        set_game_state("roses_examined", true)
        set_game_state("rose_fabric_found", true)
    end
end

-- Well - mysterious
function examine_well()
    show_message("An old stone well covered with lichen. A wooden cover lies askew - recently moved.")

    if not get_game_state("well_examined") then
        show_message("Peering through the gap, you see something glinting deep below...")
        show_message("But the cover is too heavy to move alone. The well's secrets must wait.")
        set_game_state("well_examined", true)
    end

    if has_item("lamp") then
        show_message("The lamp's light reaches down into the darkness, revealing old coins and broken glass.")
        show_message("Nothing useful, but someone has been throwing things down here. Disposing of evidence?")
    end
end

-- Bird bath - atmospheric
function examine_bird_bath()
    show_message("A cracked stone bird bath, water black as obsidian under the moon.")

    if not get_game_state("birdbath_examined") then
        show_message("Small ripples disturb the surface, though there's no wind.")
        show_message("Your reflection seems to shimmer strangely, almost as if it moves independently.")
        set_game_state("birdbath_examined", true)

        if has_item("crystal") then
            show_message("The crystal responds to the water, growing warm. Crystalline energy affects everything here.")
        end
    else
        show_message("The water remains still and dark. Some mysteries aren't meant to be solved.")
    end
end

-- Greenhouse - requires garden key
function examine_greenhouse()
    show_message("A Victorian greenhouse, glass panels cracked and clouded with age.")
    show_message("Through the dirty panes, exotic plants have run wild. A faint blue light pulses inside.")

    if has_item("garden_key") then
        if not get_game_state("greenhouse_entered") then
            show_message("The garden key opens this lock too!")
            play_sound("success")
            set_game_state("greenhouse_entered", true)

            show_message("Inside, the blue light emanates from crystalline flowers - grown from the crystal's influence!")
            show_message("Someone has been cultivating them, studying how the crystal affects living things.")

            -- Find evidence of research
            if not get_game_state("greenhouse_research_found") then
                show_message("Among the plants, you find notes about the crystal's effect on living things...")
                show_message("The handwriting matches the scientist's. He's been conducting secret experiments here.")
                set_game_state("greenhouse_research_found", true)
                set_game_state("scientist_secret_experiments", true)
            end
        else
            show_message("The greenhouse's crystalline garden continues to pulse with unearthly light.")
        end
    else
        show_message("The door is secured with the same type of padlock as the shed. Flower-shaped keyhole.")
    end
end

-- Door to laboratory
function on_door_to_lab_click()
    play_sound("door_open")

    if get_game_state("fountain_activated") then
        show_message("You return to the laboratory, the activated fountain's glow visible through the garden.")
    else
        show_message("You return to the laboratory. The garden's mysteries call you back...")
    end

    change_scene("laboratory")
end

-- Scene exit
function on_exit()
    stop_ambient("garden_night")
end

-- Victory condition check
function check_victory()
    if get_game_state("fountain_activated") and
       get_game_state("activation_method_learned") and
       has_item("crystal") and has_item("crystal_lens") then

        show_message("The Crystal of Luminus blazes with restored power!")
        show_message("The fountain's water rises in an impossible spiral, light refracting through every droplet...")
        show_message("For a moment, the veil between worlds grows thin. You glimpse... something beyond.")

        play_sound("victory")

        -- Complete final quest
        complete_quest("final_revelation")
        trigger_achievement("master_detective")
        set_game_state("game_complete", true)

        -- Mystery resolution
        show_message("The mystery is solved. The crystal is restored. The Ashworth legacy continues.")
        show_message("But as the light fades, you wonder... what lies beyond that veil?")

        -- Trigger ending
        start_sequence("ending_sequence")
    end
end

-- Item use handler
function use_item_on_hotspot(item, hotspot)
    if item == "crystal" then
        if hotspot == "fountain" then
            examine_fountain()
            return true
        elseif hotspot == "statue" then
            examine_statue()
            return true
        end
    elseif item == "crystal_lens" then
        if hotspot == "fountain" then
            examine_fountain()
            return true
        elseif hotspot == "statue" then
            examine_statue()
            return true
        end
    elseif item == "garden_key" then
        if hotspot == "garden_shed" then
            examine_garden_shed()
            return true
        elseif hotspot == "greenhouse" then
            examine_greenhouse()
            return true
        end
    elseif item == "brass_key" then
        if hotspot == "garden_shed" or hotspot == "greenhouse" then
            show_message("This key doesn't fit. The lock needs a key with a flower design.")
            return true
        end
    elseif item == "lamp" then
        if hotspot == "well" then
            examine_well()
            return true
        elseif hotspot == "hedge_maze_entrance" then
            examine_hedge_maze()
            return true
        end
    elseif item == "mysterious_note" then
        if hotspot == "sundial" then
            examine_sundial()
            return true
        end
    end

    show_message("That doesn't seem to work here.")
    return false
end

-- Update function for atmospheric effects
function on_update(delta)
    -- Periodic atmospheric messages
    if math.random() < 0.001 then
        local messages = {
            "An owl hoots somewhere in the fog.",
            "The moonflowers seem to pulse in rhythm with an unseen heartbeat.",
            "A cold breeze rustles through the hedges.",
            "The fountain's water shimmers with reflected starlight.",
            "For a moment, you thought you saw a figure in the fog..."
        }
        show_message(messages[math.random(#messages)])
    end

    -- Check victory conditions periodically
    if get_game_state("fountain_activated") and not get_game_state("game_complete") then
        check_victory()
    end
end

-- Register hotspot callbacks
hotspot.on_click("fountain", examine_fountain)
hotspot.on_click("statue", examine_statue)
hotspot.on_click("flowerbed", examine_flowerbed)
hotspot.on_click("garden_shed", examine_garden_shed)
hotspot.on_click("bench", examine_bench)
hotspot.on_click("lamp_post", examine_lamp_post)
hotspot.on_click("hedge_maze_entrance", examine_hedge_maze)
hotspot.on_click("sundial", examine_sundial)
hotspot.on_click("rose_bush", examine_rose_bush)
hotspot.on_click("well", examine_well)
hotspot.on_click("bird_bath", examine_bird_bath)
hotspot.on_click("greenhouse", examine_greenhouse)
hotspot.on_click("door_to_lab", on_door_to_lab_click)

-- Register item use handler
scene.on_item_use(use_item_on_hotspot)

-- Scene lifecycle callbacks
scene.on_enter(on_enter)
scene.on_exit(on_exit)
scene.on_update(on_update)
