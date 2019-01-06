=begin

 {
    "top_tweets": [
        {
            "type": "impressions",
            "tweets": [
                {
                    "id": "6467303938383",
                    "count": 34556
                },
                {
                    "id": "6413043544232",
                    "count": 1656
                },
                {
                    "id": "6436383002223",
                    "count": 945
                }
            ]
        },
        {
            "type": "engagements",
            "tweets": []
        }
    ]
}

=end


class TopTweet
  
  attr_accessor :id,
                :count
  
  def initialize
    @id = ''
    @count = 0
  end
  
  
end

class TopTweets
  
  attr_accessor :engagement_type,
                :tweets,
                :look_up_url

  def initialize    
    @engagement_type = ''
    @tweets = []
    @look_up_url = "https://twitter.com/lookup/"
  end


  
  
  
end