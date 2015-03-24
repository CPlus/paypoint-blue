module PayPoint
  module Blue
    module PayloadBuilder

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        attr_accessor :shortcuts

        def shortcut(key, path=nil)
          if path.nil?
            shortcuts && shortcuts[key]
          else
            self.shortcuts ||= {}
            shortcuts[key] = path
          end
        end

        def build_payload(payload)
          payload.keys.each do |key|
            if path = shortcut(key)
              segments = path.split('.').map(&:to_sym)
              leaf = segments.pop
              leaf_parent = segments.reduce(payload) {|h,k| h[k] ||= {}}
              leaf_parent[leaf] ||= payload.delete(key)
            end
          end
          payload
        end
      end

      attr_accessor :defaults

      def build_payload(payload, defaults: [])
        apply_defaults(payload, defaults)
        self.class.build_payload(payload)
      end

      private

      def apply_defaults(payload, applicable_defaults)
        return unless defaults

        defaults.each do |key, value|
          if applicable_defaults.include?(key) && !payload.has_key?(key)
            payload[key] = value
          end
        end
      end

    end
  end
end
