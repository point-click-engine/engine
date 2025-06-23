function on_enter()
  show_message("You stand before a mysterious door...")
end

hotspot.on_click("door", function()
  if has_item("key") then
    play_sound("unlock")
    change_scene("next_room")
  else
    show_message("The door is locked. You need a key.")
  end
end)