module PayPoint
  module Blue
    module PayloadBuilder

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
            leaf_parent[leaf] = payload.delete(key)
          end
        end
        payload
      end

    end
  end
end
