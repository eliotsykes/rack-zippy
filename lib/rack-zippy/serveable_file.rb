module Rack
  module Zippy
    class ServeableFile

      attr_reader :path, :full_path_info

      def initialize(options)
        raise ArgumentError.new(':has_encoding_variants option must be given') unless options.has_key?(:has_encoding_variants)

        @path = options[:path]
        @full_path_info = options[:full_path_info]
        @has_encoding_variants = options[:has_encoding_variants]
        @is_gzipped = options[:is_gzipped]
        @max_age_fallback = options[:max_age_fallback] || SECONDS_IN[:day]
      end

      def headers
        headers = { 'Content-Type'  => Rack::Mime.mime_type(::File.extname(full_path_info)) }
        headers.merge! cache_headers

        headers['Vary'] = 'Accept-Encoding' if encoding_variants?
        headers['Content-Encoding'] = 'gzip' if gzipped?

        headers['Content-Length'] = ::File.size(path).to_s
        return headers
      end

      def cache_headers
        case full_path_info
        when PRECOMPILED_ASSETS_SUBDIR_REGEX
          lifetime_in_secs = SECONDS_IN[:year]
          last_modified = CACHE_FRIENDLY_LAST_MODIFIED
        when '/favicon.ico'
          lifetime_in_secs = SECONDS_IN[:month]
          last_modified = CACHE_FRIENDLY_LAST_MODIFIED
        else
          lifetime_in_secs = @max_age_fallback
        end

        headers = { 'Cache-Control' => "public, max-age=#{lifetime_in_secs}" }
        headers['Last-Modified'] = last_modified if last_modified

        return headers
      end

      def response_body
        [::File.read(path)]
      end

      def self.find_first(options)
        asset_compiler = options[:asset_compiler]
        path_info = options[:path_info].chomp('/')

        return nil if asset_compiler.compiles?(path_info)

        asset_root = options[:asset_root]

        candidate_path_infos = []
        if !path_info.empty?
          candidate_path_infos << path_info
          candidate_path_infos << "#{path_info}#{DEFAULT_STATIC_EXTENSION}"
        end
        candidate_path_infos << "#{path_info}/index#{DEFAULT_STATIC_EXTENSION}"

        file_path = nil

        full_path_info = candidate_path_infos.find do |candidate_path_info|
          file_path = ::File.join(asset_root, candidate_path_info)
          readable_file?(file_path)
        end

        return nil if full_path_info.nil? || !has_static_extension?(full_path_info)

        include_gzipped = options[:include_gzipped]

        gzipped_file_path = "#{file_path}.gz"
        gzipped_file_present = readable_file?(gzipped_file_path)

        has_encoding_variants = gzipped_file_present

        init_options = {
          :path => file_path,
          :full_path_info => full_path_info,
          :has_encoding_variants => has_encoding_variants,
          :max_age_fallback => options[:max_age_fallback]
        }

        if include_gzipped && gzipped_file_present
          init_options[:path] = gzipped_file_path
          init_options[:is_gzipped] = true
        end

        return ServeableFile.new(init_options)
      end

      def self.has_static_extension?(path)
        path =~ AssetServer.static_extension_regex
      end

      def encoding_variants?
        return @has_encoding_variants
      end

      def gzipped?
        return @is_gzipped
      end

      def ==(other)
        return false if other.nil?
        return true if self.equal?(other)
        return self.class == other.class &&
          self.gzipped? == other.gzipped? &&
          self.encoding_variants? == other.encoding_variants? &&
          self.path == other.path &&
          self.full_path_info == other.full_path_info
      end
      alias_method :eql?, :==

        private

      # Old last-modified headers encourage caching via browser heuristics. Use it for year-long cached assets.
      CACHE_FRIENDLY_LAST_MODIFIED = 'Mon, 10 Jan 2005 10:00:00 GMT'

      SECONDS_IN = {
        :day => 24*60*60,
        :month => 31*(24*60*60),
        :year => 365*(24*60*60)
      }.freeze

      DEFAULT_STATIC_EXTENSION = '.html'.freeze

      def self.readable_file?(file_path)
        return ::File.file?(file_path) && ::File.readable?(file_path)
      end

    end
  end
end
