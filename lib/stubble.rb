require 'set'
require 'active_support/core_ext/kernel/singleton_class'
require 'active_support/core_ext/module/aliasing'
require 'active_support/core_ext/object/blank'

module Stubble
  
  class Catcher
    
    def initialize()
      @calls = {}
      @stubs = {}
      @tracking = Set.new
    end
    
    def called!(method_name, args, block)
      if @tracking.include?(method_name)
        @calls[method_name]
        @calls[method_name] << [args, !block.nil?]
        if @stubs[method_name].present?
          @stubs[method_name].shift
        end
      end
    end
    
    def track!(method_name)
      @calls[method_name] = []
      @tracking << method_name
    end
    
    def untrack!(method_name)
      @tracking.delete(method_name)
    end
    
    def raise!(method_name, exception)
      @stubs[method_name] ||= []
      @stubs[method_name] << RaiseStub.new(exception)
    end
    
    def stub!(method_name, value)
      @stubs[method_name] ||= []
      @stubs[method_name] << ReturnStub.new(value)
    end
    
    def unstub!(method_name)
      @stubs[method_name] = nil
    end
    
    def [](method_name)
      @calls[method_name]
    end
    
  end
  
  def add_stubble!(object)
    object.instance_eval do
      @stubble = Stubble::Catcher.new
    end
    object.extend StubMethods
    def object._stubble
      @stubble
    end
  end
  module_function :add_stubble!
  
  class ReturnStub
    def initialize(value)
      @value = value
    end
    
    def perform
      return @value
    end
  end
  
  class RaiseStub
    def initialize(exception)
      @exception = exception
    end
    
    def perform
      raise @exception
    end
  end
  
  module StubMethods
    
    def track!(method_name)
      self._stubble.track!(method_name)

      unstubbled_method_name = "__unstubbled__#{method_name}"
      unless methods.include?(unstubbled_method_name)
        instance_eval <<-RUBY
          alias #{unstubbled_method_name} #{method_name} 
          def #{method_name}(*args, &block)
            if stubbed_return = self._stubble.called!(#{method_name.inspect}, args, block)
              stubbed_return.perform
            else
              #{unstubbled_method_name}(*args, &block)
            end
          end
        RUBY
      end
    end
    
    def untrack!(method_name)
      self._stubble.untrack!(method_name)
    end
    
    def stub!(method_name, values)
      track!(method_name)
      values.each do |value|
        self._stubble.stub!(method_name, value)
      end
    end
    
    def raise!(method_name, exception)
      track!(method_name)
      
      self._stubble.raise!(method_name, exception)
    end
    
    def unstub!(method_name)
      self._stubble.unstub!(method_name)
    end
    
  end
      
end