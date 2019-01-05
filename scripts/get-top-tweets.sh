#!/bin/bash
#Make a Search API request... Client paginates to request all data by default.
echo "In get-top-tweets.sh, about to call Twitter API ruby scripts."
ruby search-app.rb -r "snow has:media has:geo -is:retweet" -s 1d -a "../config/environments_private.yaml" -c "../search/config/settings.yaml"
#Pass Tweet IDs to the Engagement API. 
ruby engagement/engagement-app.rb -a "../config/environments_private.yaml" -c "../engagement/config/settings.yaml"
