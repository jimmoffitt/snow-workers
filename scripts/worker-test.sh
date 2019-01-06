echo "Worker launched..."
echo "Calling Ruby test script.... Working dir: " && pwd
ruby scripts/ruby-test.rb
echo "Back from test ruby call... Now attempting the real thing at scripts/ruby-test.rb"
bash scripts/get-top-tweets.sh
