require_relative '../lib/skroutz_challenge'

print "Enter category ID: "
id = gets.chomp.to_i
print "Enter depth level: "
level = gets.chomp.to_i
root = SkroutzChallenge::build_tree(id, level)
puts SkroutzChallenge::print_tree(root)
