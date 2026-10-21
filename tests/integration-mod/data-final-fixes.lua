-- Check the parsed input as well as runtime wires: connectors created through
-- the scripting API can work even when the prototype has no connector graphics.
for name, chest in pairs(data.raw.container) do
  if name == "modular-chest" or name == "modular-steel-chest"
    or name:match("^long%-iron%-chest") or name:match("^long%-steel%-chest") then
    local connector = chest.circuit_connector
    assert(connector, name .. " has no circuit connector")
    -- The vanilla definition is a single struct in 2.0 and an array in 2.1.
    if data.raw.container["iron-chest"].circuit_connector[1] then
      assert(connector[1], name .. " needs an array of circuit connectors")
      connector = connector[1]
    end
    assert(connector.points and connector.sprites, name .. " has incomplete connector graphics")
    assert(chest.circuit_wire_connection_point == nil, name .. " uses an obsolete connector field")
    assert(chest.circuit_connector_sprites == nil, name .. " uses an obsolete connector field")
    if name:match("^long%-") then
      assert(chest.placeable_by.item == chest.minable.result,
        name .. " requests the wrong construction item")
      assert(chest.placeable_by.count == chest.minable.count,
        name .. " requests the wrong construction item count")
    end
  end
end
