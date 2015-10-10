# rack-zippy

rack-zippy is a Rack middleware for serving static gzipped assets precompiled by the Rails (4.1 and earlier) asset pipeline into the public/assets directory. Use it on Heroku if you want to serve the precompiled gzipped assets to gzip-capable clients with sensible caching headers.

## IMPORTANT NOTES for Rails 4.2 applications
- Rails 4.2 does *not* generate .gz assets when using a recent version of Sprockets
- .gz asset generation was removed in Sprockets 3.0 (see discussion here https://github.com/rails/sprockets/issues/26).
- Ensure that .gz files are generated during `rake assets:precompile`
- It might help using an earlier version of Sprockets, e.g. `gem "sprockets", "~> 2.12.4"` (awaiting confirmation - please tell me if you've found this works)
- Rails 4.2 now contains middleware to serve .gz files **if** they are generated, so as long as the .gz files are generated, you probably will not need rack-zippy. Check the headers and responses on your assets served in your production environment.

By default, Heroku + Rails 4.1 and earlier will not serve .gz assets. These .gz assets **used** to be generated at deploy time in Rails 4.1 and earlier. However in Rails 4.2 they are **not** generated (see notes on Rails 4.2 above).

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

### Options

#### max_age_fallback

`max_age_fallback`, is an integer value in seconds that should be used as the max_age fallback for files served by rack-zippy that live **outside** the `/assets` subdirectory *and* aren't `/favicon.ico`.

A typical use for `max_age_fallback` is to define how long the cache lifetime for static HTML files served by rack-zippy should be. For one of my sites I have this set to 10 minutes:

```ruby
max_age_in_secs = 10*60 # 10 mins = 600 secs
use Rack::Zippy::AssetServer, asset_root, max_age_fallback: max_age_in_secs
```

Any files given the `max_age_fallback` would have the following `Cache-Control` header:

```
Cache-Control: public, max-age=600
```

### Configuration

#### Supported Extensions Whitelist

rack-zippy handles only files with whitelisted extensions. Default extensions are stored in the `static_extensions` array with an entry for each of these:
`css js html htm txt ico png jpg jpeg gif pdf svg zip gz eps psd ai woff woff2 ttf eot otf swf`

You can modify this list to support other extensions by appending the lowercased file extension to the `static_extensions` array:

```ruby
Rack::Zippy.configure do |config|
  # Add support for the given extensions:
  config.static_extensions.push('csv', 'xls', 'rtf', ...EXTENSIONS TO ADD...)
end
```

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

#### How to Run a Single Test

```bash
# Single test method
ruby -Ilib:test test/taken_from_rails_static_test.rb --name test_serves_static_file_with_ampersand_in_filename

# Single test file
ruby -Ilib:test test/taken_from_rails_static_test.rb
```

## Contributors

- Eliot Sykes https://eliotsykes.com
- Kieran Topping https://github.com/ktopping
- Luke Wendling https://github.com/lukewendling
- Anton Petrunich https://github.com/solenko
- ssemakov https://github.com/ssemakov
- Kai Schlichting https://github.com/lacco

## Releasing a new gem

1. Update pre-release version to the release version in `lib/rack-zippy/version.rb`, e.g. `1.0.1.pre` becomes `1.0.1`
2. Update `CHANGELOG.md` version and date. Update Contributors in `README.md`.
3. Tests pass? (`rake test`)
4. Commit and push changes to origin.
4. Build the gem (`rake build`)
5. Release on rubygems.org (`rake release`)
6. Update version to the next pre-release version in `lib/rack-zippy/version.rb`, e.g. `1.0.1` becomes `1.0.2.pre`.
7. Add new heading to `CHANGELOG` for the next pre-release
8. Commit and push the updated `lib/rack-zippy/version.rb` and `CHANGELOG` files.
