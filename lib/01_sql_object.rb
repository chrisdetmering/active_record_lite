require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
   return @columns if @columns

      cols = DBConnection.execute2(<<-SQL).first
        SELECT 
          * 
        FROM 
          #{self.table_name}
      SQL
      @columns = cols.map(&:to_sym)

  end

  def self.finalize!
    #[:id, :name. :owner_id]
    columns.each do |col| 
      define_method(col) do 
        self.attributes[col]
      end 

      define_method("#{col}=") do |value|
        self.attributes[col] = value
      end

    end 
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
      @table_name || self.name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT 
        * 
      FROM 
        #{self.table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end 
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id).first
      SELECT 
        * 
      FROM 
        #{self.table_name}
      WHERE 
        id = ?
      SQL

    return self.new(result) unless result.nil?
  end

  def initialize(params = {})
    params.each do |attr_name, attr_value| 
      attr_sym = attr_name.to_sym
        if self.class.columns.include?(attr_sym)
          self.send("#{attr_name}=", attr_value)
        else 
          raise "unknown attribute '#{attr_name}'" 
        end
    end 
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map do |column| 
      self.send(column)
    end 
  end

  def insert
    columns = self.class.columns.drop(1)
    col_names = columns.join(",")
    question_marks = (['?'] * columns.count).join(",")

      DBConnection.execute(<<-SQL, *attribute_values.drop(1))
        INSERT INTO 
          #{self.class.table_name} (#{col_names})
        VALUES 
          (#{question_marks})
      SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    columns = self.class.columns
    col_names = columns.map {|attr| "#{attr} = ?"}.join(",")
    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE 
        #{self.class.table_name}
      SET 
        #{col_names}
      WHERE 
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    id.nil? ? insert : update 
  end
end


