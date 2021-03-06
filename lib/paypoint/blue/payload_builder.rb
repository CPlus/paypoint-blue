module PayPoint
  module Blue
    # Provides helper methods for payload construction used throughout
    # the API. It allows definition of payload shortcuts and default
    # values.
    module PayloadBuilder
      def self.included(base)
        base.extend ClassMethods
      end

      # Class level methods for PayloadBuilder.
      module ClassMethods
        def shortcuts
          @shortcuts ||= {}
        end

        attr_writer :shortcuts

        # Define a payload shortcut
        #
        # Shortcuts help payload construction by defining short aliases
        # to commonly used paths.
        #
        # @example Define and use a shortcut
        #   class PayPoint::Blue::Hosted
        #     shortcut :amount, "transaction.money.amount.fixed"
        #   end
        #   blue.make_payment(amount: "3.49", ...)
        #     # this will be turned into
        #     # { transaction: { money: { amount: { fixed: "3.49" } } } }
        #
        # @param [Symbol] key the shortcut key
        # @param [String] path a path into the payload with segments
        #   separated by dots (e.g. +'transaction.money.amount.fixed'+)
        def shortcut(key, path = nil)
          if path.nil?
            shortcuts[key]
          else
            shortcuts[key] = path
          end
        end
      end

      attr_accessor :defaults

      # Builds the payload by applying default values and replacing
      # shortcuts
      #
      # @note When using the callback and notification shortcuts, the
      # builder will also default their +format+ to +'REST_JSON'+,
      # because the PayPoint API requires it in _some_ cases. If your
      # endpoints expect XML, you won't be able to use these shortcuts.
      #
      # @param [Hash] payload the original payload using shortcuts
      # @param [Array<Symbol>] defaults an array of symbols for defaults
      #   that should be applied to this payload
      def build_payload(payload, defaults: [])
        apply_defaults(payload, defaults)
        expand_shortcuts(payload)
      end

      private

      def apply_defaults(payload, applicable_defaults)
        return unless defaults

        defaults.each do |key, value|
          if applicable_defaults.include?(key) && !payload.key?(key)
            payload[key] = interpolate_values(value, payload)
          end
        end
      end

      def interpolate_values(value, payload)
        value.gsub(/%(\w+)%/) { |m| payload[Regexp.last_match(1).to_sym] || m }
      end

      def expand_shortcuts(payload)
        payload.keys.each do |key|
          next unless (path = self.class.shortcut(key))
          expand_shortcut(payload, key, path)
        end
        payload
      end

      def expand_shortcut(payload, key, path)
        value = payload.delete(key)
        segments = path.split(".").map(&:to_sym)
        leaf = segments.pop
        leaf_parent = segments.reduce(payload) { |a, e| a[e] ||= {} }
        leaf_parent[leaf] ||= value

        callback_re = /_(?:callback|notification)\Z/
        leaf_parent[:format] ||= "REST_JSON" if key =~ callback_re
      end
    end
  end
end
