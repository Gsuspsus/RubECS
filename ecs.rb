# frozen_string_literal: true

class DuplicateComponentError < StandardError
  def initialize(name)
    msg = "Can't add duplicate component '#{name}'"
    super(msg)
  end
end

class InvalidNameError < StandardError
  def initialize(name)
    msg = "Component name must be of type Class (got #{name.class})"
    super(msg)
  end
end

# Represents an entity. Contains methods for CRUD relating to its components
class Entity
  attr_reader :id, :components

  def initialize(id, components)
    @id = id
    @components = Hash(components)
  end

  def get(name)
    @components[name] || nil
  end

  def add(component)
    if @components.key?(component.class)
      raise DuplicateComponentError, component.class.name
    else
      @components[component.class] = component
    end
  end

  def remove(name)
    @components.delete(name)
  end

  def update(name, &block)
    component = get(name)
    component.tap(&block)
  end

  def has_component?(name)
    raise InvalidNameError, name unless name.is_a?(Class)

    @components.any? { |n, _| n == name }
  end
end


# Is responsible for Entity instantiation.
# Is not meant to be called directly but rather through the manager class
class EntityCreator
  def initialize
    @@current_id = 0
  end

  def create_new_entity(*components)
    @@current_id += 1
    entries = components.map { |e| make_entry_from(e) }.reduce(&:merge)
    Entity.new(@@current_id, entries)
  end

  def make_entry_from(component)
    { component.class => component }
  end
end

# Keeps track of all entities and is responsible for CRUD relating to them.
class EntityManager

  def initialize
    @entities = []
    @creator = EntityCreator.new
  end

  def create_entity(*components)
    entity = @creator.create_new_entity(*components)
    @entities << entity
    entity
  end

  def find_by_id(id)
    @entities.find { |e| e.id == id }
  end

  def find_by_component_names(*names)
    @entities.filter { |e| names.any? { |name| e.has_component?(name) } }
  end

  def remove_by_id(id)
    @entities.delete_if { |e| e.id == id }
  end
end

# Represents the main point of interaction with the library.
# Handles the creation and deletion of systems and delegates any other CRUD to manager
class World
  attr_reader :manager

  def initialize
    @manager = EntityManager.new
    @systems = []
  end

  def add_system(system)
    @systems << system
  end

  def remove_system(name)
    @systems.delete_if { |s| s.instance_of?(name) }
  end

  def process
    @systems.each { |s| s.process(@manager) }
  end

  # TODO: - actually implement methods
  def method_missing(m, *args, &block)
    if @manager.respond_to?(m)
      @manager.send(m, *args, &block)
    else
      raise NoMethodError
    end
  end

  def respond_to_missing?(m, _include_private = false)
    @manager.respond_to?(m)
  end
end
