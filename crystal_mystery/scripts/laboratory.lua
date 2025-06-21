-- Laboratory Scene Script
-- Handles interactions and events in the laboratory

function on_enter()
    print("Entering laboratory...")
    show_message("The laboratory is filled with strange equipment and bubbling beakers.")
    set_game_state("visited_laboratory", true)
    
    -- Play ambient laboratory sounds
    play_ambient("laboratory_hum", 0.3)
end

function on_workbench_click()
    if not get_game_state("workbench_examined") then
        set_game_state("workbench_examined", true)
        set_game_state("lab_examined", true) -- Quest objective
        
        show_message("You examine the cluttered workbench carefully...")
        if not has_item("mysterious_note") then
            show_message("Hidden among the beakers, you find a mysterious note with strange symbols!")
            add_to_inventory("mysterious_note", "A cryptic note with strange symbols")
            play_sound("pickup")
            
            -- Complete quest objective
            complete_quest_objective("find_crystal", "examine_lab")
        end
    else
        show_message("The workbench is thoroughly examined. Just equipment and chemicals remain.")
    end
end

function on_cabinet_click()
    if get_game_state("cabinet_unlocked") then
        if not has_item("crystal_lens") then
            show_message("Inside the cabinet is a special crystal lens!")
            add_to_inventory("crystal_lens", "A special lens for enhancing crystal energy")
            play_sound("pickup")
        else
            show_message("The cabinet is empty now.")
        end
    elseif has_item("brass_key") then
        show_message("You unlock the cabinet with the brass key!")
        set_game_state("cabinet_unlocked", true)
        play_sound("success")
        
        -- Immediately trigger opening
        on_cabinet_click()
    else
        show_message("The cabinet is locked. You need a key to open it.")
    end
end

function on_microscope_click()
    if has_item("research_notes") then
        show_message("Using the microscope with the research notes reveals hidden details about crystal energy!")
        set_game_state("microscope_analysis_complete", true)
        complete_quest_objective("library_investigation", "decode_ancient_text")
        play_sound("success")
    else
        show_message("A powerful microscope. I need something specific to examine with this.")
    end
end

function on_chemical_shelf_click()
    show_message("Shelves full of mysterious chemicals. Better not touch anything without proper knowledge.")
    if has_item("crystal") then
        show_message("Some of these chemicals could react dangerously with the crystal. I should be careful.")
    end
end

function on_scientist_interact()
    if not get_game_state("scientist_questioned") then
        set_game_state("scientist_questioned", true)
        complete_quest_objective("find_crystal", "talk_to_scientist")
    end
    
    -- Start dialog with scientist
    start_dialog("scientist_dialog")
end

function on_door_to_library_click()
    play_sound("door_open")
    change_scene("library")
end

function on_door_to_garden_click()
    play_sound("door_open") 
    change_scene("garden")
end

function on_exit()
    stop_ambient("laboratory_hum")
end

-- Register hotspot callbacks
hotspot.on_click("workbench", on_workbench_click)
hotspot.on_click("cabinet", on_cabinet_click)
hotspot.on_click("microscope", on_microscope_click)
hotspot.on_click("chemical_shelf", on_chemical_shelf_click)
hotspot.on_click("door_to_library", on_door_to_library_click)
hotspot.on_click("door_to_garden", on_door_to_garden_click)

-- Register character interactions
character.on_interact("scientist", on_scientist_interact)

-- Scene lifecycle callbacks
scene.on_enter(on_enter)
scene.on_exit(on_exit)