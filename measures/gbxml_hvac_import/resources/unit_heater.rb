class UnitHeater < HVACObject
  attr_accessor :unit_heater, :supply_fan, :heating_coil, :heating_coil_type, :heating_loop_ref

  def initialize
    self.name = "Unit Heater"
  end

  def connect_thermal_zone(thermal_zone)
    self.unit_heater.addToThermalZone(thermal_zone)
  end

  def add_unit_heater
    unit_heater = OpenStudio::Model::ZoneHVACUnitHeater.new(self.model, self.model.alwaysOnDiscreteSchedule, self.supply_fan, self.heating_coil)
    unit_heater.setName(self.name) unless self.name.nil?
    unit_heater.additionalProperties.setFeature('id', self.id) unless self.id.nil?
    unit_heater.additionalProperties.setFeature('CADObjectId', self.cad_object_id) unless self.cad_object_id.nil?
    unit_heater
  end

  def add_supply_fan
    fan = OpenStudio::Model::FanConstantVolume.new(self.model)
    fan.setName("#{self.name} Fan")
    fan
  end

  def add_heating_coil
    heating_coil = nil

    if self.heating_coil_type == "ElectricResistance"
      heating_coil = OpenStudio::Model::CoilHeatingElectric.new(self.model)
    elsif self.heating_coil_type == "Furnace"
      heating_coil = OpenStudio::Model::CoilHeatingGas.new(self.model)
    elsif self.heating_coil_type == "HotWater"
      heating_coil = OpenStudio::Model::CoilHeatingWater.new(self.model)
    end

    if heating_coil
      heating_coil.setName(self.name + " Heating Coil") unless self.name.nil?
    end

    heating_coil
  end

  def resolve_dependencies
    unless self.heating_loop_ref.nil?
      heating_loop = self.model_manager.hw_loops[self.heating_loop_ref]
      heating_loop.plant_loop.addDemandBranchForComponent(self.heating_coil)
    end
  end

  def build
    # Object dependency resolution needs to happen before the object is built
    self.model_manager = model_manager
    self.model = model_manager.model
    self.heating_coil = add_heating_coil
    self.supply_fan = add_supply_fan
    self.unit_heater = add_unit_heater
    # self.unit_heater.setFanControlType('OnOff')
    resolve_dependencies

    self.built = true
    self.unit_heater
  end

  def self.create_from_xml(model_manager, xml)
    equipment = new
    equipment.model_manager = model_manager

    name = xml.elements['Name']
    equipment.set_name(xml.elements['Name'].text) unless name.nil?
    equipment.set_id(xml.attributes['id']) unless xml.attributes['id'].nil?
    equipment.set_cad_object_id(xml.elements['CADObjectId'].text) unless xml.elements['CADObjectId'].nil?

    unless xml.attributes['heatingCoilType'].nil? or xml.attributes['heatingCoilType'] == "None"
      equipment.heating_coil_type = xml.attributes['heatingCoilType']

      if equipment.heating_coil_type == 'HotWater'
        hydronic_loop_id = xml.elements['HydronicLoopId']
        unless hydronic_loop_id.nil?
          hydronic_loop_id_ref = hydronic_loop_id.attributes['hydronicLoopIdRef']
          unless hydronic_loop_id_ref.nil?
            equipment.heating_loop_ref = hydronic_loop_id_ref
          end
        end
      end
    end

    equipment
  end
end