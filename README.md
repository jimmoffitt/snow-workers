# snow-workers
Refactoring existing Ruby clients of the Twitter Search and Engagement APIs to add new features to the SnowBot.

The intent is to have a scheduled task that collects Tweets from the previous 24-hours and determing the Tweet with the most engagements, or a "Tweet of the Day." For this demo, the number of favorities/likes is used as a proxy for 'engagement.'

Code is largely borrowed from these two projects:
+ https://github.com/twitterdev/search-tweets-ruby
+ https://github.com/twitterdev/engagement-api-client-ruby

This refactoring will include:
+ Support of pulling in configuration settings from the system's underlying ENV hive, e.g.:

@keys['consumer_key'] = ENV['CONSUMER_KEY']
@keys['consumer_secret'] = ENV['CONSUMER_SECRET']
@keys['access_token'] = ENV['ACCESS_TOKEN']
@keys['access_token_secret'] = ENV['ACCESS_TOKEN_SECRET']

This will make deploying on Heroku easier. Heroku provides a basic UI for ENV settings.





