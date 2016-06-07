module SharedAdapterTests
  def setup
    super
    @flipper = Flipper.new(@adapter)
    @actor_class = Struct.new(:flipper_id)
    @feature = @flipper[:stats]
    @boolean_gate = @feature.gate(:boolean)
    @group_gate = @feature.gate(:group)
    @actor_gate = @feature.gate(:actor)
    @actors_gate =  @feature.gate(:percentage_of_actors)
    @time_gate =  @feature.gate(:percentage_of_time)
    Flipper.register(:admins) do |actor|
      actor.respond_to?(:admin?) && actor.admin?
    end

    Flipper.register(:early_access) { |actor|
      actor.respond_to?(:early_access?) && actor.early_access?
    }
  end

  def teardown
    super
    Flipper.unregister_groups
  end

  def test_name
    refute_empty  @adapter.name
    assert_kind_of Symbol, @adapter.name
  end

  def test_ancestors
    assert_includes  @adapter.class.ancestors, Flipper::Adapter
  end

  def test_get
    expected = {
      :boolean => nil,
      :groups => Set.new,
      :actors => Set.new,
      :percentage_of_actors => nil,
      :percentage_of_time => nil,
    }
    assert_equal expected, @adapter.get(@feature)
  end

  def test_enable
    assert_equal true, @adapter.enable(@feature, @boolean_gate, @flipper.boolean)
    assert_equal 'true', @adapter.get(@feature)[:boolean]
  end

  def test_disable
    assert_equal true, @adapter.disable(@feature, @boolean_gate, @flipper.boolean(false))
    assert_equal nil, @adapter.get(@feature)[:boolean]
  end

  def test_can_disable_all
    actor_22 = @actor_class.new('22')
    assert_equal true, @adapter.enable(@feature, @boolean_gate, @flipper.boolean)
    assert_equal true, @adapter.enable(@feature, @boolean_gate, @flipper.group(:admins))
    assert_equal true, @adapter.enable(@feature, @boolean_gate, @flipper.actor(actor_22))
    assert_equal true, @adapter.enable(@feature, @boolean_gate, @flipper.actors(25))
    assert_equal true, @adapter.enable(@feature, @boolean_gate, @flipper.time(45))
    assert_equal true, @adapter.disable(@feature, @boolean_gate, @flipper.boolean(false))
    expected = {
      :boolean => nil,
      :groups => Set.new,
      :actors => Set.new,
      :percentage_of_actors => nil,
      :percentage_of_time => nil
    }
    assert_equal expected, @adapter.get(@feature)
  end

  def test_can_enable_disable_get_value_for_group_gate
    assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:admins))
    assert_equal true, @adapter.enable(@feature, @group_gate, @flipper.group(:early_access))

    result = @adapter.get(@feature)
    assert_equal Set['admins', 'early_access'], result[:groups]

    assert_equal true, @adapter.disable(@feature, @group_gate, @flipper.group(:early_access))
    result = @adapter.get(@feature)
    assert_equal Set['admins'], result[:groups]

    assert_equal true, @adapter.disable(@feature, @group_gate, @flipper.group(:admins))
    result = @adapter.get(@feature)
    assert_equal Set.new, result[:groups]
  end

  def test_can_enable_disable_and_get_value_for_an_actor_gate
    actor_22 = @actor_class.new('22')
    actor_asdf = @actor_class.new('asdf')

    assert_equal true, @adapter.enable(@feature, @actor_gate, @flipper.actor(actor_22))
    assert_equal true, @adapter.enable(@feature, @actor_gate, @flipper.actor(actor_asdf))

    result = @adapter.get(@feature)
    assert_equal Set['22', 'asdf'], result[:actors]

    assert true, @adapter.disable(@feature, @actor_gate, @flipper.actor(actor_22))
    result = @adapter.get(@feature)
    assert_equal Set['asdf'], result[:actors]
  end

  def test_can_enable_disable_get_value_for_percentage_of_actors_gate
    assert_equal true, @adapter.enable(@feature, @actors_gate, @flipper.actors(15))
    result = @adapter.get(@feature)
    assert_equal '15', result[:percentage_of_actors]

    assert_equal true, @adapter.disable(@feature, @actors_gate, @flipper.actors(0))
    result = @adapter.get(@feature)
    assert_equal '0', result[:percentage_of_actors]
  end
end
