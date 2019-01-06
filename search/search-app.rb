'''
A command-line wrapper to search-tweets.rb, the SearchTweets class. The code here focuses on parsing command-line
options, loading configuration details, and then calling get_data or get_counts methods.

* Uses the optparse gem for parsing command-line options.
* Currently loads all configuration details from a config.yaml file
* A next step could be to load in authentication keys via local environment vars.

This app currently has no logging, and instead just "puts" statements to system out. The /common/app_logger
class would be a somewhat simple way to add logging.

Loads up rules, and loops through them. At least one rule is required. One rule can be passed in via the command-line,
or a file path can be provided which contains a rule array in JSON or yaml.
Writes to standard-out or files. Soon to a data store.

-------------------------------------------------------------------------------------------------------------------
Example command-lines

    #Pass in two files, the SearchTweets app config file and a Rules file.
    # $ruby ./search-api.rb -c "./SearchConfig.yaml" -r "./rules/mySearchRules.yaml"
    # $ruby ./search-api.rb -c "./SearchConfig.yaml" -r "./rules/mySearchRules.json"

    #Typical command-line usage.
    # Passing in single filter/rule and ISO formatted dates. Otherwise running with defaults.
    # $ruby ./search-api.rb -r "rain OR weather (profile_region:colorado)" -s "2013-10-18 06:00" -e "2013-10-20 06:00"

    #Get minute counts.  Returns JSON time-series of minute, hour, or day counts.
    # $ruby ./search_api.rb -l -d "minutes" -r "rain OR weather (profile_region:colorado)" -s "2013-10-18 06:00" -e "2013-10-20 06:00"
-------------------------------------------------------------------------------------------------------------------
'''
#Wiring up on Heroku, where 'relative' is well, relative.
require_relative "/lib/search-tweets.rb"
require_relative "common/utilities.rb"

