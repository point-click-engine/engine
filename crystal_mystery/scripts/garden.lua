-- Garden scene script

function on_enter()
    print("Entering garden...")
    show_message("The moonlit garden is peaceful and mysterious.")
end

function on_fountain_click()
    show_message("The fountain sparkles with an otherworldly light.")
    if has_item("crystal_shard") and get_game_state("painting_clue") then
        show_message("The crystal reacts to the fountain's water!")
        show_message("You've discovered the secret of the Crystal Mystery!")
        trigger_achievement("mystery_solver")
        set_game_state("game_complete", true)
        -- TODO: Show ending cutscene
    end
end

function on_statue_click()
    show_message("The statue holds an empty socket where something should be...")
    if has_item("crystal_shard") then
        show_message("The crystal would fit perfectly here!")
    end
end

function on_flowerbed_click()
    show_message("Beautiful roses bloom despite the late hour.")
end

function on_door_to_lab_click()
    change_scene("laboratory")
end

-- Register hotspot callbacks
hotspot.on_click("fountain", on_fountain_click)
hotspot.on_click("statue", on_statue_click)
hotspot.on_click("flowerbed", on_flowerbed_click)
hotspot.on_click("door_to_lab", on_door_to_lab_click)