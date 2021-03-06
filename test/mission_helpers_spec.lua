local yarrrconfig = require "yarrrconfig"

local radius = 100

local expected_object = {}
object_coordinate = { x = 100, y = 100 }
expected_object.coordinate = object_coordinate
object_velocity = { x = 10, y = 10 }
expected_object.velocity = object_velocity
local expected_object_id = "expected_object_id"
objects = {}
objects.expected_object_id = expected_object
_G.objects = objects

local existing_mission_id = "existing_mission_id"
local existing_mission = { id = function( this ) return existing_mission_id end }
existing_mission.character = {}
existing_mission.character.object_id = expected_object_id

local mission_contexts = { existing_mission_id = existing_mission }
local expected_context = mission_contexts.existing_mission_id

_G.mission_contexts = mission_contexts


_G.failed = 0
_G.succeeded = 1
_G.ongoing = 2

function _G.universe_time()
  return 100000
end

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

  describe( "length of", function()

    it( "returns the length of the vector", function()
      a = { x = 5, y = 10 }
      assert.are.equal(
        math.sqrt( 125 ),
        yarrrconfig.length_of( a ) )
    end)

  end)

  describe( "is slower than", function()

    it( "returns true if the speed of the object is less than the given value", function()
      assert.is_true( yarrrconfig.is_slower_than( 14.15, expected_object ) )
    end)

    it( "returns false if the speed of the object is more than the given value", function()
      assert.is_false( yarrrconfig.is_slower_than( 14.14, expected_object ) )
    end)

  end)

  describe( "context of mission", function()

    it( "returns the context table for a given mission", function()
      local context = yarrrconfig.context_of( existing_mission )
      assert.are.same( context, expected_context )
    end)

  end)

  describe( "ship of mission", function()

    it( "returns the ship object of the given mission", function()
      local ship = yarrrconfig.ship_of( existing_mission )
      assert.are.same( expected_object, ship )
    end)

  end)

  describe( "ship of mission by id", function()

    it( "returns the ship object of the given mission", function()
      local ship = yarrrconfig.ship_of_mission_by_id( existing_mission:id() )
      assert.are.same( expected_object, ship )
    end)

    it( "returns nil if the mission does not exist", function()
      local ship = yarrrconfig.ship_of_mission_by_id( "not existing mission" )
      assert.are.same( nil, ship )
    end)

    it( "returns nil if the object does not exist", function()
      local dummy_mission_id = "dummy_mission_id"
      _G.mission_contexts[ dummy_mission_id ] = {
        character = {
          object_id = "not existing object"
        }
      }
      local ship = yarrrconfig.ship_of_mission_by_id( "dummy_mission_id" )
      assert.are.same( nil, ship )
    end)

  end)

  describe( "checkpoint", function()

    function future()
      return universe_time() + 100
    end

    function past()
      return universe_time() - 100
    end

    function far_away()
      local coordinate = {
        x = object_coordinate.x + radius + 10,
        y = object_coordinate.y }
      return coordinate
    end

    function close_enough()
      local coordinate = {
        x = object_coordinate.x + radius,
        y = object_coordinate.y }
      return coordinate
    end

    it( "fails if timer expires", function()
      assert.are.equal(
        failed,
        yarrrconfig.checkpoint( existing_mission, far_away(), radius, past() ) )
    end)

    it( "returns ongoing if the object is far from the destination ", function()
      assert.are.equal(
        ongoing,
        yarrrconfig.checkpoint( existing_mission, far_away(), radius, future() ) )
    end)

    it( "returns succeeded if the object is closer than the radius to the destination ", function()
      assert.are.equal(
        succeeded,
        yarrrconfig.checkpoint( existing_mission, close_enough(), radius, future() ) )
    end)

  end)

  describe( "add objective to mission", function()
    function create_checker()
      local checker = {}
      checker.call_count = 0
      checker.call = function( this, parameter )
        this.was_called_with = parameter
        this.call_count = this.call_count + 1
      end
      return checker
    end

    local created_updater = nil
    local test_mission_id = "1"
    local test_mission = {
      id = function( this )
        return test_mission_id
      end,
      add_objective = function( this, objective )
        this.new_objective = objective
      end }

    local test_objective = {}
    local was_objective_created = false
    _G.MissionObjective = {
      new = function( description, updater )
        was_objective_created = true
        test_objective.description = description
        test_objective.updater = updater
        return test_objective
      end }

    local setup_checker = nil
    local updater_checker = nil
    local teardown_checker = nil
    local updater_status = nil
    local returned_status = nil
    local expected_description = "objective description appletree"

    function update_with_status( status )
      updater_status = status
      returned_status = created_updater( test_mission )
    end

    function reset_data()
      test_objective = {}
      test_mission.new_objective = {}
      was_objective_created = false
      updater_status = ongoing
      setup_checker = create_checker()
      updater_checker = create_checker()
      teardown_checker = create_checker()
      _G.mission_contexts = {}
      _G.mission_contexts[ test_mission_id ] = {}
    end

    function create_new_objective( objective_descriptor )
      yarrrconfig.add_objective_to(
      test_mission,
      objective_descriptor )

      created_updater = test_objective.updater
      update_with_status( ongoing )
    end

    before_each( function()
      reset_data()
      create_new_objective( {
        description = expected_description,

        setup = function ( mission )
          setup_checker:call( mission )
        end,

        updater = function ( mission )
          updater_checker:call( mission )
          return updater_status
        end,

        teardown = function ( mission )
          teardown_checker:call( mission )
        end } )
    end)


    it( "creates a mission objective", function()
      assert.is_true( was_objective_created )
    end)

    it( "creates the objective with the given description ", function()
      assert.are.equal( test_objective.description, expected_description )
    end)

    it( "adds the created objective to the mission", function()
      assert.are.equal( test_mission.new_objective, test_objective )
    end)

    it( "calls the set up function with the mission object", function()
      assert.are.equal( 1, setup_checker.call_count )
      assert.are.same( test_mission, setup_checker.was_called_with )
    end)

    it( "calls the set up function only the first time", function()
      created_updater( test_mission )
      assert.are.equal( 1, setup_checker.call_count )
    end)

    it( "can call setup after tear down of the previous objective", function()
      update_with_status( succeeded )
      created_updater( test_mission )
      assert.are.equal( 2, setup_checker.call_count )
    end)

    it( "calls the updater function with the mission object", function()
      assert.are.equal( 1, updater_checker.call_count )
      assert.are.same( test_mission, updater_checker.was_called_with )
    end)

    it( "calls the tear down function with the mission object if the updater succeeds", function()
      update_with_status( succeeded )
      assert.are.equal( 1, teardown_checker.call_count )
      assert.are.same( test_mission, teardown_checker.was_called_with )
    end)

    it( "calls the tear down function only if the updater succeeds", function()
      assert.are.equal( 0, teardown_checker.call_count )
      update_with_status( failed )
      assert.are.equal( 0, teardown_checker.call_count )
    end)

    function check_returns_correct_status( status )
      update_with_status( status )
      assert.are.equal( status, returned_status )
    end

    it( "returns with the return value of the updater", function()
      check_returns_correct_status( ongoing )
      check_returns_correct_status( succeeded )
      check_returns_correct_status( failed )
    end)

    it( "fixes missing parts of the objective", function()
      reset_data()
      create_new_objective( {} )
    end)

  end)

  describe( "bind to mission", function()
    local created_agent = {
    }

    local agent_period = nil

    local agent_function = nil

    local created_function = {}

    _G.LuaFunction = {
      new = function( f )
        agent_function = f
        return {}
      end
    }

    _G.LuaAgent = {
      new = function( f, period )
        agent_period = period
        return created_agent
      end
    }

    local object = {
      add_behavior = function( self, behavior )
        self.new_behavior = behavior
      end,

      destroy_self = function( self )
        self.was_destroyed = true
      end
    }

    before_each( function()
      agent_period = nil
      agent_function = nil
      object.new_behavior = nil
      object.was_destroyed = false
      _G.mission_contexts.existing_mission_id = existing_mission
      yarrrconfig.bind_to_mission( object, existing_mission_id )
    end)

    it( "adds a lua agent to the object", function()
      assert.are.same( created_agent, object.new_behavior )
    end)

    it( "passes the agent function to the behavior", function()
      assert.truthy( agent_function )
    end)

    it( "the behavior is updated once a second", function()
      local one_second = 1000000
      assert.are.equal( one_second, agent_period )
    end)

    it( "does not destroy the object if the mission still exists", function()
      agent_function( object )
      assert.are.equal( false, object.was_destroyed )
    end)

    it( "destroys the object if the mission does not exist", function()
      _G.mission_contexts.existing_mission_id = nil
      agent_function( object )
      assert.are.equal( true, object.was_destroyed )
    end)

  end)


end)

