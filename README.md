# snow-workers
Refactoring existing Ruby clients of the Twitter Search and Engagement APIs to add new features to the SnowBot.

The intent is to have a scheduled task that collects Tweets from the previous 24-hours and determing the Tweet with the most engagements, or a "Tweet of the Day." For this demo, the number of favorities/likes is used as a proxy for 'engagement.'

Code is largely borrowed from these two projects:
+ https://github.com/twitterdev/search-tweets-ruby
+ https://github.com/twitterdev/engagement-api-client-ruby

This refactoring will include:
+ Support of pulling in configuration settings from the system's underlying ENV hive, e.g.:

* @keys['consumer_key'] = ENV['CONSUMER_KEY']
* @keys['consumer_secret'] = ENV['CONSUMER_SECRET']
* @keys['access_token'] = ENV['ACCESS_TOKEN']
* @keys['access_token_secret'] = ENV['ACCESS_TOKEN_SECRET']

This will make deploying on Heroku easier. Heroku provides a basic UI for ENV settings.

These two projects differ in fundamental ways, and it will be interesting to see what new common code falls out of this. One key difference is that the search client uses app-only Bearer Tokens and the engagement API supports user authentication. So two projects with very difference authentication libraries baked into them.