#=======================================================================================================================
if __FILE__ == $0  #This script code is executed when running this file.

    require 'optparse'
    require 'base64'
    

    OptionParser.new do |o|

        #Passing in a config file.... Or you can set a bunch of parameters.
        o.on('-a ACCOUNT', '--account', 'File (including path) that holds environment and credential info.
                                       Specifies which search api, including credentials.') { |account| $account = account}

        o.on('-c CONFIG', '--config', 'Configuration file (including path) that holds app settings. ') { |config| $config = config}
        
        #Search rule.  This can be a single rule ""this exact phrase\" OR keyword"
        o.on('-r RULE', '--rule', 'Rule details (maps to API "query" parameter).  Either a single rule passed in, or a file containing either a
                                   YAML or JSON array of rules.') {|rule| $rule = rule}
        #Tag, optional.  Not in payload, but triggers a "matching_rules" section with rule/tag values.
        o.on('-t TAG', '--tag', 'Optional. Gets included in the  payload if included. Alternatively, rules files can contain tags.') {|tag| $tag = tag}

        #Period of search.  Defaults to end = Now(), start = Now() - 30.days.
        o.on('-s START', '--start_date', 'UTC timestamp for beginning of Search period (maps to "fromDate").
                                         Specified as YYYYMMDDHHMM, \"YYYY-MM-DD HH:MM\", YYYY-MM-DDTHH:MM:SS.000Z or use ##d, ##h or ##m.') { |start_date| $start_date = start_date}
        o.on('-e END', '--end_date', 'UTC timestamp for ending of Search period (maps to "toDate").
                                      Specified as YYYYMMDDHHMM, \"YYYY-MM-DD HH:MM\", YYYY-MM-DDTHH:MM:SS.000Z or use ##d, ##h or ##m.') { |end_date| $end_date = end_date}
        #New sinceId and maxId support
        o.on('-i SINCEID','--sinceid', "For 'catch-up' queries. Usually set to the most recent numeric Tweet ID you've received.") {|since_id| $since_id = since_id}
        o.on('-u UNTILID','--untilid', "For 'backfill' queries... Usually set to the oldest numeric Tweet ID you've received. ") {|until_id| $until_id = until_id}

        o.on('-m MAXRESULTS', '--max', 'Specify the maximum amount of data results (maps to "maxResults").  10 to 500, defaults to 100.') {|max_results| $max_results = max_results}  #... as in look before you leap.

        #These trigger the estimation process, based on "duration" bucket size.
        o.on('-l', '--look', '"Look before you leap..."  Triggers the return of counts only via the "/counts.json" endpoint.') {|look| $look = look}  #... as in look before you leap.
        o.on('-d DURATION', '--duration', 'The "bucket size" for counts, minute, hour (default), or day. (maps to "bucket")' ) {|duration| $duration = duration}  

        o.on('-x EXIT', '--exit', 'Specify the maximum amount of requests to make. "Exit app after this many requests."') {|exit_after| $exit_after = exit_after}

        o.on('-w WRITE', '--write',"'files', 'standard-out' (or 'so' or 'standard'), 'datastore' (relational? mongo?)") {|write| $write = write}
        o.on('-o OUTBOX', '--outbox', 'Optional. Triggers the generation of files and where to write them.') {|outbox| $outbox = outbox}
        o.on('-z', '--zip', 'Optional. Largely untested. If writing files, compress the files with gzip.') {|zip| $zip = zip}

        #Help screen.
        o.on( '-h', '--help', 'Display this screen.' ) do
            puts o
            exit
        end

        o.parse!
    end

    puts "Starting at #{Time.now}"
    
    #Create a Tweet Search object.
    oSearch = SearchTweets.new()
    oSearch.rules.rules = Array.new

    #Manage authentication and app setting details.
    # Authentication details are looked for in ENV first, then a environments YAML file.
    # @keys['bearer_token'] = ENV['SEARCH_BEARER_TOKEN']
    # @keys['environment'] = ENV['ENVIRONMENT']


    #Set a default location for these configuration files.
    #Provided config files, which can provide auth, URL metadata, and app options.
    if $account.nil?
      $account = "../config/environments.yaml" #This file is shared with other workers.
    end

    if $config.nil?
        $config = "config/settings.yaml" #Search API specific.
    end

    #If we don't get what we need to continue, these client methods know to quit.
    oSearch.get_environment($account)
    oSearch.get_settings($config)


    #So, we got what we got from the config files, so process what was passed in.
    #Provides initial "gate-keeping" on what we have been provided. Enough information to proceed?
    #Anything on command-line overrides configuration setting... 

    error_msgs = Array.new

    oSearch.set_requester #With config details, set the HTTP stage for making requests. 

    #We need to have at least one rule.
    if !$rule.nil?
        #Rules file provided?
        extension = $rule.split(".")[-1]
        if extension == "yaml" or extension == "json"
            oSearch.rules_file = $rule
            if extension == "yaml" then
                oSearch.rules.loadRulesYAML(oSearch.rules_file)
            end
            if extension == "json"
                oSearch.rules.loadRulesYAML(oSearch.rules_file)
            end
        else
            rule = {}
            rule["value"] = $rule
            oSearch.rules.rules << rule
        end
    else
        error_msgs << "Either a single rule or a rules files is required. "
    end

    #Everything else is option or can be driven by defaults.

    #Tag is completely optional.
    if !$tag.nil?
        rule = {}
        rule = oSearch.rules.rules
        rule[0]["tag"] = $tag
    end

    #TODO new logic that handles new sinceId and maxId usage? Does a mix with dates throw an API error?

   
    #Duration is optional, defaults to "hour" which is handled by Search API.
    #Can only be "minute", "hour" or "day".
    if !$duration.nil?
        if !['minute','hour','day'].include?($duration)
            p "Warning: unrecognized duration setting, defaulting to 'minute'."
            $duration = 'minute'
        end
    end

    #start_date, defaults to NOW - 30.days by Search API.
    #end_date, defaults to NOW by Search API.
    # OK, accepted parameters gets a bit fancy here.
    #    These can be specified on command-line in several formats:
    #           YYYYMMDDHHmm or ISO YYYY-MM-DD HH:MM.
    #           14d = 14 days, 48h = 48 hours, 360m = 6 hours
    #    Or they can be in the rules file (but overridden on the command-line).
    #    start_date < end_date, and end_date <= NOW.

    #We need to end up with Twitter Search/PowerTrack timestamps in YYYYMMDDHHmm format.

    #TODO new logic that handles new sinceId and maxId usage?


    #Handle start date.
    #First see if it was passed in
    if !$start_date.nil?
        oSearch.from_date = Utilities.set_date_string($start_date)
    end

    #Handle end date.
    #First see if it was passed in
    if !$end_date.nil?
        oSearch.to_date = Utilities.set_date_string($end_date)
    end

    #Max results is optional, defaults to 100 by Search API.
    if !$max_results.nil?
        oSearch.max_results = $max_results
    end

    #Optional, defaults to auto pagination.
    if !$exit_after.nil?
	    oSearch.exit_after = $exit_after.to_i
    end
    
    #Handle 'write' option
    if !$write.nil?
			oSearch.write_mode = $write
			
			if oSearch.write_mode == "so" or oSearch.write_mode == "standard"
				oSearch.write_mode = "standard-out"
			end

			if oSearch.write_mode == "db"
				oSearch.write_mode = "datastore"
			end
			
    end

    #Writing data to files.
    if !$outbox.nil?
        oSearch.out_box = $outbox
        oSearch.write_mode = "files"

        if !$zip.nil?
            oSearch.compress_files = true
        end
    end

    #Check for configuration errors.
    if error_msgs.length > 0
        puts "Errors in configuration: "
        error_msgs.each { |e|
          puts e
        }

        puts ""
        puts "Please check configuration and try again... Exiting."

        exit
    end
    
    #Wow, we made it all the way through that!  Documentation must be awesome...

    if $look == true #Handle count requests.
        oSearch.rules.rules.each do |rule|
            puts "Getting counts for rule: #{rule["value"]}"
            results = oSearch.get_counts(rule, oSearch.from_date, oSearch.to_date, $duration)
        end
    else #Asking for data!
        oSearch.rules.rules.each do |rule|
            puts "Getting activities for rule: #{rule["value"]}"
            oSearch.get_data(rule, oSearch.from_date, oSearch.to_date)
        end
    end
    
    puts "Exiting at #{Time.now}"
end
