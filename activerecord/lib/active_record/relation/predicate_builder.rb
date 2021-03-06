module ActiveRecord
  class PredicateBuilder # :nodoc:
    def self.build_from_hash(engine, attributes, default_table)
      predicates = attributes.map do |column, value|
        table = default_table

        if value.is_a?(Hash)
          table = Arel::Table.new(column, :engine => engine)
          build_from_hash(engine, value, table)
        else
          column = column.to_s

          if column.include?('.')
            table_name, column = column.split('.', 2)
            table = Arel::Table.new(table_name, :engine => engine)
          end

          attribute = table[column.to_sym]

          case value
          when ActiveRecord::Relation
            value.select_values = [value.klass.arel_table['id']] if value.select_values.empty?
            attribute.in(value.arel.ast)
          when Array, ActiveRecord::Associations::AssociationCollection
            values = value.to_a.map { |x|
              x.is_a?(ActiveRecord::Base) ? x.id : x
            }
            attribute.in(values)
          when Range, Arel::Relation
            attribute.in(value)
          when ActiveRecord::Base
            attribute.eq(value.id)
          when Class
            # FIXME: I think we need to deprecate this behavior
            attribute.eq(value.name)
          else
            attribute.eq(value)
          end
        end
      end

      predicates.flatten
    end
  end
end
