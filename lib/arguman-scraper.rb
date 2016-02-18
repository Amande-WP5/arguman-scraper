require "httparty"
require "sequel"
Sequel.connect("postgres:///postgres")

require_relative "scraper/scraper"
require_relative "scraper/debate"
require_relative "scraper/user"
require_relative "scraper/argument"
