script.on_init(function()
  local surface = game.surfaces[1]

  -- Arrange entities with surface.create_entity{...}.
  -- Use raise_built = true when the mod's placement event should run.

  -- Assert the expected result with a useful message.
  assert(surface ~= nil, "replace this assertion with your test")

  helpers.write_file("replace-with-test-result.txt", "PASS")
end)
