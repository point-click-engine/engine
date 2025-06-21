-- Laboratory scene script

function on_enter()
    print("Entering laboratory...")
    show_message("The laboratory is filled with strange equipment and bubbling beakers.")
end

function on_workbench_click()
    show_message("The workbench is cluttered with experiments.")
    if has_item("crystal_shard") then
        show_message("You could analyze the crystal here...")
        -- TODO: Add puzzle
    end
end

function on_cabinet_click()
    if not get_game_state("cabinet_unlocked") then
        if has_item("key") then
            show_message("You unlock the cabinet with the brass key!")
            set_game_state("cabinet_unlocked", true)
            show_message("Inside you find a glowing crystal shard!")
            add_to_inventory("crystal_shard", "A glowing crystal fragment")
            trigger_achievement("treasure_hunter")
        else
            show_message("The cabinet is locked. You need a key.")
        end
    else
        show_message("The cabinet is empty now.")
    end
end

function on_door_to_library_click()
    change_scene("library")
end

function on_door_to_garden_click()
    if get_game_state("crystal_analyzed") then
        change_scene("garden")
    else
        show_message("You should investigate the laboratory first.")
    end
end

-- Register hotspot callbacks
hotspot.on_click("workbench", on_workbench_click)
hotspot.on_click("cabinet", on_cabinet_click)
hotspot.on_click("door_to_library", on_door_to_library_click)
hotspot.on_click("door_to_garden", on_door_to_garden_click)