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
    
    def with_punctuation!
      "punctuated"
    end
    
    def some_method_with_arguments(times, shout="boom")
      shout * times
    end
    
    def some_method_with_block
      yield @hits+=1
    end
    
    def self.some_classy
      "classy"
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
  
  test "track! - with a class" do
    Stubble.add_stubble!(StubThis)
    
    StubThis.track!(:some_classy)
    StubThis.some_classy
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
  
  test "we can stub! punctuated methods" do
    this = StubThis.new
    assert_equal "punctuated", this.with_punctuation!
    
    Stubble.add_stubble!(this)
    this.stub!(:with_punctuation!, [:a, :b, :c])
    
    assert_equal :a, this.with_punctuation!
    assert_equal :b, this.with_punctuation!
    assert_equal :c, this.with_punctuation!
    
    assert_equal "punctuated", this.with_punctuation!
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
  
  test "stub! - with a class" do
    Stubble.add_stubble!(StubThis)
    
    assert_equal "classy", StubThis.some_classy
    StubThis.stub!(:some_classy, ["purple"])
    assert_equal "purple", StubThis.some_classy
    assert_equal "classy", StubThis.some_classy
  end
  
  test "stub! - can be done progressively" do
    this = StubThis.new
    assert_equal 1, this.some_method
    
    Stubble.add_stubble!(this)
    this.stub!(:some_method, [:a])
    this.stub!(:some_method, [:b, :c])
    
    assert_equal :a, this.some_method
    assert_equal :b, this.some_method
    assert_equal :c, this.some_method
    
    assert_equal 2, this.some_method
  end
  
  class SomeMagicError < RuntimeError ; end
  
  test "raise!" do
     this = StubThis.new
     assert_equal 1, this.some_method

     Stubble.add_stubble!(this)
     this.raise!(:some_method, SomeMagicError)
     
     assert_raise(SomeMagicError) do
       this.some_method
     end

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