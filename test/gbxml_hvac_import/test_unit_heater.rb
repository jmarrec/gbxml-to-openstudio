require_relative 'minitest_helper'

class TestUnitHeater < MiniTest::Test
  attr_accessor :model, :model_manager, :gbxml_path

  def before_setup
    self.gbxml_path = Config::GBXML_FILES + '/UnitHeaterAllVariations.xml'
    translator = OpenStudio::GbXML::GbXMLReverseTranslator.new
    self.model = translator.loadModel(self.gbxml_path).get
    self.model_manager = ModelManager.new(self.model, self.gbxml_path)
    self.model_manager.load_gbxml
  end

  def test_xml_creation
    equipment = self.model_manager.zone_hvac_equipments.values[0]
    xml_element = self.model_manager.gbxml_parser.zone_hvac_equipments[0]
    name = xml_element.elements['Name'].text
    id = xml_element.attributes['id']
    cad_object_id = xml_element.elements['CADObjectId'].text

    assert(equipment.name == name)
    assert(equipment.cad_object_id == cad_object_id)
    assert(equipment.id == id)
  end

  def test_build
    self.model_manager.build
    uh_elec = self.model_manager.zone_hvac_equipments.values[0].unit_heater
    uh_furnace = self.model_manager.zone_hvac_equipments.values[1].unit_heater
    uh_hw = self.model_manager.zone_hvac_equipments.values[2].unit_heater

    assert(uh_elec.heatingCoil.to_CoilHeatingElectric.is_initialized)
    assert(uh_elec.supplyAirFan.to_FanConstantVolume.is_initialized)
    assert(uh_elec.is_a?(OpenStudio::Model::ZoneHVACUnitHeater))

    assert(uh_furnace.heatingCoil.to_CoilHeatingGas.is_initialized)
    assert(uh_hw.heatingCoil.to_CoilHeatingWater.is_initialized)

    assert(uh_elec.name.get == 'UH Electric')
    assert(uh_elec.additionalProperties.getFeatureAsString('id').get == 'aim0824')
    assert(uh_elec.additionalProperties.getFeatureAsString('CADObjectId').get == '280066-1')
  end

  def create_osw
    osw = create_test_sizing_osw
    osw = adjust_gbxml_paths(osw, 'UnitHeaterAllVariations.xml')
    osw_in_path = Config::TEST_OUTPUT_PATH + '/unit_heater/in.osw'
    osw.saveAs(osw_in_path)
  end

  def test_simulation
    create_osw
    # set osw_path to find location of osw to run
    osw_in_path = Config::TEST_OUTPUT_PATH + '/unit_heater/in.osw'
    cmd = "\"#{Config::CLI_PATH}\" run -w \"#{osw_in_path}\""
    assert(run_command(cmd))

    osw_out_path = Config::TEST_OUTPUT_PATH + '/unit_heater/out.osw'
    osw_out = JSON.parse(File.read(osw_out_path))

    assert(osw_out['completed_status'] == 'Success')
  end
end