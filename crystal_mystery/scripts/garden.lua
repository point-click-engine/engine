-- Garden Scene Script
-- Handles interactions and events in the garden

function on_enter()
    print("Entering garden...")
    show_message("The moonlit garden is peaceful and mysterious.")
    set_game_state("visited_garden", true)
    
    -- Play ambient garden sounds
    play_ambient("garden_night", 0.4)
end

function on_fountain_click()
    show_message("The fountain sparkles with crystal-clear water under the moonlight.")
    if has_item("crystal") and has_item("crystal_lens") then
        show_message("You place the crystal in the fountain and focus the lens...")
        show_message("The water begins to glow with mystical energy!")
        set_game_state("fountain_activated", true)
        complete_quest_objective("final_revelation", "restore_crystal")
        play_sound("success")
    elseif has_item("crystal") then
        show_message("The crystal reacts to the water, but you need something to focus its energy.")
    else
        show_message("The fountain seems to be waiting for something special...")
    end
end

function on_statue_click()
    if not get_game_state("statue_examined") then
        show_message("You examine the weathered statue carefully...")
        if not has_item("crystal") then
            show_message("Hidden in the statue's base, you find the missing crystal!")
            add_to_inventory("crystal", "A mysterious glowing crystal")
            set_game_state("statue_examined", true)
            complete_quest_objective("find_crystal", "locate_crystal")
            play_sound("pickup")
        end
    elseif has_item("crystal_lens") then
        show_message("Using the crystal lens, you can see hidden markings on the statue...")
        show_message("The markings show how to properly activate the crystal's power!")
        set_game_state("activation_method_learned", true)
    else
        show_message("The statue has already revealed its secret.")
    end
end

function on_flowerbed_click()
    show_message("Beautiful roses bloom despite the late hour. Their fragrance is intoxicating.")
    if has_item("crystal") then
        show_message("The flowers seem to lean toward the crystal, as if drawn to its energy.")
    end
end

function on_garden_shed_click()
    if has_item("brass_key") then
        show_message("The brass key doesn't fit this lock. This needs a different key.")
    else
        show_message("The tool shed is locked tight. You'd need a key to open it.")
    end
end

function on_bench_click()
    show_message("A weathered stone bench. Someone has carved initials into it: 'E.B. + M.L.'")
    if get_game_state("secret_compartment_found") then
        show_message("Those must be the initials mentioned in the mansion's history!")
    end
end

function on_lamp_post_click()
    if not get_game_state("lamp_taken") then
        show_message("An old-fashioned lamp post. There's an ornate oil lamp hanging from it.")
        if not has_item("lamp") then
            show_message("You take the lamp. It might come in handy.")
            add_to_inventory("lamp", "An ornate oil lamp")
            set_game_state("lamp_taken", true)
            play_sound("pickup")
        end
    else
        show_message("The lamp post stands empty now.")
    end
end

function on_door_to_lab_click()
    play_sound("door_open")
    change_scene("laboratory")
end

function on_exit()
    stop_ambient("garden_night")
end

-- Victory condition check
function check_victory()
    if get_game_state("fountain_activated") and 
       get_game_state("activation_method_learned") and
       has_item("crystal") and has_item("crystal_lens") then
        
        show_message("The crystal pulses with restored energy! The mystery is solved!")
        show_message("You have successfully restored the Crystal of Luminus!")
        
        -- Complete final quest
        complete_quest("final_revelation")
        trigger_achievement("master_detective")
        set_game_state("game_complete", true)
        
        -- TODO: Show ending cutscene
        start_cutscene("ending_sequence")
    end
end

-- Register hotspot callbacks
hotspot.on_click("fountain", on_fountain_click)
hotspot.on_click("statue", on_statue_click)
hotspot.on_click("flowerbed", on_flowerbed_click)
hotspot.on_click("garden_shed", on_garden_shed_click)
hotspot.on_click("bench", on_bench_click)
hotspot.on_click("lamp_post", on_lamp_post_click)
hotspot.on_click("door_to_lab", on_door_to_lab_click)

-- Scene lifecycle callbacks
scene.on_enter(on_enter)
scene.on_exit(on_exit)

-- Update function for checking victory conditions
scene.on_update(check_victory)