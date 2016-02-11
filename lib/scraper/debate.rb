require "httparty"

class Debate < Sequel::Model
  many_to_one :user
  one_to_many :arguments

  def build_apxd_file(dir)
    File.open("#{dir}/#{self.id}.apxd", "w") do |file|
      file.write("arg(root).\n")
      file.write("text(root, #{self.title}).\n\n")
      self.arguments.each do |arg|
        file.write("arg(#{arg.id}).\n")
        file.write("text(#{arg.id}, #{arg.text}).\n")
        parent = (arg.parent ? arg.parent.id : "root")
        if arg.type == 1
          file.write("support(#{arg.id}, #{parent}).\n\n")
        else
          file.write("att(#{arg.id}, #{parent}).\n\n")
        end
      end
    end
  end

  def retrieve_arguments(verbose=false)
    url = "http://arguman.org/api/v1/arguments/#{self.id}/premises"
    response = HTTParty.get(url)
    res = response.parsed_response
    puts self.title if verbose
    res.each do |arg|
      user = User.find_or_create(:id=>arg["user"]["id"], :username=>arg["user"]["username"])
      next if Argument[arg["id"]]
      Argument.create do |a|
        a.id = arg["id"]
        a.text = arg["text"]
        a.type = arg["premise_type"]
        a.user = user
        a.parent = Argument[arg["parent"]]
        a.debate = Debate[self.id]
      end
      puts arg["text"] if verbose
    end
    res.each do |arg|
      a = Argument[arg["id"]]
      next if a.parent
      a.parent = Argument[arg["parent"]]
      a.save
    end
  end

  def cross_all_args(stream=nil)
    args = self.arguments
    raise "Not enough arguments" if args.size <= 1
    return cross_array(args, stream)
  end

  def cross_siblings(stream=nil)
    args = self.arguments
    arg_ids = []
    no_parent = []
    args.each do |subtree|
      if subtree.parent.nil?
        no_parent << subtree
        next
      end
      support, attack = subtree.children.partition {|arg| arg.type == 1}
      arg_ids += cross_array(support, stream) if support.size > 1
      arg_ids += cross_array(attack, stream)  if attack.size > 1
    end
    if no_parent.size > 1
      support, attack = no_parent.partition {|arg| arg.type == 1}
      arg_ids += cross_array(support, stream) if support.size > 1
      arg_ids += cross_array(attack, stream)  if attack.size > 1
    end
    return arg_ids
  end

  def cross_array(array, stream)
    arg_ids = []
    array.each_with_index do |arg, it|
      array[it+1..-1].each do |arg2|
        pair = "#{arg.text.gsub(/\r\n?/," ").gsub(/#/, "").chomp}##{arg2.text.gsub(/\r\n?/," ").gsub(/#/, "").chomp}\n"
        stream << pair if stream
        arg_ids << [arg.id, arg2.id, pair]
      end
    end
    return arg_ids
  end
end
