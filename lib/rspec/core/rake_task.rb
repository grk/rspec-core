require 'rspec/core'
require 'rspec/core/deprecation'
require 'rake'
require 'rake/tasklib'

module RSpec
  module Core
    class RakeTask < ::Rake::TaskLib
      include ::Rake::DSL if defined?(::Rake::DSL)

      # Name of task.
      #
      # default:
      #   :spec
      attr_accessor :name

      # Glob pattern to match files.
      #
      # default:
      #   'spec/**/*_spec.rb'
      attr_accessor :pattern

      # @deprecated
      # Has no effect. The rake task now checks ENV['BUNDLE_GEMFILE'] instead.
      def skip_bundler=(*)
        RSpec.deprecate("RSpec::Core::RakeTask#skip_bundler=")
      end

      # @deprecated
      # Has no effect. The rake task now checks ENV['BUNDLE_GEMFILE'] instead.
      def gemfile=(*)
        RSpec.deprecate("RSpec::Core::RakeTask#gemfile=", 'ENV["BUNDLE_GEMFILE"]')
      end

      # @deprecated
      # Use ruby_opts="-w" instead.
      #
      # When true, requests that the specs be run with the warning flag set.
      # e.g. "ruby -w"
      #
      # default:
      #   false
      def warning=(true_or_false)
        RSpec.deprecate("RSpec::Core::RakeTask#warning=", 'ruby_opts="-w"')
        @warning = true_or_false
      end

      # Whether or not to fail Rake when an error occurs (typically when examples fail).
      #
      # default:
      #   true
      attr_accessor :fail_on_error

      # A message to print to stderr when there are failures.
      attr_accessor :failure_message

      # Use verbose output. If this is set to true, the task will print the
      # executed spec command to stdout.
      #
      # default:
      #   true
      attr_accessor :verbose

      # Use rcov for code coverage?
      #
      # default:
      #   false
      attr_accessor :rcov

      # Path to rcov.
      #
      # default:
      #   'rcov'
      attr_accessor :rcov_path

      # Command line options to pass to rcov.
      #
      # default:
      #   nil
      attr_accessor :rcov_opts

      # Command line options to pass to ruby.
      #
      # default:
      #   nil
      attr_accessor :ruby_opts

      # Path to rspec
      #
      # default:
      #   'rspec'
      attr_accessor :rspec_path

      # Command line options to pass to rspec.
      #
      # default:
      #   nil
      attr_accessor :rspec_opts

      # @deprecated
      # Use rspec_opts instead.
      #
      # Command line options to pass to rspec.
      #
      # default:
      #   nil
      def spec_opts=(opts)
        RSpec.deprecate('RSpec::Core::RakeTask#spec_opts=', 'rspec_opts=')
        @rspec_opts = opts
      end

      def initialize(*args)
        setup_ivars(args)
        yield self if block_given?

        desc "Run RSpec code examples" unless ::Rake.application.last_comment

        task name do
          RakeFileUtils.send(:verbose, verbose) do
            run_task verbose
          end
        end
      end

      def setup_ivars(args)
        @name = args.shift || :spec
        @rcov_opts, @ruby_opts, @rspec_opts = nil, nil, nil
        @warning, @rcov = false, false
        @verbose, @fail_on_error = true, true

        @rcov_path  = 'rcov'
        @rspec_path = 'rspec'
        @pattern    = './spec{,/*/**}/*_spec.rb'
      end

      def has_files?
        empty = files_to_run.empty?
        puts "No examples matching #{pattern} could be found" if empty
        not empty
      end

      def run_task(verbose)
        files = has_files?
        if files
          begin
            puts spec_command if verbose
            success = system(spec_command)
          rescue
            puts failure_message if failure_message
          end
          raise("#{spec_command} failed") if fail_on_error unless success
        end
      end

    private

      def files_to_run
        if ENV['SPEC']
          FileList[ ENV['SPEC'] ].sort
        else
          FileList[ pattern ].sort.map { |f| f.gsub(/"/, '\"').gsub(/'/, "\\\\'") }
        end
      end

      def spec_command
        @spec_command ||= default_spec_command
      end

      def default_spec_command
        cmd_parts = []
        cmd_parts << RUBY
        cmd_parts << ruby_opts
        cmd_parts << "-w" if @warning
        cmd_parts << "-S" << runner
        cmd_parts << "-Ispec:lib" << rcov_opts if rcov
        cmd_parts << files_to_run
        cmd_parts << "--" if rcov && rspec_opts
        cmd_parts << rspec_opts
        cmd_parts.flatten.reject(&blank).join(" ")
      end

      def runner
        rcov ? rcov_path : rspec_path
      end

      def blank
        lambda {|s| s.nil? || s == ""}
      end
    end
  end
end
