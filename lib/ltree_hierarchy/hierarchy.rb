module Ltree
  module Hierarchy
    def has_ltree_hierarchy
      belongs_to :parent, :class_name => self.name

      scope :roots, where(:parent_id => nil)

      validate :prevent_circular_paths, :if => :parent_id_changed?

      after_create  :commit_path
      before_update :assign_path, :cascade_path_change, :if => :parent_id_changed?

      include InstanceMethods
    end

    def at_depth(depth)
      where(['nlevel(path) = ?', depth])
    end

    def leaves
      where("id NOT IN(#{select('DISTINCT parent_id').to_sql})")
    end

    def lowest_common_ancestor_paths(paths)
      sql = if paths.respond_to?(:to_sql)
        "SELECT lca(array(#{paths.to_sql}))"
      else
        return [] if paths.empty?
        safe_paths = paths.map { |p| "#{connection.quote(p)}::ltree" }
        "SELECT lca(ARRAY[#{safe_paths.join(', ')}])"
      end
      connection.select_values(sql)
    end

    def lowest_common_ancestors(paths)
      where(:path => lowest_common_ancestor_paths(paths))
    end

    module InstanceMethods
      def prevent_circular_paths
        if parent && parent.path.split('.').include?(id.to_s)
          errors.add(:parent_id, :invalid)
        end
      end

      def ltree_scope
        self.class.base_class
      end

      def compute_path
        if parent
          "#{parent.path}.#{id}"
        else
          id.to_s
        end
      end

      def assign_path
        self.path = compute_path
      end

      def commit_path
        update_column(:path, compute_path)
      end

      def cascade_path_change
        # Equivalent to:
        #  UPDATE whatever
        #  SET    path = NEW.path || subpath(path, nlevel(OLD.path))
        #  WHERE  path <@ OLD.path AND id != NEW.id;
        ltree_scope.update_all(
          ['path = :new_path || subpath(path, nlevel(:old_path))', :new_path => path, :old_path => path_was],
          ['path <@ :old_path AND id != :id', :old_path => path_was, :id => id]
        )
      end

      def root?
        if parent_id
          false
        else
          parent.nil?
        end
      end

      def leaf?
        !children.any?
      end

      def depth # 1-based, for compatibility with ltree's nlevel().
        if root?
          1
        elsif path
          path.split('.').length
        elsif parent
          parent.depth + 1
        end
      end

      def ancestors
        ltree_scope.where('path @> ? AND id != ?', path, id)
      end

      def self_and_ancestors
        ltree_scope.where('path @> ?', path)
      end
      alias :and_ancestors :self_and_ancestors

      def siblings
        ltree_scope.where('parent_id = ? AND id != ?', parent_id, id)
      end

      def self_and_siblings
        ltree_scope.where('parent_id = ?', parent_id)
      end
      alias :and_siblings :self_and_siblings

      def descendents
        ltree_scope.where('path <@ ? AND id != ?', path, id)
      end

      def self_and_descendents
        ltree_scope.where('path <@ ?', path)
      end
      alias :and_descendents :self_and_descendents

      def children
        ltree_scope.where('parent_id = ?', id)
      end

      def self_and_children
        ltree_scope.where('id = :id OR parent_id = :id', :id => id)
      end
      alias :and_children :self_and_children

      def leaves
        descendents.leaves
      end
    end
  end
end
