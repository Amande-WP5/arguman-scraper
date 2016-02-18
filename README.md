# arguman-scraper
Scraps [arguman.org](http://arguman.org) for debates.

##Requirements
1. A [PostgreSQL](http://www.postgresql.org/) database, up and running
2. [Ruby](https://www.ruby-lang.org) of course

##Installation
1. Install [bundler](http://bundler.io/): ```gem install bundler```
2. Clone the repository: ```git clone https://github.com/Amande-WP5/arguman-scraper.git && cd arguman-scraper```
3. Install the required gems: ```bundle install```
4. Change the connection URL to the database in [this file](lib/arguman-scraper.rb)
5. Execute the migrations to build the tables: ```sequel -m ./migrations postgres://host/database```
6. Check the man: ```bin/scraper help```

##Available commands
###debates
Retrieves all the debates from arguman. It only retrieves the root (the title) of the debates, not the arguments inside.
If some debates look awkward or are not usable (troll debates, tests, foreign languages), please add them to the ```REMOVED``` list in [this file](bin/scraper) and propose a pull-request.

###arguments
Retrieves all the arguments of all debates.

###apxd
Builds the APXD file (an extension of [Aspartix](http://www.dbai.tuwien.ac.at/proj/argumentation/systempage/)) for the given debates (all debates by default).

The syntax for this file is as follows:
* ```arg(root)``` or ```arg(id)``` to specify an argument
* ```text(ARG, SOMETEXT)``` to specify the text associated to this argument (id or "root")
* ```att(ARG1, ARG2)``` if ARG1 attacks ARG2 (id or "root")
* ```support(ARG1, ARG2)``` if ARG1 supports ARG2 (id or "root")

###stats
Returns some statistics on the debates: maximum number of arguments and number of debates by ranges of number of arguments.

##Contribution
Feel free to contribute using pull-requests and fill issue tickets.
