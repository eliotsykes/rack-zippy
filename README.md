# rack-zippy

rack-zippy is a Rack middleware for serving static gzipped assets precompiled by the Rails asset pipeline into the public/assets directory. Use it
on Heroku if you want to serve the precompiled gzipped assets to gzip-capable clients with sensible caching headers.

By default, Rails + Heroku will not serve *.gz assets even though they are generated at deploy time.

rack-zippy replaces the `ActionDispatch::Static` middleware used by Rails, which is not capable of serving the gzipped assets created by
the `rake assets:precompile` task. rack-zippy will serve non-gzipped assets where they are not available or not supported by the
requesting client.

rack-zippy (since 2.0.0) has the same **convenient directory request handling** provided by `ActionDispatch::Static`, which means you can take advantage of this in any rack app:

- Requests for `/` and `/index` respond with `public/index.html` if present
- Requests for `/foo/` and `/foo` respond with first file present out of `public/foo.html`, `public/foo/index.html` (Same behaviour for subdirectories)

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

##### NameError: uninitialized constant Rack::Zippy

- Check `Gemfile` doesn't limit rack-zippy to a subset of environment groups
- Run `bundle install`
- Check `Gemfile.lock` contains an entry for rack-zippy


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Run tests (`rake test`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new Pull Request

### Optional for contributors
To try a local branch of rack-zippy out as the gem dependency in a local app, configure bundler with a local gem
override as follows:

In `your-app/Gemfile`: edit the rack-zippy dependency to the following:

    # The branch your-local-branch-name **must** exist otherwise bundler will shout obscenities at you
    gem 'rack-zippy', :github => 'eliotsykes/rack-zippy', :branch => 'your-local-branch-name'

At the command line, inside `your-app`, configure bundler to set a local git repo to override the one we specified in the previous step for rack-zippy:

    $> bundle config --local local.rack-zippy /path/to/your/local/rack-zippy

Now when you run your-app **with** `bundle exec`, the rack-zippy gem dependency will resolve to `/path/to/your/local/rack-zippy`.

Cleanup time! When you’re finished testing, delete the local override and set your Gemfile dependency back to the original:

    # At the command line:
    $> bundle config --delete local.rack-zippy

    # In your-app/Gemfile change rack-zippy dependency to this (or similar):
    gem 'rack-zippy', '~> 9.8.7' # Replace 9.8.7 with the rack-zippy release version you want to use.



## Contributors

- Eliot Sykes https://eliotsykes.com
- Kieran Topping https://github.com/ktopping
- Luke Wendling https://github.com/lukewendling


## Releasing a new gem

1. Update pre-release version to the release version in `lib/rack-zippy/version.rb`, e.g. `1.0.1.pre` becomes `1.0.1`
2. Update `CHANGELOG.md` version and date. Update Contributors in `README.md`.
3. Tests pass? (`rake test`)
4. Build the gem (`rake build`)
5. Release on rubygems.org (`rake release`)
6. Update version to the next pre-release version in `lib/rack-zippy/version.rb`, e.g. `1.0.1` becomes `1.0.2.pre`.
7. Add new heading to `CHANGELOG` for the next pre-release
8. Commit and push the updated `lib/rack-zippy/version.rb` and `CHANGELOG` files.

