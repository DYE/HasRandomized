module ActiveRecord
    module HasRandomized
        def self.included(base)
            base.send :extend, ClassMethods
        end

        module ClassMethods
            def has_randomized(fields, options = {})
                configurations = { :method => :hex }
                configurations.update(options)

                configurations[:fields] = fields.is_a?(Array) ? fields : [fields]
                configurations[:fields].each do |field|

                # create dynamic methods to generate new random strings
                    method = case configurations[:method]
                    when :integer
                        "rand(10 ** #{configurations[:length] || 8})"
                    when :hex
                        "ActiveSupport::SecureRandom.hex(#{configurations[:length] || 16})"
                    end

                    class_eval <<-CLASS_EVAL, __FILE__, __LINE__ + 1
                        def _generate_#{field}
                          begin
                            random = #{method}
                            used = #{configurations[:class_name] || self.class}.find_all_by_#{field}(random)
                          end while used.count > 0

                          self.#{field} = random
                        end

                        # privatize the method
                        private :_generate_#{field}

                    CLASS_EVAL

                end # of each
            end # of has_randomized
        end # of ClassMethods
    end # of HasRandomized
end # of ActiveRecord

#ActiveRecord::Base.send :include, ActiveRecord::HasRandomized