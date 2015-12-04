require "tty"
require "pastel"
require "optitron"
require "tty"
require "httparty"
require "sequel"
Sequel.connect("postgres:///postgres")
require_relative "lib/scraper"

REMOVED = [2424,2388,2376,2353,2336,2251,2186,2059,1978,1924,1794,978,963,962,960,954,902,880,828,797,776,722,844]

class Scraper < Optitron::CLI
  def parse_results(results)
    results.each do |res|
      next if Debate[res["id"]]
      next if REMOVED.include? res["id"].to_i
      next if res["title"] =~ /[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0-9,.;:\/\s"’'\(\)\%&$£€+\-*_ =!?]/
      user = User.find_or_create(:id=>res["user"]["id"]) do |u|
        u.id = res["user"]["id"]
        u.username = res["user"]["username"]
      end
      Debate.create do |d|
        d.id    = res["id"]
        d.title = res["title"]
        d.user  = user
      end
      puts "#{res["title"]} from #{res["user"]["username"]} #{res["id"]}"
    end
  end

  def retrieve_arguments(debate)
    url = "http://arguman.org/api/v1/arguments/#{debate.id}/premises"
    response = HTTParty.get(url)
    res = response.parsed_response
    puts debate.title
    res.each do |arg|
      user = User.find_or_create(:id=>arg["user"]["id"], :username=>arg["user"]["username"])
      next if Argument[arg["id"]]
      Argument.create do |a|
        a.id = arg["id"]
        a.text = arg["text"]
        a.type = arg["premise_type"]
        a.user = user
        a.parent = Argument[arg["parent"]]
        a.debate = Debate[debate.id]
      end
      puts arg["text"]
    end
  end

  def build_apxd_file(debate)
    File.open("debates_apxd/#{debate.id}.apxd", "w") do |file|
      file.write("arg(root).\n")
      file.write("text(root, #{debate.title}).\n\n")
      debate.arguments.each do |arg|
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

  desc "Retrieve the new debates (but not the arguments)"
  arg_types :numeric
  def get_debates(up_to_page=20)
    url = "http://arguman.org/api/v1/arguments/?page=1"
    loop do
      puts "\n#{url}"
      response = HTTParty.get(url)
      json = response.parsed_response
      parse_results(json["results"])
      url = json["next"]
      break if url.nil? || url == "http://arguman.org/api/v1/arguments/?page=#{up_to_page}"
    end
  end

  desc "Retrieve arguments of all debates"
  def get_arguments
    Debate.dataset.all.each do |d|
      retrieve_arguments(d)
    end
  end

  desc "Build apxd files from the debates"
  def build_apxd
    nb_deb = Debate.dataset.count
    pastel = Pastel.new
    bar = TTY::ProgressBar.new("Creating files [:bar] :current/:total", :total=>nb_deb, :complete=>pastel.on_green("-"), :incomplete=>pastel.on_red("-"))
    Debate.dataset.each do |d|
      build_apxd_file(d)
      bar.advance(1)
    end
  end

  desc "Returns some stats"
  def stats
    num = Array.new(50) {0}
    max = 0
    Debate.dataset.each do |d|
      size = d.arguments.size
      max = size if size > max
      num[size/10] += 1
    end
    val = [["Max #args", max]]
    num.each_with_index do |v,it|
      val << ["#{it*10}-#{(it+1)*10}", v] if v > 0
    end
    table = TTY::Table.new :rows=>val
    puts table.render :ascii, :alignment=>[:left, :right]
  end
end

Scraper.dispatch
