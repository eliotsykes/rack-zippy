# rack-zippy

rack-zippy is a Rack middleware for serving static gzipped assets precompiled by the Rails asset pipeline into the public/assets directory. Use it
on Heroku if you want to serve the precompiled gzipped assets to gzip-capable clients with sensible caching headers.

By default, Rails + Heroku will not serve *.gz assets even though they are generated at deploy time.

rack-zippy replaces the ActionDispatch::Static middleware used by Rails, which is not capable of serving the gzipped assets created by
the `rake assets:precompile` task. rack-zippy will serve non-gzipped assets where they are not available or not supported by the
requesting client.

For a fuller explanation of the how, why, and the kind of performance difference you can expect when using rack-zippy,
see [Serving Compressed Assets with Heroku and Rack-Zippy](http://www.cheynewallace.com/serving-compressed-assets-with-heroku-rack-zippy/)
(thanks to Cheyne Wallace).

## Installation

Add this line to your application's Gemfile:

    gem 'rack-zippy'

And then execute:

    $ bundle

Add this line to config/application.rb:

    config.middleware.swap(ActionDispatch::Static, Rack::Zippy::AssetServer)

## Usage

Follow the installation instructions above and rack-zippy will serve any static assets, including gzipped assets, from your
application's public/ directory and will respond with sensible caching headers.

## Troubleshooting

##### 'assert_index': No such middleware to insert before: ActionDispatch::Static (RuntimeError)

Check your environment (in config/environments/) does not have `serve_static_assets` set to false:

    config.serve_static_assets = false # Oops! Should be set to true for rack-zippy

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run tests (`rake test`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Releasing a new gem

1. Update pre-release version to the release version in lib/rack-zippy/version.rb, e.g. '1.0.1.pre' becomes '1.0.1'
2. Update CHANGELOG.md
3. Tests pass? (`rake test`)
4. Build the gem (`rake build`)
5. Release on rubygems.org (`rake release`)
6. Update version to the next pre-release version in lib/rack-zippy/version.rb, e.g. '1.0.1' becomes '1.0.2.pre'
