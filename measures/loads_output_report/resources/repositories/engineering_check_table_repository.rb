require_relative '../engineering_check_table'

class EngineeringCheckTableRepository
  attr_accessor :sql_file

  BASE_QUERY = "SELECT Value FROM TabularDataWithStrings"
  PARAM_MAP = [
      {:db_name => 'Outside Air (%)', :param_name => 'oa_percent', :param_type => 'double'},
      {:db_name => 'Airflow per Floor Area', :param_name => 'airflow_per_floor_area', :param_type => 'double'},
      {:db_name => 'Airflow per Total Capacity', :param_name => 'airflow_per_total_cap', :param_type => 'double'},
      {:db_name => 'Floor Area per Total Capacity', :param_name => 'floor_area_per_total_cap', :param_type => 'double'},
      {:db_name => 'Total Capacity per Floor Area', :param_name => 'total_cap_per_floor_area', :param_type => 'double'},
      {:db_name => 'Number of People', :param_name => 'number_of_people', :param_type => 'double'}
  ]
  def initialize(sql_file)
    self.sql_file = sql_file
  end

  # @param name [String] the name of the object
  # @param type [String] either "Zone", "AirLoop" or "Facility"
  # @param conditioning [String] either "Cooling" or "Heating"
  def find_by_name_type_and_conditioning(name, type, conditioning)
    names_query = "SELECT DISTINCT UPPER(ReportForString) From TabularDataWithStrings WHERE ReportName == '#{type} Component Load Summary'
                        AND TableName == 'Engineering Checks for #{conditioning}'"
    names = @sql_file.execAndReturnVectorOfString(names_query).get

    if names.include? name.upcase
      component_query = BASE_QUERY + " WHERE ReportName = '#{type} Component Load Summary' AND TableName =
            'Engineering Checks for #{conditioning}' AND UPPER(ReportForString) = '#{name.upcase}'"
      params = {}

      PARAM_MAP.each do |param|
        query = component_query + " AND RowName == '#{param[:db_name]}'"
        params[param[:param_name].to_sym] = get_optional_value(param[:param_type], query)
      end

      EngineeringCheckTable.new(params)
    end
  end

  def get_optional_value(param_type, query)
    if param_type == 'string'
      result = self.sql_file.execAndReturnFirstString(query)
    elsif param_type == 'double'
      result = self.sql_file.execAndReturnFirstDouble(query)
    end

    if result.is_initialized
      result = result.get
    else
      result = nil
    end

    return result
  end
end