require_relative 'repositories/peak_load_component_table_repository'
require_relative 'repositories/peak_condition_table_repository'
require_relative 'repositories/engineering_check_table_repository'
require_relative 'repositories/coil_sizing_detail_repository'
require_relative 'system_checksum_peak_load_component_table'
require_relative 'zone_loads_by_component'
require_relative 'system_checksum'
require_relative 'facility_component_load_summary'
require_relative 'design_psychrometric'

class OutputService
  attr_accessor :sql_file, :peak_load_component_table_repository, :peak_condition_table_repository, :engineering_check_table_repository,
                :coil_sizing_detail_repository

  def initialize(sql_file)
    self.peak_load_component_table_repository = PeakLoadComponentTableRepository.new(sql_file)
    self.peak_condition_table_repository = PeakConditionTableRepository.new(sql_file)
    self.engineering_check_table_repository = EngineeringCheckTableRepository.new(sql_file)
    self.coil_sizing_detail_repository = CoilSizingDetailRepository.new(sql_file)
  end

  def get_zone_loads_by_component(name)
    cooling_peak_load_component_table = self.peak_load_component_table_repository.find_by_name_type_and_conditioning(name, 'Zone', 'Cooling')
    heating_peak_load_component_table = self.peak_load_component_table_repository.find_by_name_type_and_conditioning(name, 'Zone', 'Heating')
    cooling_peak_condition_table_repository = self.peak_condition_table_repository.find_by_name_type_and_conditioning(name, 'Zone', 'Cooling')
    heating_peak_condition_table_repository = self.peak_condition_table_repository.find_by_name_type_and_conditioning(name, 'Zone', 'Heating')
    cooling_engineering_check_table = self.engineering_check_table_repository.find_by_name_type_and_conditioning(name, 'Zone', 'Cooling')
    heating_engineering_check_table = self.engineering_check_table_repository.find_by_name_type_and_conditioning(name, 'Zone', 'Heating')

    unless cooling_peak_load_component_table.nil? and heating_peak_load_component_table.nil? and cooling_peak_condition_table_repository.nil? and
        heating_peak_condition_table_repository.nil? and cooling_engineering_check_table.nil? and heating_engineering_check_table.nil?

      zone_loads_by_component = ZoneLoadsByComponent.new
      zone_loads_by_component.cooling_peak_load_component_table = cooling_peak_load_component_table
      zone_loads_by_component.heating_peak_load_component_table = heating_peak_load_component_table
      zone_loads_by_component.cooling_peak_condition_table = cooling_peak_condition_table_repository
      zone_loads_by_component.heating_peak_condition_table = heating_peak_condition_table_repository
      zone_loads_by_component.cooling_engineering_check_table = cooling_engineering_check_table
      zone_loads_by_component.heating_engineering_check_table = heating_engineering_check_table

      zone_loads_by_component
    end
  end

  def get_system_checksum(name, cooling_coil_name = nil, heating_coil_name = nil)
    cooling_peak_load_component_table = self.peak_load_component_table_repository.find_by_name_type_and_conditioning(name, 'AirLoop', 'Cooling')
    heating_peak_load_component_table = self.peak_load_component_table_repository.find_by_name_type_and_conditioning(name, 'AirLoop', 'Heating')
    cooling_peak_condition_table_repository = self.peak_condition_table_repository.find_by_name_type_and_conditioning(name, 'AirLoop', 'Cooling')
    heating_peak_condition_table_repository = self.peak_condition_table_repository.find_by_name_type_and_conditioning(name, 'AirLoop', 'Heating')
    cooling_engineering_check_table = self.engineering_check_table_repository.find_by_name_type_and_conditioning(name, 'AirLoop', 'Cooling')
    heating_engineering_check_table = self.engineering_check_table_repository.find_by_name_type_and_conditioning(name, 'AirLoop', 'Heating')

    unless cooling_peak_load_component_table.nil? and heating_peak_load_component_table.nil? and cooling_peak_condition_table_repository.nil? and
        heating_peak_condition_table_repository.nil? and cooling_engineering_check_table.nil? and heating_engineering_check_table.nil?

      system_checksum = SystemChecksum.new
      if cooling_peak_load_component_table
        extended_cooling_peak_load_component_table = SystemChecksumPeakLoadComponentTable.new(cooling_peak_load_component_table)
        system_checksum.cooling_peak_load_component_table = extended_cooling_peak_load_component_table
      end

      if heating_peak_load_component_table
        extended_heating_peak_load_component_table = SystemChecksumPeakLoadComponentTable.new(heating_peak_load_component_table)
        system_checksum.heating_peak_load_component_table = extended_heating_peak_load_component_table
      end

      system_checksum.cooling_peak_condition_table = cooling_peak_condition_table_repository
      system_checksum.heating_peak_condition_table = heating_peak_condition_table_repository
      system_checksum.cooling_engineering_check_table = cooling_engineering_check_table
      system_checksum.heating_engineering_check_table = heating_engineering_check_table

      cooling_coil_sizing_detail = @coil_sizing_detail_repository.find_by_name(cooling_coil_name) if cooling_coil_name
      heating_coil_sizing_detail = @coil_sizing_detail_repository.find_by_name(heating_coil_name) if heating_coil_name

      system_checksum.cooling_coil_sizing_detail = cooling_coil_sizing_detail if cooling_coil_sizing_detail
      system_checksum.heating_coil_sizing_detail = heating_coil_sizing_detail if heating_coil_sizing_detail

      system_checksum.calculate_additional_results
      system_checksum
    end
  end

  def get_facility_component_load_summary
    facility_component_load_summary = FacilityComponentLoadSummary.new
    name = 'Facility'
    facility_component_load_summary.cooling_peak_load_component_table = self.peak_load_component_table_repository.find_by_name_type_and_conditioning(name, 'Facility', 'Cooling')
    facility_component_load_summary.heating_peak_load_component_table = self.peak_load_component_table_repository.find_by_name_type_and_conditioning(name, 'Facility', 'Heating')
    facility_component_load_summary.cooling_peak_condition_table_repository = self.peak_condition_table_repository.find_by_name_type_and_conditioning(name, 'Facility', 'Cooling')
    facility_component_load_summary.heating_peak_condition_table_repository = self.peak_condition_table_repository.find_by_name_type_and_conditioning(name, 'Facility', 'Heating')
    facility_component_load_summary.cooling_engineering_check_table = self.engineering_check_table_repository.find_by_name_type_and_conditioning(name, 'Facility', 'Cooling')
    facility_component_load_summary.heating_engineering_check_table = self.engineering_check_table_repository.find_by_name_type_and_conditioning(name, 'Facility', 'Heating')

    facility_component_load_summary
  end

  def get_design_psychrometric(name)
    coil_sizing_detail = self.coil_sizing_detail_repository.find_by_name(name)
    DesignPsychrometric.new(coil_sizing_detail) if coil_sizing_detail
  end

  def get_system_component_summary

  end
end