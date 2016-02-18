module Scraper
  class Scraper
    def self.get_debates(upto, except, verbose)
      url = "http://arguman.org/api/v1/arguments/?page=1"
      loop do
        puts "\n#{url}"
        response = HTTParty.get(url)
        json = response.parsed_response

        json["results"].each do |res|
          next if Debate[res["id"]]
          next if except.include? res["id"].to_i
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
          puts "#{res["title"]} from #{res["user"]["username"]} #{res["id"]}" if verbose
        end

        url = json["next"]
        break if url.nil? || url == "http://arguman.org/api/v1/arguments/?page=#{upto+1}"
      end
    end

    def self.get_arguments(verbose)
      Debate.dataset.all.each do |d|
        d.retrieve_arguments(verbose)
      end
    end

    def self.num_debates
      Debate.dataset.count
    end

    def self.build_apxd(dir, ids, &block)
      if ids.empty?
        Debate.dataset.each do |d|
          d.build_apxd_file(dir)
          yield if block
        end
      else
        ids.each do |id|
          Debate[id].build_apxd_file(dir)
          yield if block
        end
      end
    end

    def self.stats
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
      val
    end
  end
end
