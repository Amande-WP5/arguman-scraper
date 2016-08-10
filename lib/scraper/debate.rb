module Scraper
  class Debate < Sequel::Model
    many_to_one :user
    one_to_many :arguments

    def build_apxd_file(dir)
      File.open("#{dir}/#{self.id}.apxd", "w") do |file|
        file.write("arg(root).\n")
        file.write("text(root, #{self.title}).\n\n")
        relations = []
        self.arguments.each do |arg|
          type = (arg.type == 1 ? "support" : "att")
          file.write("arg(#{arg.id}). %#{type}\n")
          file.write("text(#{arg.id}, #{arg.text.gsub(/\n/, "\\n")}).\n")
          parent = (arg.parent ? arg.parent.id : "root")
          relations << "#{type}(#{arg.id}, #{parent}).#{" %parent is support" if arg.parent&.type == 1}\n\n"
        end
        relations.each { |rel| file.write(rel) }
      end
    end

    def retrieve_arguments(verbose=false)
      url = "http://arguman.org/api/v1/arguments/#{self.id}/premises"
      response = HTTParty.get(url)
      res = response.parsed_response
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
        puts "#{arg["text"]} #{self.id}" if verbose
      end
      res.each do |arg|
        a = Argument[arg["id"]]
        next if a.parent
        a.parent = Argument[arg["parent"]]
        a.save
      end
    end
  end
end
