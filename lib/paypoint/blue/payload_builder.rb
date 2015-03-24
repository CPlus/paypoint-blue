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
      end

      attr_accessor :defaults

      def build_payload(payload, defaults: [])
        apply_defaults(payload, defaults)
        payload.keys.each do |key|
          if path = self.class.shortcut(key)
            value = payload.delete(key)
            segments = path.split('.').map(&:to_sym)
            leaf = segments.pop
            leaf_parent = segments.reduce(payload) {|h,k| h[k] ||= {}}
            leaf_parent[leaf] ||= value
          end
        end
        payload
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
