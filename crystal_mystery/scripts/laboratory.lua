-- Laboratory Scene Script - Crystal Mystery
-- The Scientist's Laboratory: Where brilliant discoveries and dark secrets intertwine
-- This is where the crystal was stolen from

scene.on_enter(function()
    print("Entering laboratory...")

    set_game_state("visited_laboratory", true)

    -- Play laboratory theme music
    play_music("laboratory_theme", 0.5)

    -- Play ambient sounds - equipment hum, bubbling beakers
    play_ambient("laboratory_hum", 0.25)

    -- First visit introduction
    if not get_game_state("laboratory_intro_shown") then
        set_game_state("laboratory_intro_shown", true)

        show_message("The acrid smell of chemicals mingles with ozone as you enter the laboratory.")
        show_message("Banks of equipment hum softly, their displays casting an eerie glow.")

        if not get_game_state("scientist_questioned") then
            show_message("The professor paces nervously by his workbench, muttering to himself.")
            show_message("This is where the Crystal of Luminus was kept - and stolen.")
        end
    else
        -- Return visits based on game state
        if get_game_state("crystal_found") then
            show_message("The laboratory feels different now. Less empty, somehow.")
        elseif get_game_state("cabinet_unlocked") then
            show_message("The open cabinet reminds you of the grandfather's secrets still to uncover.")
        end
    end
end)

-- Workbench - main discovery point
function examine_workbench()
    show_message("A massive oak workbench covered in beakers, Bunsen burners, and scattered papers.")

    if not get_game_state("workbench_examined") then
        show_message("Chemical stains mark the wood. Several experiments sit half-completed.")
        show_message("Among the clutter, you notice a handwritten note with unusual symbols...")

        if not has_item("mysterious_note") then
            show_message("You carefully extract a yellowed piece of parchment!")
            show_message("Strange symbols cover it, along with hurried handwriting. This could be important.")
            add_to_inventory("mysterious_note")
            play_sound("pickup")
            set_game_state("mysterious_note_found", true)
        end

        set_game_state("workbench_examined", true)
        complete_quest_objective("find_crystal", "examine_lab")
    else
        -- Additional examination
        if has_item("research_notes") and not get_game_state("notes_compared") then
            show_message("Comparing your research notes with the workbench materials...")
            show_message("The same handwriting! These notes were written by the professor, not his grandfather.")
            show_message("He's been documenting his own descent into obsession.")
            set_game_state("notes_compared", true)
        else
            show_message("The workbench has revealed its secrets. Just scattered equipment remains.")
        end
    end
end

-- Cabinet - locked container with crystal lens
function examine_cabinet()
    show_message("A tall specimen cabinet with glass doors, secured by an ornate brass lock.")

    if get_game_state("cabinet_unlocked") then
        if not get_game_state("cabinet_contents_taken") then
            show_message("Inside you see various crystal specimens and strange instruments.")
            show_message("One shelf is conspicuously empty - the display stand for the Crystal of Luminus.")

            if not has_item("crystal_lens") then
                show_message("But wait - there's something else here!")
                show_message("A perfectly crafted crystal lens, hidden behind the other specimens!")
                add_to_inventory("crystal_lens")
                play_sound("pickup")
                set_game_state("cabinet_contents_taken", true)
            end
        else
            show_message("The cabinet stands open and empty, its secrets revealed.")
        end
    else
        show_message("Through the glass, you can see crystal specimens and the empty stand where the crystal once sat.")

        if has_item("brass_key") then
            show_message("The serpent design on your key matches the lock exactly!")
            show_message("You turn the key and hear a satisfying click...")
            set_game_state("cabinet_unlocked", true)
            play_sound("success")

            -- Trigger the opening examination
            examine_cabinet()
        else
            show_message("The lock is ornate, featuring a coiled serpent. You'd need a matching key.")
        end
    end
end

