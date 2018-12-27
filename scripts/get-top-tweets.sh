#!/bin/bash
#Make a Search API request... Client paginates to request all data by default.

ruby ../search/search-app.rb -r "snow has:media has:geo -is:retweet" -s 1d -a "../config/environments_private.yaml" -c "../search/config/settings.yaml"
#Pass Tweet IDs to the Engagement API. 
ruby ../engagement/engagement-app.rb -a "../config/environments_private.yaml" -c "../engagement/config/settings.yaml"