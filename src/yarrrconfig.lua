local yarrrconfig = {}

function create_shape_from( tiles )
  local local_shape = Shape.new()
  for i, tile  in ipairs( tiles ) do
    local_shape:add_tile( tile )
  end

  return local_shape
end

function add_behaviors_to( object, behaviors )
  for i, behavior  in ipairs( behaviors ) do
    object:add_behavior( behavior )
  end
end

function yarrrconfig.create_ship( object, tiles, additional_behaviors )
  add_behaviors_to( object, {
      PhysicalBehavior.new(),
      Inventory.new(),
      Collider.new( ship_layer ),
      DamageCauser.new( 100 ),
      LootDropper.new(),
      ShapeBehavior.new( create_shape_from( tiles ) ),
      ShapeGraphics.new()
    } )

  add_behaviors_to( object, additional_behaviors )
end

function yarrrconfig.distance_between( a, b )
  return math.sqrt( math.pow( a.x - b.x, 2 ) + math.pow( a.y - b.y, 2 ) )
end


function yarrrconfig.ship_of_mission( mission_id )
  return objects[ missions[ mission_id ].character.object_id ]
end


function yarrrconfig.checkpoint( mission_id, destination, radius, till )
  if till < os.time() then
    return failed
  end

  local ship = yarrrconfig.ship_of_mission( mission_id )
  local distance_from_checkpoin = yarrrconfig.distance_between( ship.coordinate, destination )

  if distance_from_checkpoin <= radius then
    return succeeded
  end

  return ongoing
end


function yarrrconfig.length_of( vector )
  return yarrrconfig.distance_between( { x=0, y=0 }, vector )
end

function yarrrconfig.is_slower_than( speed, object )
  return yarrrconfig.length_of( object.velocity ) < speed
end


function yarrrconfig.add_instruction( mission, message )
  mission:add_objective( MissionObjective.new(
    message,
    function() return succeeded end ) )
end

return yarrrconfig

