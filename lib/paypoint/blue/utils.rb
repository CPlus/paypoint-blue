module PayPoint
  module Blue
    module Utils
      extend self

      def snakecase_and_symbolize_keys(hash)
        case hash
        when Hash
          hash.each_with_object({},) do |(key, value), snakified|
            snakified[snakecase(key)] = snakecase_and_symbolize_keys(value)
          end
        when Enumerable
          hash.map { |v| snakecase_and_symbolize_keys(v) }
        else
          hash
        end
      end

      def camelcase_and_symbolize_keys(hash)
        case hash
        when Hash
          hash.each_with_object({},) do |(key, value), camelized|
            camelized[camelcase(key)] = camelcase_and_symbolize_keys(value)
          end
        when Enumerable
          hash.map { |v| camelcase_and_symbolize_keys(v) }
        else
          hash
        end
      end

      private

      def snakecase(original)
        string = original.is_a?(Symbol) ? original.to_s : original.dup
        string.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
        string.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
        string.downcase!
        string.to_sym
      end

      def camelcase(original)
        string = original.is_a?(Symbol) ? original.to_s : original.dup
        string.gsub!(/_([a-z\d]*)/) { Regexp.last_match(1).capitalize }
        string.to_sym
      end
    end
  end
end
