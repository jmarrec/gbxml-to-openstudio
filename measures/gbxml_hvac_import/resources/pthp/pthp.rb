require_relative '../hvac_object/hvac_object'

class PTHP < HVACObject
  wshpattr_accessor :pthp, :supply_fan, :cooling_coil, :heating_coil, :supplemental_heating_coil

  def initialize
    self.name = "PTHP"
  end

  def connect_thermal_zone(thermal_zone)
    self.pthp.addToThermalZone(thermal_zone)
  end

  def add_pthp
    pthp = OpenStudio::Model::ZoneHVACPackagedTerminalHeatPump.new(self.model, self.model.alwaysOnDiscreteSchedule, self.supply_fan, self.heating_coil, self.cooling_coil, self.supplemental_heating_coil)
    pthp.setName(self.name) unless self.name.nil?
    pthp.additionalProperties.setFeature('id', self.id) unless self.id.nil?
    pthp.additionalProperties.setFeature('CADObjectId', self.cad_object_id) unless self.cad_object_id.nil?
    pthp
  end

  def add_supply_fan
    OpenStudio::Model::FanOnOff.new(self.model)
  end

  def add_heating_coil
    OpenStudio::Model::CoilHeatingDXSingleSpeed.new(self.model)
  end

  def add_cooling_coil
    OpenStudio::Model::CoilCoolingDXSingleSpeed.new(self.model)
  end

  def add_supplemental_heating_coil
    OpenStudio::Model::CoilHeatingElectric.new(self.model)
  end

  def resolve_dependencies

  end

  def build(model_manager)
    # Object dependency resolution needs to happen before the object is built
    self.model_manager = model_manager
    self.model = model_manager.model
    self.heating_coil = add_heating_coil
    self.supply_fan = add_supply_fan
    self.cooling_coil = add_cooling_coil
    self.supplemental_heating_coil = add_supplemental_heating_coil
    self.pthp = add_pthp
    resolve_dependencies

    self.built = true
    self.pthp
  end

  def self.create_from_xml(xml)
    equipment = new

    name = xml.elements['Name']
    equipment.set_name(xml.elements['Name'].text) unless name.nil?
    equipment.set_id(xml.attributes['id']) unless xml.attributes['id'].nil?
    equipment.set_cad_object_id(xml.elements['CADObjectId'].text) unless xml.elements['CADObjectId'].nil?

    equipment
  end
end