echo "worker launch..."
echo "Calling Ruby test script..."
ruby scripts/ruby-test.rb
echo "back from test ruby call..."
bash scripts/get-top-tweets.sh
