require_relative 'minitest_helper'

class TestPTAC < MiniTest::Test
  attr_accessor :model, :model_manager, :gbxml_path

  def before_setup
    self.gbxml_path = Config::GBXML_FILES + '/PTACAllVariations.xml'
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
    ptac_elec = self.model_manager.zone_hvac_equipments.values[0].ptac
    ptac_furnace = self.model_manager.zone_hvac_equipments.values[1].ptac
    ptac_hw = self.model_manager.zone_hvac_equipments.values[2].ptac

    # TODO: update this test after Autodesk fix the xml output
    assert(ptac_elec.coolingCoil.to_CoilCoolingDXSingleSpeed.is_initialized)
    assert(ptac_elec.heatingCoil.to_CoilHeatingElectric.is_initialized)
    assert(ptac_elec.supplyAirFan.to_FanOnOff.is_initialized)
    assert(ptac_elec.is_a?(OpenStudio::Model::ZoneHVACPackagedTerminalAirConditioner))

    assert(ptac_furnace.heatingCoil.to_CoilHeatingGas.is_initialized)
    assert(ptac_hw.heatingCoil.to_CoilHeatingWater.is_initialized)

    # only need to test one object for this mapping
    assert(ptac_elec.name.get == 'PTAC Elec')
    assert(ptac_elec.additionalProperties.getFeatureAsString('id').get == 'aim0933')
    assert(ptac_elec.additionalProperties.getFeatureAsString('CADObjectId').get == '280066-1')
  end

  def test_create_osw
    osw = create_gbxml_test_osw
    osw = add_gbxml_test_measure_steps(osw, 'PTACAllVariations.xml')
    osw_in_path = Config::TEST_OUTPUT_PATH + '/ptac/in.osw'
    osw.saveAs(osw_in_path)
  end

  def test_simulation
    # set osw_path to find location of osw to run
    osw_in_path = Config::TEST_OUTPUT_PATH + '/ptac/in.osw'
    cmd = "\"#{Config::CLI_PATH}\" run -w \"#{osw_in_path}\""
    assert(run_command(cmd))

    osw_out_path = Config::TEST_OUTPUT_PATH + '/ptac/out.osw'
    osw_out = JSON.parse(File.read(osw_out_path))

    assert(osw_out['completed_status'] == 'Success')
  end
end