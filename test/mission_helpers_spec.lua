local yarrrconfig = require "yarrrconfig"

local radius = 100

local expected_object = {}
object_coordinate = { x = 100, y = 100 }
expected_object.coordinate = object_coordinate
local expected_object_id = "expected_object_id"
objects = {}
objects.expected_object_id = expected_object
_G.objects = objects

local existing_mission_id = "existing_mission_id"
missions = {}
missions.existing_mission_id = {}
missions.existing_mission_id.character = {}
missions.existing_mission_id.character.object_id = expected_object_id
_G.missions = missions

_G.failed = 0
_G.succeeded = 1
_G.ongoing = 2

describe( "mission helpers", function()

  describe( "distance between", function()

    it( "returns the distance between two coordinates ", function()
      a = { x = 10, y = 10 }
      b = { x = 20, y = 20 }
      assert.are.equal(
        math.sqrt( 200 ),
        yarrrconfig.distance_between( a, b ) )
    end)

  end)

  describe( "ship of mission", function()

    it( "returns the ship object of the given mission", function()
      ship = yarrrconfig.ship_of_mission( existing_mission_id )
      assert.are.same( ship, expected_object )
    end)

  end)

  describe( "checkpoint", function()

    function future()
      return os.time() + 100
    end

    function past()
      return os.time() - 100
    end

    function far_away()
      coordinate = {
        x = object_coordinate.x + radius + 10,
        y = object_coordinate.y }
      return coordinate
    end

    function close_enough()
      coordinate = {
        x = object_coordinate.x + radius,
        y = object_coordinate.y }
      return coordinate
    end

    it( "fails if timer expires", function()
      assert.are.equal(
        failed,
        yarrrconfig.checkpoint( existing_mission_id, far_away(), radius, past() ) )
    end)

    it( "returns ongoing if the object is far from the destination ", function()
      assert.are.equal(
        ongoing,
        yarrrconfig.checkpoint( existing_mission_id, far_away(), radius, future() ) )
    end)

    it( "returns succeeded if the object is closer than the radius to the destination ", function()
      assert.are.equal(
        succeeded,
        yarrrconfig.checkpoint( existing_mission_id, close_enough(), radius, future() ) )
    end)

  end)

end)
