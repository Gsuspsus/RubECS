require_relative '../ecs.rb'

PositionComponent = Struct.new(:x,:y)
HealthComponent = Struct.new(:value)
SpeedComponent = Struct.new(:x,:y)

class UpdatePositionSystem
  def process(manager)
    entities = manager.find_by_component_names(PositionComponent, SpeedComponent) 
    entities.each do |entity|
      speed = entity.get(SpeedComponent)
      entity.update(PositionComponent) {|pos| pos.x += speed.x; pos.y += speed.y}
    end
  end
end

world = World.new
world.create_entity(PositionComponent.new(0,0), SpeedComponent.new(5,10))
world.create_entity(PositionComponent.new(10,5), SpeedComponent.new(1,2), HealthComponent.new(100))

world.add_system(UpdatePositionSystem.new)

pp world.find_by_component_names(PositionComponent)
world.process
pp world.find_by_component_names(PositionComponent)