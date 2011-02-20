#--
#
# Author:: Nathaniel Talbott.
# Copyright:: Copyright (c) 2000-2003 Nathaniel Talbott. All rights reserved.
# Copyright:: Copyright (c) 2008-2011 Kouhei Sutou. All rights reserved.
# License:: Ruby license.

require 'test/unit/error'

module Test
  module Unit

    # A collection of tests which can be #run.
    #
    # Note: It is easy to confuse a TestSuite instance with
    # something that has a static suite method; I know because _I_
    # have trouble keeping them straight. Think of something that
    # has a suite method as simply providing a way to get a
    # meaningful TestSuite instance.
    class TestSuite
      attr_reader :name, :tests, :test_case, :start_time

      # Test suite that has higher priority is ran prior to
      # test suites that have lower priority.
      attr_accessor :priority

      STARTED = name + "::STARTED"
      STARTED_OBJECT = name + "::STARTED::OBJECT"
      FINISHED = name + "::FINISHED"
      FINISHED_OBJECT = name + "::FINISHED::OBJECT"

      # Creates a new TestSuite with the given name.
      def initialize(name="Unnamed TestSuite", test_case=nil)
        @name = name
        @tests = []
        @test_case = test_case
        @n_tests = 0
        @priority = 0
        @start_time = nil
        @passed = true
      end

      # Runs the tests and/or suites contained in this
      # TestSuite.
      def run(result, &progress_block)
        @start_time = Time.now
        yield(STARTED, name)
        yield(STARTED_OBJECT, self)
        run_startup(result)
        while test = @tests.shift
          @n_tests += test.size
          test.run(result, &progress_block)
          @passed = false unless test.passed?
        end
        run_shutdown(result)
        yield(FINISHED, name)
        yield(FINISHED_OBJECT, self)
      end

      # Adds the test to the suite.
      def <<(test)
        @tests << test
        self
      end

      def delete(test)
        @tests.delete(test)
      end

      # Retuns the rolled up number of tests in this suite;
      # i.e. if the suite contains other suites, it counts the
      # tests within those suites, not the suites themselves.
      def size
        total_size = @n_tests
        @tests.each { |test| total_size += test.size }
        total_size
      end
      
      def empty?
        tests.empty?
      end

      # Overridden to return the name given the suite at
      # creation.
      def to_s
        @name
      end
      
      # It's handy to be able to compare TestSuite instances.
      def ==(other)
        return false unless(other.kind_of?(self.class))
        return false unless(@name == other.name)
        @tests == other.tests
      end

      def passed?
        @passed
      end

      private
      def run_startup(result)
        return if @test_case.nil? or !@test_case.respond_to?(:startup)
        begin
          @test_case.startup
        rescue Exception
          raise unless handle_exception($!, result)
        end
      end

      def run_shutdown(result)
        return if @test_case.nil? or !@test_case.respond_to?(:shutdown)
        begin
          @test_case.shutdown
        rescue Exception
          raise unless handle_exception($!, result)
        end
      end

      def handle_exception(exception, result)
        case exception
        when *ErrorHandler::PASS_THROUGH_EXCEPTIONS
          false
        else
          result.add_error(Error.new(@test_case.name, exception))
          @passed = false
          true
        end
      end
    end
  end
end