-- Microscope - research tool
function examine_microscope()
    show_message("A powerful research microscope with multiple lenses and precise adjustment dials.")
    show_message("A slide is still positioned under the objective lens.")

    if not get_game_state("microscope_examined") then
        show_message("You peer through the eyepiece...")
        show_message("The slide shows crystalline fragments - pieces of something that glows faintly under magnification.")
        set_game_state("microscope_examined", true)
    end

    if has_item("research_notes") and not get_game_state("microscope_analysis_complete") then
        show_message("Using the research notes as a guide, you analyze the fragments more carefully.")
        show_message("These are from the Crystal of Luminus! Tiny pieces left behind from experiments.")
        show_message("The notes describe how these fragments still retain some energy-amplifying properties.")
        set_game_state("microscope_analysis_complete", true)
        play_sound("success")
    elseif has_item("crystal_lens") and not get_game_state("lens_magnified") then
        show_message("Examining the crystal lens under magnification reveals hidden etchings!")
        show_message("Instructions, perhaps - for focusing the crystal's power at specific alignments.")
        set_game_state("lens_magnified", true)
        set_game_state("focusing_instructions_found", true)
    end
end

-- Chemical shelf - atmospheric, hints at danger
function examine_chemical_shelf()
    show_message("Rows of labeled bottles line the shelves - some mundane, others with exotic names.")
    show_message("A warning label reads: 'CAUTION - Crystalline Reactive Compounds'")

    if has_item("crystal") then
        show_message("You feel the crystal grow warm in your inventory.")
        show_message("Some of these chemicals could react dangerously with it. Best to keep distance.")
    end

    if not get_game_state("chemicals_examined") then
        show_message("One section is labeled 'Resonance Catalysts' - bottles of glowing liquids.")
        show_message("These must enhance the crystal's natural properties.")
        set_game_state("chemicals_examined", true)
    end
end

-- Empty display - crime scene
function examine_empty_display()
    show_message("The velvet-lined display stand where the Crystal of Luminus once rested.")
    show_message("A faint indentation shows where it sat. No fingerprints on the glass - the thief was careful.")

    if not get_game_state("display_examined") then
        show_message("Looking closer, you notice faint scuff marks on the floor nearby.")
        show_message("Someone stood here for a long time, perhaps watching, waiting for the right moment.")
        set_game_state("display_examined", true)

        if get_game_state("butler_questioned") then
            show_message("The butler mentioned checking the lab at 11:30. These marks could be from anyone.")
        end
    end

    if has_item("lamp") then
        show_message("The lamp's revealing light shows more: tiny fibers caught on the case's edge.")
        show_message("Dark wool, finely woven. Like a formal suit... or servant's attire.")
        set_game_state("fiber_evidence_found", true)
    end
end

-- Tesla coil - atmospheric
function examine_tesla_coil()
    show_message("A small Tesla coil, currently inactive. Scorch marks on the ceiling show recent use.")

    if has_item("crystal") then
        show_message("As you approach with the crystal, the coil begins to hum faintly...")
        show_message("Sparks dance between the electrodes, drawn to the crystal's energy!")
        show_message("This is how the professor studied the crystal's properties.")
    else
        show_message("Without the crystal, the Tesla coil serves little purpose. It hums faintly when you approach.")
    end
end

-- Chalkboard - scientific clues
function examine_chalkboard()
    show_message("A chalkboard filled with complex equations and crystallography notations.")

    if not get_game_state("chalkboard_examined") then
        show_message("In the corner, circled multiple times: 'CRITICAL: Energy amplification at 11:47 PM - lunar alignment!'")
        show_message("The same time as the stopped clock in the library. This can't be coincidence.")
        set_game_state("chalkboard_examined", true)
        set_game_state("alignment_time_confirmed", true)
    end

    if has_item("research_notes") then
        show_message("The equations here match calculations in your notes.")
        show_message("The professor was planning something for tonight - something involving the fountain and statue.")
    end
end

-- Journal - professor's personal notes
function examine_journal()
    show_message("A leather-bound journal lies open on a stool.")

    if not get_game_state("journal_read") then
        show_message("The handwriting is frantic, nearly illegible in places.")
        show_message("The last entry: 'The butler asked again about the crystal's resonance frequency.'")
        show_message("'Why would a servant need to know such things? I must be more careful.'")
        set_game_state("journal_read", true)
        set_game_state("butler_suspicion_noted", true)
    else
        show_message("The journal's final entries paint a picture of growing paranoia - and perhaps justified fear.")
    end
