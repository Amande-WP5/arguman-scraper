require "tty"
require "pastel"
require "optitron"
require "httparty"
require "sequel"
Sequel.connect("postgres:///postgres")
require_relative "lib/scraper"

REMOVED = [2621,2607,2563,2550,2529,2516,2515,2503,2462,2461,2441,2424,2388,2376,2353,2336,2251,2186,2059,1978,1924,1794,978,963,962,960,954,902,880,828,797,776,722,844,662,650,641,607,606,582,548,538,537,529,528,508,501,481,450,448,422,403,386,380,358,356,346,345,322,321,308,283,276,269,264,253,207,177,161,130,102,88,61,47,21,20,12]

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
      break if url.nil? || url == "http://arguman.org/api/v1/arguments/?page=#{up_to_page+1}"
    end
  end

  desc "Retrieve arguments of all debates"
  def get_arguments
    Debate.dataset.all.each do |d|
      d.retrieve_arguments(true)
    end
  end

  desc "Build apxd files from the debates"
  def build_apxd
    dir    = "debates_apxd"
    nb_deb = Debate.dataset.count
    pastel = Pastel.new
    bar = TTY::ProgressBar.new("Creating files [:bar] :current/:total", :total=>nb_deb, :complete=>pastel.on_green("-"), :incomplete=>pastel.on_red("-"))
    Debate.dataset.each do |d|
      d.build_apx_file(dir)
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

  desc "Create files and compute similarity distance for a debate"
  def similitude(debate_id, siblings_only=false)
    arg_ids = []
    STDERR.puts "Creating file"
    File.open("#{debate_id}.txt", "w") do |file|
      d = Debate[debate_id.to_i]
      if siblings_only
        arg_ids = d.cross_siblings(file)
      else
        arg_ids = d.cross_all_args(file)
      end
    end
    STDERR.puts "Features"
    %x{python takelab_simple_features.py #{debate_id}.txt > "#{debate_id}-feat.txt"}
    STDERR.puts "Predict"
    %x{svm-predict #{debate_id}-feat.txt model.txt #{debate_id}-pred.txt}
    STDERR.puts "Post process"
    %x{python postprocess_scores.py #{debate_id}.txt #{debate_id}-pred.txt}
    values = Array.new
    g = Graph.new
    STDERR.puts "Sorting"
    File.open("#{debate_id}-pred.txt", "r") do |file|
      ind = 0
      while(line = file.gets)
        values << [ind, line.to_f]
        id_ind = arg_ids[ind]
        g.add_edge(id_ind[0], id_ind[1], line.to_f)
        ind += 1
      end
    end
    value_hash = g.optimize
    values.zip(arg_ids).each do |val, ids|
      new_val = value_hash[ids[0..1].minmax.join("_")]
      val << new_val*5.0 << ids[2]
    end
    values.sort! {|a,b| b[2] <=> a[2]}
    values.each do |val|
      puts "#{val[3]} #{val[2]} #{val[1]}"
    end
  end

  desc "Create files and compute similarity distance for a debate using Cortical API"
  def cortical_sim(debate_id, siblings_only=false)
    arg_ids = []
    d = Debate[debate_id.to_i]
    if siblings_only
      arg_ids = d.cross_siblings
    else
      arg_ids = d.cross_all_args
    end
    STDERR.puts "Creating API call JSON"

    json_arr = []
    arg_ids.lazy.map(&:last).each do |args|
      arg1, arg2 = args.split("#")
      json_arr << [{"text"=>arg1}, {"text"=>arg2}]
    end
    response = HTTParty.post("http://api.cortical.io:80/rest/compare/bulk?retina_name=en_associative", :body => json_arr.to_json, :headers => {"api-key" => "PLACEHOLDER", "Content-Type" => "application/json" })

    json = response.parsed_response
    ind_with_index = json.map {|h| h["cosineSimilarity"]}.zip(arg_ids.map(&:last))
    sorted = ind_with_index.sort! {|a,b| b[0] <=> a[0]}
    sorted.each do |val, arg|
      arg1, arg2 = arg.split("#")
      puts "#{arg1} // #{arg2} #{val}"
    end
  end
end

Scraper.dispatch
