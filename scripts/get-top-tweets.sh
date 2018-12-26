#!/bin/bash
#Make a Search API request... Client paginates to request all data by default.
ruby ./search/search_app.rb -r "snow has:media has:geo -is:retweet" -s 1s -c ./search/config/settings.yaml
#Pass Tweet IDs to the Engagement API. 
ruby ./engagement/engagement_app.rb -c ./engagement/config/settings.yaml