module Cord
  module Helpers
    extend ActiveSupport::Concern

    included do
      undelegated_methods = methods

      class << self
        def is_api? obj
          obj.is_a?(Class) && obj < Cord::BaseApi
        end

        def find_api value
          api = (value.to_s.camelcase.chomp('Api').pluralize + 'Api').constantize
          raise NameError, "#{api} is not a Cord Api" unless is_api?(api)
          api
        end

        def is_model? obj
          obj.is_a?(Class) && obj < ActiveRecord::Base
        end

        def is_driver? obj
          obj.is_a?(ActiveRecord::Relation)
        end

        def normalize str
          str.to_s.downcase
        end

        def apply_scope driver, name, scope
          raise ArgumentError, 'expected an ActiveRecord::Relation' unless is_driver?(driver)
          result = instance_exec(driver, &scope)
          unless is_driver?(result)
            raise ArgumentError, "scope '#{name}' did not return an ActiveRecord::Relation"
          end
          result
        end

        def apply_sort(driver, sort)
          col, dir = sort.downcase.split(' ')
          unless dir.in?(%w[asc desc])
            error "sort direction must be either 'asc' or 'desc', instead got '#{dir}'"
            return driver
          end
          if col.in?(model.column_names)
            driver.order(col => dir)
          else
            error "unknown sort #{col}"
            driver
          end
        end

        def apply_search(driver, search, columns = [])
          condition = columns.map { |col| "#{col} ILIKE :term" }.join ' OR '
          driver.where(condition, term: "%#{search}%")
        end
      end

      delegate *(methods - undelegated_methods), to: :class

      def self.load_api value
        api = value if is_api?(value)
        api ||= find_api(value)
        api.new
      end

      def load_api value
        api = value if is_api?(value)
        api ||= find_api(value)

        controller_instance = controller if is_api?(self)
        controller_instance = self if is_a?(ApiBaseController)

        api.new(controller_instance)
      end
    end
  end
end
