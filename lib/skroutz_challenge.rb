require 'open-uri'
require 'json'
require 'tree'

module SkroutzChallenge
  extend self
  
  CATEGORY_NOT_FOUND = "Category not found."

  # Prints an ASCII representation for the tree of node.
  # Returns "Category not found" if the node is nil.
  def print_tree(node)
    return CATEGORY_NOT_FOUND unless node
    
    result, = print_rec(node) # grab the ASCII string from the array
    result.shift              # remove the extra vertical bar
    puts result.join("\n")    # print the result
  end

  # Merge +rows1+ and +rows2+ into one array of strings. +rows1+ and +rows2+
  # are array of strings (ASCII) .
  # The strings from rows1 / rows2 will start at p1 / p2 in the result.
  #
  #    puts SkroutzChallenge::merge_rows(["|", "2"], ["|", "13"], 1, 4)
  #  # =>   |  |    
  #         2  13 
  def merge_rows(rows1, rows2, p1, p2)
    i = 0
    result = []

    while i < rows1.size || i < rows2.size
      result << " " * p1 # prepend with p1 whitespaces
      result.last << rows1[i] if i < rows1.size # add the ith char from rows1
      if i < rows2.size
        # append with p2 whitespaces
        result.last << " " * [0, p2 - result.last.size].max
        result.last << rows2[i] # add the ith char from rows1
      end

      i += 1
    end

    result
  end

  # Builds an ASCII representation of the subtree starting at root +node+ .
  # Returns two values: an array of strings (the ASCII) and the length of
  # the longest string in that array (the width of the ASCII)
  def print_rec(node)
    # wrap the content of the node with vertical bars
    content = vertical_bars(node.content.to_s)

    if node.first_child # has left child
      left, width_left = print_rec(node.first_child)
    else
      hor_bar = horizontal_bar(node.content.to_s)
      # put the horizontal bar on top and bottom of the content
      #     |
      #  +-----+
      #  | 255 |
      #  +-----+
      return [["|".center(content.size), hor_bar, content, hor_bar], content.size]
    end

    if node.last_child # has right child
      # we allow at most 2 child nodes, so last_child gets the job done
      right, width_right = print_rec(node.last_child)
    else
      right, width_right = [], -1
    end
    
    # total width of the current line in tree level
    width = width_left + width_right + 1
    
    # merge the subtree ASCII representation
    result = merge_rows(left, right, 0, width_left + 1)

    # build the connection between parent and children
    # the vertical bar:    +-----+   
    #                      |     |
    hor_bar = horizontal_bar(node.content.to_s).center(width) # +-----+
    vert_bar = "|".center(hor_bar.length) 
    # the horizontal connection e.g. "+     +"
    hor_line = result[0].gsub("|", "+")
    hor_line[vert_bar.index("|")] = ?+ # +  +  +

    # convert spaces between pluses to minuses
    hor_line.sub!(/\+(.+)\+/) { |s| s.gsub(" ", "-") } # +---+--+

    # put it all together
    [[vert_bar, hor_bar, content.center(width), hor_bar, vert_bar, hor_line] + result, width]
  end

  # Fills the categories tree structure with nodes.
  # +cur_level+  current tree level
  # +id+         category id
  # +cur_node+   current node
  # +level+      max tree level 
  # +cache+      Hash containing cached data
  def fill_tree(cur_level, id, cur_node, level, cache={})
    level_key = "level" << cur_level.to_s
    # for the current level increase the number of nodes by 1
    cache[level_key] += 1

    if level == cur_level # we reached the maximum allowed level
      return
    else
      child_key = "childs" << cur_level.to_s

      # if we have cached data for the current level
      if cache[child_key] != 0
        # use the cached data
        data = cache["childs"+cur_level.to_s]
      else
        # perform a new API call
        data = self.get_childrens(id)
        # cache the data of the current level for later use
        cache[child_key] = data
      end

      data["categories"].take(2).each do |category|
        cat_id = category["id"]
        # break if the current level contains already two nodes
        # at most 2 nodes are allowed for every level
        break if cache[level_key] >= 2
        child = cur_node << Tree::TreeNode.new(category["name"], cat_id)
        fill_tree(cur_level + 1, cat_id, child, level, cache)
      end
    end
  end

  # Retrieves the children categories for the category +id+ and returns
  # a Hash that contains them.
  # If the category id does not exists it returns an appropriate message.
  def get_childrens(id)
    access_token = "U3TbstVCZWRdYP4Bj6d4PaR3yHMR4uJRGRQcmbs2k86VlSkQeOdDj1Xe9GV32L97x2ID8GrbyOS1idepgZO2ag=="
    # the endpoint to retrieve the childrens for the given category id
    uri = "http://skroutz.gr/api/categories/#{id}/children?oauth_token=#{access_token}"

    begin
      # perform an API call
      response = open(uri, "Accept" => "application/vnd.skroutz+json;version=3")

      # if the request was succesful
      if response.status[1] == "OK"
        # parse and return the data
        data = JSON.parse(response.read)
      end
    rescue Exception => ex
      if ex.message =~ /404/
        CATEGORY_NOT_FOUND
      else
        puts ex.message
      end
    ensure
      # In any case, close the response
      response.close if response != nil
    end
  end

  # Builds the categories tree structure. The root of the tree will
  # be the category with the matching +id+ . The tree will have a
  # depth level <= +level+ .
  # Raises an ArgumentError if the id <= 0 and if the level < 0
  def build_tree(id, level)
    raise ArgumentError, "Negative depth level." if level < 0
    raise ArgumentError, "Invalid category id." if id <= 0

    root_node = Tree::TreeNode.new("Root", id)
    result = get_childrens(id)

    if result == CATEGORY_NOT_FOUND
      return nil
    else
      memo = Hash.new(0)
      # put the childrens of the root category to the cache
      memo["childs0"] = result
      fill_tree(0, id, root_node, level, memo)  
    end

    root_node
  end

  # Computes the zero based depth of the node passed in.
  # Returns -1 if node is nil.
  #
  # ==== Examples
  #      1 = root
  #     / \
  #    2   3
  #   / \
  #  4   5
  #    depth(root)       # => 2
  #    depth(root.left)  # => 1
  #    depth(root.right) # => 0
  def depth(node)
    return -1 unless node

    lDepth = depth(node.first_child)
    rDepth = depth(node.last_child)

    lDepth > rDepth ? lDepth + 1 : rDepth + 1
  end

  # Creates a horizontal bar with + on the edges and - in the middle.
  # The length of the bar depends on the +str+ length.
  #
  #    horizontal_bar("1")    # => "+---+"
  #    horizontal_bar("255")  # => "+-----+"
  def horizontal_bar(str)
    middle = "-" * (str.length + 2)
    "+#{middle}+"
  end

  # Adds vertical bars to the left and right of +str+.
  #
  #    vertical_bars("2") # => "| 2 |"
  def vertical_bars(str)
    "| #{str} |"
  end

end
