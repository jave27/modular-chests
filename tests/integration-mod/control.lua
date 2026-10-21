local function place_chest(surface, position, quality)
  return surface.create_entity{
    name = "modular-chest",
    position = position,
    force = game.forces.player,
    quality = quality or "normal",
    raise_built = true
  }
end

local function assert_single_entity(surface, name, area, message)
  local entities = surface.find_entities_filtered{name = name, area = area}
  assert(#entities == 1, message .. " (found " .. #entities .. ")")
  return entities[1]
end

local function test_normal_merge(surface)
  for x = 0, 5 do
    place_chest(surface, {x, 0})
  end

  assert_single_entity(
    surface,
    "long-iron-chest",
    {{-1, -1}, {7, 1}},
    "six normal chests did not merge"
  )
end

local function test_quality_merge(surface)
  local first = place_chest(surface, {0, 10}, "uncommon")
  first.get_inventory(defines.inventory.chest).insert{
    name = "iron-plate",
    count = 1,
    quality = "rare"
  }

  for x = 1, 5 do
    place_chest(surface, {x, 10}, "uncommon")
  end

  local merged = assert_single_entity(
    surface,
    "long-iron-chest",
    {{-1, 9}, {7, 11}},
    "six uncommon chests did not merge"
  )

  assert(merged.quality.name == "uncommon", "merged chest lost its quality")
  assert(
    #merged.get_inventory(defines.inventory.chest) == 249,
    "uncommon merged chest has the wrong inventory size"
  )

  local contents = merged.get_inventory(defines.inventory.chest).get_contents()
  assert(contents[1].quality == "rare", "item-stack quality was not preserved")
end

local function test_mixed_quality_does_not_merge(surface)
  for x = 0, 5 do
    place_chest(
      surface,
      {x, 20},
      x % 2 == 0 and "normal" or "uncommon"
    )
  end

  assert(
    surface.count_entities_filtered{
      name = "modular-chest",
      area = {{-1, 19}, {7, 21}}
    } == 6,
    "mixed-quality chests merged"
  )
end

local function test_wire_preservation(surface)
  local chests = {}
  for x = 0, 4 do
    chests[#chests + 1] = place_chest(surface, {x, 30})
  end

  local red_target = surface.create_entity{
    name = "constant-combinator",
    position = {0, 32},
    force = game.forces.player
  }
  local green_target = surface.create_entity{
    name = "constant-combinator",
    position = {4, 32},
    force = game.forces.player
  }

  assert(
    chests[1].get_wire_connector(
      defines.wire_connector_id.circuit_red,
      true
    ).connect_to(
      red_target.get_wire_connector(
        defines.wire_connector_id.circuit_red,
        true
      )
    ),
    "failed to create red test wire"
  )
  assert(
    chests[5].get_wire_connector(
      defines.wire_connector_id.circuit_green,
      true
    ).connect_to(
      green_target.get_wire_connector(
        defines.wire_connector_id.circuit_green,
        true
      )
    ),
    "failed to create green test wire"
  )

  place_chest(surface, {5, 30})
  local merged = assert_single_entity(
    surface,
    "long-iron-chest",
    {{-1, 29}, {7, 31}},
    "wired chests did not merge"
  )

  assert(
    merged.get_wire_connector(
      defines.wire_connector_id.circuit_red,
      false
    ).connection_count == 1,
    "red wire was lost during the initial merge"
  )
  assert(
    merged.get_wire_connector(
      defines.wire_connector_id.circuit_green,
      false
    ).connection_count == 1,
    "green wire was lost during the initial merge"
  )

  for x = 6, 12 do
    place_chest(surface, {x, 30})
  end

  local expanded = assert_single_entity(
    surface,
    "long-iron-chest-1x13",
    {{-1, 29}, {14, 31}},
    "wired chest did not expand to thirteen modules"
  )
  assert(
    expanded.get_wire_connector(
      defines.wire_connector_id.circuit_red,
      false
    ).connection_count == 1,
    "red wire was lost during expansion"
  )
  assert(
    expanded.get_wire_connector(
      defines.wire_connector_id.circuit_green,
      false
    ).connection_count == 1,
    "green wire was lost during expansion"
  )
end

local function test_steel_vertical_expansion(surface)
  local function place(y)
    return surface.create_entity{
      name = "modular-steel-chest",
      position = {30, y},
      force = game.forces.player,
      raise_built = true
    }
  end
  local first = place(0)
  first.insert{name = "steel-plate", count = 10}
  for y = 1, 5 do place(y) end
  local merged = assert_single_entity(
    surface, "long-steel-chest-v", {{29, -1}, {31, 7}},
    "six steel chests did not merge vertically"
  )
  assert(#merged.get_inventory(defines.inventory.chest) == 768, "wrong steel chest capacity")
  for y = 6, 12 do place(y) end
  local expanded = assert_single_entity(
    surface, "long-steel-chest-v-1x13", {{29, -1}, {31, 14}},
    "steel chest did not expand vertically"
  )
  assert(#expanded.get_inventory(defines.inventory.chest) == 1536, "wrong expanded steel capacity")
  assert(expanded.get_item_count("steel-plate") == 10, "vertical expansion lost items")
  assert(expanded.force == game.forces.player, "vertical expansion changed force")
end

script.on_init(function()
  local surface = game.surfaces[1]
  test_normal_merge(surface)
  if script.active_mods["quality"] then
    test_quality_merge(surface)
    test_mixed_quality_does_not_merge(surface)
  end
  test_wire_preservation(surface)
  test_steel_vertical_expansion(surface)
  helpers.write_file("integration-test-result.txt", "PASS")
end)
