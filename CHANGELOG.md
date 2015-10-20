## 4.0.1.pre / yyyy-mm-dd

## 4.0.0 / 2015-10-20
- Rack Zippy continues to support non-Rails Rack apps, though Rails support has ended in rack-zippy 4.0+. Rails 4.2+ now supports serving gzipped files directly. Configure your Rails 4.2+ app to use the `ActionDispatch::Static` middleware. If you absolutely need rack-zippy for your Rails app or can't upgrade to Rails 4.2+, try using an earlier rack-zippy version: `~> 3.0.1`
- New dependency on actionpack gem. Rack Zippy decorates the `ActionDispatch::Static` middleware for non-Rails Rack apps to provide Rack Zippy's own choice of caching headers and whitelisting of permitted static file extensions.

## 3.0.1 / 2015-05-19
- Allow paths with periods in the middle, but not if they immediately follow slash ([#46](https://github.com/eliotsykes/rack-zippy/pull/46)) @ssemakov

## 3.0.0 / 2015-04-18
- POTENTIAL BREAKING CHANGE! `STATIC_EXTENSION_REGEX` has been removed and replaced with a `static_extensions` array. If your app monkey patched `STATIC_EXTENSTION_REGEX` to change the file extension whitelist, then you will need to update your app to use rack-zippy 3.x. Depending on how you patched, and your test coverage, your app could silently fail. Search your codebase for `STATIC_EXTENSION_REGEX` to ensure it is not used. If it is used, then migrate your patch to use the new `Rack::Zippy.config` method for configuring `static_extensions`: https://github.com/eliotsykes/rack-zippy#static_extensions
- Make static extensions list configurable ([#45](https://github.com/eliotsykes/rack-zippy/pull/45)) Anton Petrunich

## 2.0.2 / 2014-12-15
- Remove binstub bin/rake permanently, may be causing Heroku issues

## 2.0.1 / 2014-12-15
- New `:max_age_fallback` (in seconds) option

## 2.0.0 / 2014-12-07
- Rack Zippy now works cleanly with all Rack apps, including Rails apps ([#23](https://github.com/eliotsykes/rack-zippy/issues/23))
- Decomposed AssetServer into AssetServer, ServeableFile, and AssetCompiler classes
- Installation notes for non-Rails Rack apps added to README.md
- Smarter handling of directory requests to match behaviour of Rails Static middleware ([#15](https://github.com/eliotsykes/rack-zippy/issues/15))
    - Requests for `/` and `/index` respond with `public/index.html` if present
    - Requests for `/foo/` and `/foo` respond with first file present out of `public/foo.html`, `public/foo/index.html` (Same behaviour for subdirectories)
- Use File.join to build file path ([#34](https://github.com/eliotsykes/rack-zippy/issues/34))
- Respond with 404 Not Found instead of raising SecurityError for illegal paths ([#17](https://github.com/eliotsykes/rack-zippy/issues/17))

## 1.2.1 / 2014-07-09
- Use absolute (not relative) path for default asset_root ([#11](https://github.com/eliotsykes/rack-zippy/issues/11))

## 1.2.0 / 2014-07-09
- Add handling of font files with extensions: woff, woff2, ttf, eot, otf
  ([#9](https://github.com/eliotsykes/rack-zippy/issues/9))
- Handle flash .swf file extension ([#20](https://github.com/eliotsykes/rack-zippy/issues/20))

## 1.1.0 / 2014-01-26
- rack-zippy no longer blocks requests for assets that it cannot find on the filesystem. These
  requests are now passed on to the app. ([#7](https://github.com/eliotsykes/rack-zippy/issues/7))

## 1.0.1 / 2013-09-06
-  Fix error on request for assets root dir (fixes [#2](https://github.com/eliotsykes/rack-zippy/issues/2))
-  Add MIT license to gemspec (fixes [#1](https://github.com/eliotsykes/rack-zippy/issues/1))

## 1.0.0 / 2013-08-22

Production-ready release

-  Only set years-old cache-friendly last-modified header on assets with max-age of at least 1 month

## 0.1.0 / 2013-08-21

Initial release
