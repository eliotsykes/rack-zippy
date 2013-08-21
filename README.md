# rack-zippy

WORK IN PROGRESS, DO NOT USE!

Rack middleware for serving static gzipped assets precompiled by the Rails asset pipeline into the public/assets directory. Use it
on Heroku if you want to serve the precompiled gzipped assets to gzip-capable clients. By default, Rails + Heroku will not serve
*.gz assets even though they are generated at deploy time.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-zippy'

And then execute:

    $ bundle

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run tests (`rake test`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

