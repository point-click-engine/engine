function on_enter()
  print("Entered test room")
end

hotspot.on_click("test_object", function()
  show_message("You clicked the test object!")
end)