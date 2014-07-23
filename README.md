# rack-zippy

rack-zippy is a Rack middleware for serving static gzipped assets precompiled by the Rails asset pipeline into the public/assets directory. Use it
on Heroku if you want to serve the precompiled gzipped assets to gzip-capable clients with sensible caching headers.

By default, Rails + Heroku will not serve *.gz assets even though they are generated at deploy time.

rack-zippy replaces the ActionDispatch::Static middleware used by Rails, which is not capable of serving the gzipped assets created by
the `rake assets:precompile` task. rack-zippy will serve non-gzipped assets where they are not available or not supported by the
requesting client.

Watch the [Web Dev Break podcast on rack-zippy](http://www.webdevbreak.com/specials/rack-zippy "Faster, friendlier assets with rack-zippy") to see how you can check if your app
is currently serving uncompressed assets and how quick it is to setup rack-zippy:

[ ![Faster, friendlier assets with rack-zippy](/video-player.png "Faster, friendlier assets with rack-zippy") ](http://www.webdevbreak.com/specials/rack-zippy "Faster, friendlier assets with rack-zippy")

## Installation in Rails app

Add this line to your application's Gemfile:

    gem 'rack-zippy'

And then execute:

    $ bundle
    
In `config/environments/production.rb`, set `config.serve_static_assets` to `true`:

    # Puts ActionDispatch::Static in middleware stack which we are going to replace with
    # Rack::Zippy::AssetServer
    config.serve_static_assets = true

Create the file `config/initializers/rack_zippy.rb` and put this line in it:

    Rails.application.config.middleware.swap(ActionDispatch::Static, Rack::Zippy::AssetServer)

Now run `rake middleware` at the command line and make sure that `Rack::Zippy::AssetServer` is near the top of the outputted list. ActionDispatch::Static should not be in the list. Nicely done, rack-zippy is now installed in your app.

## Installation in Rack app (that isn’t a Rails app)

Add this line to your application's Gemfile:

    gem 'rack-zippy'

And then execute:

    $ bundle

In `config.ru`:

    require 'rack-zippy'

    # Set asset_root to an absolute or relative path to the directory holding your asset files
    # e.g. '/path/to/my/apps/static-assets' or 'public'
    asset_root = '/path/to/my/apps/public'
    use Rack::Zippy::AssetServer, asset_root


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
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request


## Contributors

- [Eliot Sykes](https://github.com/eliotsykes)
- [Kieran Topping](https://github.com/ktopping)
- [Luke Wendling](https://github.com/lukewendling)


## Releasing a new gem

1. Update pre-release version to the release version in lib/rack-zippy/version.rb, e.g. '1.0.1.pre' becomes '1.0.1'
2. Update CHANGELOG.md and Contributors in README.md
3. Tests pass? (`rake test`)
4. Build the gem (`rake build`)
5. Release on rubygems.org (`rake release`)
6. Update version to the next pre-release version in lib/rack-zippy/version.rb, e.g. '1.0.1' becomes '1.0.2.pre'.
7. Commit and push the updated lib/rack-zippy/version.rb.

