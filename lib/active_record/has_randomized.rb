module ActiveRecord
    module HasRandomized
        def self.included(base)
            base.send :extend, ClassMethods
        end
        
        class InvalidRandomizerMethod < StandardError; end

        module ClassMethods
            def has_randomized(fields, options = {})
                configurations = { :method => :hex, :unique => false, :class_name => self.class, :length => 8 }
                configurations.update(options)

                configurations[:fields] = fields.is_a?(Array) ? fields : [fields]
                configurations[:fields].each do |field|

                # create dynamic methods to generate new random strings
                    method = case configurations[:method]
                    when :integer
                        "rand(10 ** #{configurations[:length]})"
                    when :hex
                        "ActiveSupport::SecureRandom.hex(#{configurations[:length]})"
                    else
                        raise ::InvalidRandomizerMethod, "Valid methods include :integer, :hex"
                    end

                    class_eval <<-CLASS_EVAL, __FILE__, __LINE__ + 1
                        define_method("randomize_#{field}".to_sym) do
                          begin
                            random = #{method}
                            used = #{configurations[:class_name]}.find_all_by_#{field}(random)
                          end while used.count > 0

                          self.#{field} = random
                        end

                        # privatize the method
                        private :randomize_#{field}

                    CLASS_EVAL

                end # of each
            end # of has_randomized
        end # of ClassMethods
    end # of HasRandomized
end # of ActiveRecord

#ActiveRecord::Base.send :include, ActiveRecord::HasRandomized