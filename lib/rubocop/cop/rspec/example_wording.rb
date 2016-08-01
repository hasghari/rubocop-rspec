# frozen_string_literal: true

module RuboCop
  module Cop
    module RSpec
      # Do not use should when describing your tests.
      # see: http://betterspecs.org/#should
      #
      # The autocorrect is experimental - use with care! It can be configured
      # with CustomTransform (e.g. have => has) and IgnoredWords (e.g. only).
      #
      # @example
      #   # bad
      #   it 'should find nothing' do
      #   end
      #
      #   # good
      #   it 'finds nothing' do
      #   end
      class ExampleWording < Cop
        MSG = 'Do not use should when describing your tests.'.freeze

        def on_block(node) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength,Metrics/LineLength
          method, = *node
          _, method_name, *args = *method

          return unless method_name.equal?(:it)

          arguments = args.first.to_a
          message = arguments.first.to_s
          return unless message.downcase.start_with?('should')

          arg1 = args.first.loc.expression
          message = Parser::Source::Range.new(arg1.source_buffer,
                                              arg1.begin_pos + 1,
                                              arg1.end_pos - 1)

          add_offense(message, message)
        end

        def autocorrect(range)
          lambda do |corrector|
            corrector.replace(
              range,
              Corrector.new(
                range,
                ignore: ignored_words,
                replace: custom_transform
              ).to_s
            )
          end
        end

        private

        def custom_transform
          cop_config['CustomTransform'] || []
        end

        def ignored_words
          cop_config['IgnoredWords'] || []
        end

        class Corrector
          def initialize(range, ignore:, replace:)
            @range        = range
            @ignores      = ignore
            @replacements = replace
          end

          def to_s
            range.source.split(' ').tap do |words|
              first_word = words.shift
              words.unshift('not') if first_word == "shouldn't"

              words.each_with_index do |value, key|
                next if ignores.include?(value)
                words[key] = simple_present(words[key])
                break
              end
            end.join(' ')
          end

          private

          attr_reader :range, :ignores, :replacements

          def simple_present(word)
            return replacements[word] if replacements[word]

            # ends with o s x ch sh or ss
            if %w(o s x]).include?(word[-1]) ||
                %w(ch sh ss]).include?(word[-2..-1])
              return "#{word}es"
            end

            # ends with y
            if word[-1] == 'y' && !%w(a u i o e).include?(word[-2])
              return "#{word[0..-2]}ies"
            end

            "#{word}s"
          end
        end
      end
    end
  end
end
