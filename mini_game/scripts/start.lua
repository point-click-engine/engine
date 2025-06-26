function on_enter()
  show_message("Welcome to the adventure!")
end
hotspot.on_click("door", function()
  if has_item("key") then
    change_scene("next_room")
  else
    show_message("The door is locked.")
  end
end)