end

-- Safe - locked, hints at more secrets
function examine_safe()
    show_message("A heavy iron safe bolted to the floor. The combination dial shows signs of recent use.")

    if get_game_state("safe_opened") then
        show_message("The safe stands open and empty.")
        return
    end

    if not get_game_state("safe_examined") then
        show_message("Whatever the professor keeps here, he didn't trust it to the cabinet.")
        show_message("Without the combination, you won't be opening this.")
        set_game_state("safe_examined", true)
    end

    -- Try 11:47 as combination if we've discovered the alignment time
    if get_game_state("alignment_time_confirmed") then
        show_message("11:47... that number keeps appearing. You try it as the combination...")
        show_message("11... 47... Click! The safe swings open!")
        play_sound("success")
        set_game_state("safe_opened", true)

        show_message("Inside you find old documents and a rusty iron key with a flower-shaped bow.")
        show_message("A note reads: 'For the garden. What grows there must not be disturbed.' - E.A.")

        if not has_item("garden_key") then
            add_to_inventory("garden_key")
            play_sound("pickup")
        end
    end
end

-- Scientist interaction
function on_scientist_interact()
    if not get_game_state("scientist_questioned") then
        set_game_state("scientist_questioned", true)
        complete_quest_objective("find_crystal", "talk_to_scientist")
    end

    -- Check if we have the confession to show him
    if has_item("butler_confession") and not get_game_state("confession_shown_to_scientist") then
        set_game_state("confession_shown_to_scientist", true)
        -- This will be handled in dialog
    end

    start_dialog("scientist_dialog")
end

-- Door to library
function on_door_to_library_click()
    play_sound("door_open")
    show_message("You return to the library through the heavy oak door.")
    change_scene("library")
end

-- Door to garden
function on_door_to_garden_click()
    play_sound("door_open")

    if not get_game_state("visited_garden") then
        show_message("The glass door opens to reveal a fog-shrouded garden.")
        show_message("A faint luminescence seems to emanate from somewhere in the depths...")
    end

    change_scene("garden")
end

-- Scene exit
function on_exit()
    stop_ambient("laboratory_hum")
end

-- Item use handler
function use_item_on_hotspot(item, hotspot)
    if item == "brass_key" then
        if hotspot == "cabinet" then
            examine_cabinet()
            return true
        end
    elseif item == "lamp" then
        if hotspot == "empty_display" then
            examine_empty_display()
            return true
        end
    elseif item == "research_notes" then
        if hotspot == "microscope" then
            examine_microscope()
            return true
        elseif hotspot == "workbench" then
            examine_workbench()
            return true
        elseif hotspot == "chalkboard" then
            examine_chalkboard()
            return true
        end
    elseif item == "crystal_lens" then
        if hotspot == "microscope" then
            examine_microscope()
            return true
        end
    elseif item == "crystal" then
        if hotspot == "tesla_coil" then
            examine_tesla_coil()
            return true
        end
    elseif item == "butler_confession" then
        if hotspot == "scientist" then
            on_scientist_interact()
            return true
        end
    end

    show_message("That combination doesn't seem useful here.")
    return false
end

-- Register hotspot callbacks
hotspot.on_click("workbench", examine_workbench)
hotspot.on_click("cabinet", examine_cabinet)
hotspot.on_click("microscope", examine_microscope)
hotspot.on_click("chemical_shelf", examine_chemical_shelf)
hotspot.on_click("empty_display", examine_empty_display)
hotspot.on_click("tesla_coil", examine_tesla_coil)
hotspot.on_click("chalkboard", examine_chalkboard)
hotspot.on_click("journal", examine_journal)
hotspot.on_click("safe", examine_safe)
hotspot.on_click("door_to_library", on_door_to_library_click)
hotspot.on_click("door_to_garden", on_door_to_garden_click)

-- Register character interactions
character.on_interact("scientist", on_scientist_interact)

-- Register item use handler
scene.on_item_use(use_item_on_hotspot)

-- Scene lifecycle callbacks
scene.on_enter(on_enter)
scene.on_exit(on_exit)
