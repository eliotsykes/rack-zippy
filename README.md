# Hey fellow Rails developers, please read!

**Want to use rack-zippy with a Rails v4.2 or greater app?**  
Its recommended you don't! Rails 4.2+ now supports serving gzipped files directly so there's no need for rack-zippy in Rails 4.2+ apps.

**Want to use rack-zippy with a Rails v4.1 or less app?**  
You'll need to use v3.0 of rack-zippy, see the README here: https://github.com/eliotsykes/rack-zippy/tree/v3.0.1

# rack-zippy

rack-zippy v4+ is a Rack middleware for serving .gz files in Rack apps that are **not** Rails 4.2+ apps. (If you need to use rack-zippy in a Rails <= 4.1 app, then use v3.0 of rack-zippy, see README here: https://github.com/eliotsykes/rack-zippy/tree/v3.0.1)

rack-zippy has convenient directory request handling:

- Requests for `/` and `/index` respond with `public/index.html` if present
- Requests for `/foo/` and `/foo` respond with first file present out of `public/foo.html`, `public/foo/index.html` (Same behaviour for subdirectories)

rack-zippy decorates actionpack's `ActionDispatch::Static` middleware for non-Rails Rack apps to provide rack-zippy's own choice of caching headers and whitelisting of permitted static file extensions. (As an alternative to rack-zippy, you can use actionpack's `ActionDispatch::Static` directly without rack-zippy.)

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

A typical use for `max_age_fallback` is to define how long the cache lifetime for static HTML files served by rack-zippy should be. For one of my sites I have this set to 15 minutes:

```ruby
max_age_in_secs = 15*60 # 15 mins = 900 secs
use Rack::Zippy::AssetServer, asset_root, max_age_fallback: max_age_in_secs
```

Any files given the `max_age_fallback` would have the following `Cache-Control` header:

```
Cache-Control: public, max-age=900
```

### Configuration

#### Supported Extensions Whitelist

rack-zippy handles only files with whitelisted extensions. Default extensions are stored in the `static_extensions` array with an entry for each of these:
`css js html htm txt ico png jpg jpeg gif pdf svg zip gz eps psd ai woff woff2 ttf eot otf swf`

You can modify this list to support other extensions by appending the lowercased file extension to the `static_extensions` array:

```ruby
Rack::Zippy.configure do |config|
  # Add support for the given extensions:
  config.static_extensions.push('map', 'csv', 'xls', 'rtf', ...EXTENSIONS TO ADD...)
end
```

It is not recommended, however if you use rack-zippy 4.0+ with a Rails 4.2+ app, you can skip the rack-zippy rails version check and log output. Put the following in an initializer:

```ruby
# config/initializers/zippy.rb
Rack::Zippy::Railtie.skip_version_check = true
```


## Troubleshooting

##### NameError: uninitialized constant Rack::Zippy

- Check `Gemfile` doesn't limit rack-zippy to a subset of environment groups
- Run `bundle install`
- Check `Gemfile.lock` contains an entry for rack-zippy
- Ensure `require 'rack-zippy'` is present near the top of `config.ru`


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
# Single test file
ruby -Ilib:test test/assert_server_test.rb

# Single test method
ruby -Ilib:test test/assert_server_test.rb --name test_serves_static_file_as_directory

# Test methods matching a regex
ruby -Ilib:test test/assert_server_test.rb --name /serves_static/
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
