require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options
  # has_one_through :home, :human, :house
  # belongs_to :human, :foreign_key => :owner_id
  def has_one_through(name, through_name, source_name)
      #self = Cat
      #through_options.model_class = Human
      define_method(name) do
        through_options = self.class.assoc_options[through_name]
        source_options =
        through_options.model_class.assoc_options[source_name]
        source_table = source_options.table_name
        through_table = through_options.table_name
        source_fk = source_options.foreign_key

        owner = self.send(through_options.foreign_key)
        

        results = DBConnection.execute(<<-SQL, owner)
          SELECT 
            #{source_table}.*
          FROM 
            #{through_table}
          JOIN 
            #{source_table} ON #{through_table}.#{source_fk} = #{source_table}.id
          WHERE 
            #{through_table}.id = ?
        SQL

        source_options.model_class.new(results.first)
        
      end
  end
end

class Cat < SQLObject
      belongs_to :human, foreign_key: :owner_id
      has_one_through :home, :human, :house

      finalize!
    end

    class Human < SQLObject
      self.table_name = 'humans'

      has_many :cats, foreign_key: :owner_id
      belongs_to :house

      finalize!
    end

    class House < SQLObject
      has_many :humans

      finalize!
    end

     cat = Cat.find(1)

    p cat.home

   