require 'spec_helper'

describe SkroutzChallenge do

  let(:three_level_tree) { SkroutzChallenge::build_tree(76, 3) }
  let(:two_level_tree) { SkroutzChallenge::build_tree(76, 2) }

  describe "::start" do

    it "should return a TreeNode object" do
      expect(three_level_tree).to be_an_instance_of(Tree::TreeNode)
    end

    it "should return the root node" do
      expect(three_level_tree.is_root?).to be_true
    end

    it "should raise exception with invalid id" do
      expect { SkroutzChallenge::build_tree(-1, 2) }.to raise_error(ArgumentError, "Invalid category id.")
      expect { SkroutzChallenge::build_tree(0, 2) }.to raise_error(ArgumentError, "Invalid category id.")
    end

    it "should raise exception for negative level" do
      expect { SkroutzChallenge::build_tree(76, -1) }.to raise_error(ArgumentError, "Negative depth level.")
    end

  end

  describe "::get_childrens" do

    let(:categories) { SkroutzChallenge::get_childrens(76) }

    context "with existent category id" do

      it "should return a Hash" do
        expect(categories).to be_an_instance_of(Hash)
      end

      it "should have a categories key" do
        expect(categories.has_key?("categories")).to be_true
      end

      it "should have an array of hashes for the categories key" do
        expect(categories["categories"]).to be_an_instance_of(Array)
        expect(categories["categories"][0]).to be_an_instance_of(Hash)
      end

    end

    context "with non-existent category id" do

      it "should return an appropriate message" do
        result = SkroutzChallenge::get_childrens(3)
        expect(result).to eql SkroutzChallenge::CATEGORY_NOT_FOUND
      end

    end        
  end

  describe "::depth" do

    it "should return -1 for nil node" do
      expect(SkroutzChallenge::depth(nil)).to eql(-1)
    end

    it "should return 3 for three level tree" do
      expect(SkroutzChallenge::depth(three_level_tree)).to eql(3)
    end

    it "should return 2 for two level tree" do
      expect(SkroutzChallenge::depth(two_level_tree)).to eql(2)
    end

  end

  describe "::fill_tree" do

    let(:root) { Tree::TreeNode.new("Root", 76) }

    context "with 2 level tree" do

      it "should have the opposite level" do
        SkroutzChallenge::fill_tree(0, 76, root, 2, Hash.new(0))
        expect(SkroutzChallenge::depth(root)).to eql(2)
      end

      it "should have at most 2 nodes per level" do
        SkroutzChallenge::fill_tree(0, 76, root, 2, Hash.new(0))
        expect(root.size).to be <= (SkroutzChallenge::depth(root) * 2) + 1
      end

      it "should minimize API calls" do
        expect(SkroutzChallenge).to receive(:get_childrens).twice.and_call_original
        SkroutzChallenge::fill_tree(0, 76, root, 2, Hash.new(0))
      end

    end

    context "with 3 level tree" do

      it "should have the opposite level" do
        SkroutzChallenge::fill_tree(0, 76, root, 3, Hash.new(0))
        expect(SkroutzChallenge::depth(root)).to eql(3)
      end

      it "should have at most 2 nodes per level" do
        SkroutzChallenge::fill_tree(0, 76, root, 3, Hash.new(0))
        expect(root.size).to be <= (SkroutzChallenge::depth(root) * 2) + 1
      end

      it "should minimize API calls" do
        expect(SkroutzChallenge).to receive(:get_childrens).exactly(3).times.and_call_original
        SkroutzChallenge::fill_tree(0, 76, root, 3, Hash.new(0))
      end

    end

  end
end
