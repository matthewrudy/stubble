require 'test_helper'
require 'stubble'

class StubbleTest < Test::Unit::TestCase
  
  extend ActiveSupport::Testing::Declarative
  
  class StubThis
    
    def initialize
      @hits = 0
    end
    attr_reader :hits
    
    def some_method
      @hits +=1
    end
    
    def some_method_with_arguments(times, shout="boom")
      shout * times
    end
    
    def some_method_with_block
      yield @hits+=1
    end
    
  end
  
  test "stubble is added on an individual basis" do
    one = StubThis.new
    two = StubThis.new
    
    Stubble.add_stubble!(one)
    assert one.respond_to?(:_stubble)
    assert !two.respond_to?(:_stubble)
  end
  
  test "track! - tracks, but doesnt affect the function" do
    this = StubThis.new
    assert_equal 1, this.some_method
    
    Stubble.add_stubble!(this)
    this.track!(:some_method)
    
    assert_equal 2, this.some_method
    assert_equal 3, this.some_method
    
    assert_equal [[[],false]]*2, this._stubble[:some_method]
  end
  
  test "track! - tracks arguments" do
    this = StubThis.new
    assert_equal "boom", this.some_method_with_arguments(1)
    
    Stubble.add_stubble!(this)
    this.track!(:some_method_with_arguments)
    
    assert_equal "boomboom", this.some_method_with_arguments(2)
    assert_equal "purple",  this.some_method_with_arguments(1, "purple")
    
    assert_equal [[[2],false], [[1,"purple"],false]], this._stubble[:some_method_with_arguments]
  end
  
  test "track! - tracks blocks" do
    this = StubThis.new

    this.some_method_with_block do |val|
      assert_equal 1, val
    end
    
    Stubble.add_stubble!(this)
    this.track!(:some_method_with_block)
    
    this.some_method_with_block do |val|
      assert_equal 2, val
    end
    this.some_method_with_block do |val|
      assert_equal 3, val
    end
    
    assert_equal [[[],true], [[],true]], this._stubble[:some_method_with_block]
  end
  
  test "track! - can be called multiple times" do
    this = StubThis.new
    assert_equal 1, this.some_method
    
    Stubble.add_stubble!(this)
    this.track!(:some_method)
    this.track!(:some_method)
    
    assert_equal 2, this.some_method
  end
  
  test "untrack! - undoes a track" do
    this = StubThis.new
    assert_equal 1, this.some_method
    
    Stubble.add_stubble!(this)
    this.track!(:some_method)
    
    assert_equal 2, this.some_method
    assert_equal 1, this._stubble[:some_method].length
    
    this.untrack!(:some_method)
    
    assert_equal 3, this.some_method
    assert_equal 1, this._stubble[:some_method].length # no new
  end
  
  test "stub! - defines the next values to be returned" do
    this = StubThis.new
    assert_equal 1, this.some_method
    
    Stubble.add_stubble!(this)
    this.stub!(:some_method, [:a, :b, :c])
    
    assert_equal :a, this.some_method
    assert_equal :b, this.some_method
    assert_equal :c, this.some_method
    
    assert_equal 2, this.some_method
  end
  
  test "unstub! - cancels a stub" do
    this = StubThis.new
    assert_equal 1, this.some_method
    
    Stubble.add_stubble!(this)
    this.stub!(:some_method, [:a, :b, :c])
    
    assert_equal :a, this.some_method
    
    this.unstub!(:some_method)
    
    assert_equal 2, this.some_method
    assert_equal 3, this.some_method
  end
end