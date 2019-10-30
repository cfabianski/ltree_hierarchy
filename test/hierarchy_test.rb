require "rubygems"
require "active_record"
require "minitest/autorun"

require "ltree_hierarchy"

class DefaultTreeNode < ActiveRecord::Base
  has_ltree_hierarchy
end

class TreeNode < ActiveRecord::Base
  has_ltree_hierarchy fragment: :fragment, parent_fragment: :parent_fragment, path: :materialized_path
end

class HierarchyTest < MiniTest::Unit::TestCase
  def setup
    db_config = YAML.load(File.open(File.join(File.dirname(__FILE__), "database.yml")).read)["test"]

    ActiveRecord::Base.establish_connection(db_config)

    unless TreeNode.connection.select_value("SELECT proname FROM pg_proc WHERE proname = 'nlevel'")
      pgversion = TreeNode.connection.send(:postgresql_version)
      if pgversion < 90100
        pg_sharedir = `pg_config --sharedir`.strip
        ltree_script_path = File.join(pg_sharedir, "contrib", "ltree.sql")
        TreeNode.connection.execute(File.read(ltree_script_path))
      else
        TreeNode.connection.execute("CREATE EXTENSION ltree")
      end
    end

    TreeNode.connection.create_table(:tree_nodes, primary_key: :fragment, force: true) do |t|
      t.integer :parent_fragment
      t.column :materialized_path, "ltree"
      t.timestamps null: false
    end
  end

  def test_sensible_default_configuration
    assert_equal DefaultTreeNode.ltree_fragment_column, :id
    assert_equal DefaultTreeNode.ltree_parent_fragment_column, :parent_id
    assert_equal DefaultTreeNode.ltree_path_column, :path
  end

  def test_add_a_root_node
    root = TreeNode.create
    assert root.persisted?
  end

  def test_sets_path_upon_creation
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    assert_equal "#{root.fragment}.#{child.fragment}", child.materialized_path
  end

  def test_cascades_path_changes_through_descendants
    acme_corp = TreeNode.create!
    uk = TreeNode.create!(parent: acme_corp)
    london = TreeNode.create!(parent: uk)

    # Insert intermediate TreeNode.
    emea = TreeNode.create!(parent: acme_corp)
    uk.update_attributes!(parent: emea)

    london.reload
    assert_equal "#{acme_corp.fragment}.#{emea.fragment}.#{uk.fragment}.#{london.fragment}", london.materialized_path
  end

  def test_prevents_circular_references
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    root.parent = child
    assert !root.save
    assert_equal "is invalid", root.errors[:parent_fragment].join
  end

  def test_finds_roots
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    assert_equal [root], TreeNode.roots.to_a
  end

  def test_root_returns_true_on_root
    root = TreeNode.create!
    assert root.root?
  end

  def test_root_returns_first_item
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: child1)

    assert_equal root, child2.root
  end

  def test_root_returns_false_on_non_root
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    assert !child.root?
  end

  def test_leaf_returns_false_on_non_leaf
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    assert !root.leaf?
  end

  def test_leaf_returns_true_on_leaf
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    assert child.leaf?
  end

  def test_depth_on_root_returns_one
    root = TreeNode.create!
    assert_equal 1, root.depth
  end

  def test_depth_on_descendent
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    assert_equal 2, child.depth
  end

  def test_depth_when_not_yet_persisted
    root = TreeNode.new
    child = TreeNode.new(parent: root)
    grandchild = TreeNode.new(parent: child)
    assert_equal 3, grandchild.depth
  end

  def test_finds_ancestors
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    assert_equal [root], child.ancestors.to_a
  end

  def test_finds_self_and_ancestors
    root = TreeNode.create!
    child = TreeNode.create!(parent: root)
    assert_equal [root, child], child.and_ancestors
  end

  def test_finds_siblings
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: root)
    child3 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)

    assert_equal [child2, child3], child1.siblings.order(:created_at).to_a
  end

  def test_finds_self_and_siblings
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: root)
    child3 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)

    assert_equal [child1, child2, child3], child1.and_siblings.order(:created_at).to_a
  end

  def test_finds_children
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: root)
    child3 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)

    assert_equal [child1, child2, child3], root.children.order(:created_at).to_a
  end

  def test_finds_self_and_children
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: root)
    child3 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)

    assert_equal [root, child1, child2, child3], root.and_children.order(:created_at).to_a
  end

  def test_finds_descendants
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: root)
    child3 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)

    assert_equal [child1, child2, child3, grandchild1], root.descendants.order(:created_at).to_a
  end

  def test_finds_self_and_descendants
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: root)
    child3 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)

    assert_equal [root, child1, child2, child3, grandchild1], root.and_descendants.order(:created_at).to_a
  end

  def test_finds_nodes_at_depth
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: root)
    child3 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)

    assert_equal [grandchild1], root.descendants.at_depth(3)
  end

  def test_finds_leaves
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    child2 = TreeNode.create!(parent: root)
    child3 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)

    assert_equal [child2, child3, grandchild1], root.descendants.leaves.order(:created_at).to_a
  end

  def test_finds_all_leaves
    root1 = TreeNode.create!
    child1 = TreeNode.create!(parent: root1)
    child2 = TreeNode.create!(parent: root1)
    child3 = TreeNode.create!(parent: root1)
    grandchild1 = TreeNode.create!(parent: child1)
    root2 = TreeNode.create!

    assert_equal [child2, child3, grandchild1, root2], TreeNode.leaves.order(:created_at).to_a
  end

  def test_lowest_common_ancestor_paths
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)
    grandchild2 = TreeNode.create!(parent: child1)
    greatgrandchild2 = TreeNode.create!(parent: grandchild2)

    assert_equal [child1.materialized_path], TreeNode.lowest_common_ancestor_paths(root.leaves.select(:materialized_path))
  end

  def test_lowest_common_ancestor_paths_from_array
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)
    grandchild2 = TreeNode.create!(parent: child1)
    greatgrandchild2 = TreeNode.create!(parent: grandchild2)

    paths = root.leaves.select(:materialized_path).map(&:materialized_path)
    assert_equal [child1.materialized_path], TreeNode.lowest_common_ancestor_paths(paths)
  end

  def test_lowest_common_ancestors
    root = TreeNode.create!
    child1 = TreeNode.create!(parent: root)
    grandchild1 = TreeNode.create!(parent: child1)
    grandchild2 = TreeNode.create!(parent: child1)
    greatgrandchild2 = TreeNode.create!(parent: grandchild2)

    assert_equal [child1], TreeNode.lowest_common_ancestors(root.leaves.select(:materialized_path)).to_a
  end
end
