class CAVBox < HVACObject
  attr_accessor :air_terminal, :air_terminal_type, :heating_coil, :heating_coil_type, :heating_loop_ref, :air_loop, :air_loop_ref

  def initialize
    self.name = "CAV Box"
  end

  def connect_thermal_zone(thermal_zone)
    outlet_node = self.air_terminal.outletModelObject.get.to_Node.get
    thermal_zone.addToNode(outlet_node)
  end

  def add_air_terminal
    if self.air_terminal_type == 'Reheat'
      cav_box = OpenStudio::Model::AirTerminalSingleDuctConstantVolumeReheat.new(self.model, self.model.alwaysOnDiscreteSchedule, self.heating_coil)
    else
      cav_box = OpenStudio::Model::AirTerminalSingleDuctUncontrolled.new(self.model, self.model.alwaysOnDiscreteSchedule)
    end

    cav_box.setName(self.name) unless self.name.nil?
    cav_box.additionalProperties.setFeature('id', self.id) unless self.id.nil?
    cav_box.additionalProperties.setFeature('CADObjectId', self.cad_object_id) unless self.cad_object_id.nil?
    cav_box
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

    unless self.air_loop_ref.nil?
      air_loop = self.model_manager.air_systems[self.air_loop_ref]
      air_loop.air_loop_hvac.addBranchForHVACComponent(self.air_terminal)
    end
  end

  def build
    # Object dependency resolution needs to happen before the object is built
    self.model = model_manager.model
    self.heating_coil = add_heating_coil
    self.air_terminal = add_air_terminal
    resolve_dependencies

    self.built = true
    self.air_terminal
  end

  def self.create_from_xml(model_manager, xml)
    cav_box = new
    cav_box.model_manager = model_manager

    name = xml.elements['Name']
    cav_box.set_name(xml.elements['Name'].text) unless name.nil?
    cav_box.set_id(xml.attributes['id']) unless xml.attributes['id'].nil?
    cav_box.set_cad_object_id(xml.elements['CADObjectId'].text) unless xml.elements['CADObjectId'].nil?

    air_loop_ref = xml.elements['AirSystemId']
    unless air_loop_ref.nil?
      cav_box.air_loop_ref = xml.elements['AirSystemId'].attributes['airSystemIdRef']
    end

    unless xml.attributes['heatingCoilType'].nil? or xml.attributes['heatingCoilType'] == "None"
      cav_box.heating_coil_type = xml.attributes['heatingCoilType']

      if cav_box.heating_coil_type == 'HotWater'
        hydronic_loop_id = xml.elements['HydronicLoopId']
        unless hydronic_loop_id.nil?
          hydronic_loop_id_ref = hydronic_loop_id.attributes['hydronicLoopIdRef']
          unless hydronic_loop_id_ref.nil?
            cav_box.heating_loop_ref = hydronic_loop_id_ref
          end
        end
      end

      if ['HotWater', 'Furnace', 'ElectricResistance'].include? cav_box.heating_coil_type
        cav_box.air_terminal_type = 'Reheat'
      else
        cav_box.air_terminal_type = 'NoReheat'
      end
    end

    cav_box
  end
end