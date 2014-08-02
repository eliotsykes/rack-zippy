# path_info needed on ServeableFile?? Try removing it.



def test_request_for_assets_root_responds_with_index_html_if_possible
        flunk
      end

      def test_request_for_assets_root_responds_with_assets_html_if_possible
        flunk
      end


      def test_serves_static_file_in_directory
        flunk
        assert_html "/foo/bar.html", get("/foo/bar.html")
        assert_html "/foo/bar.html", get("/foo/bar/")
        assert_html "/foo/bar.html", get("/foo/bar")
      end

      def test_serves_static_index_file_in_directory
        flunk
        assert_html "/foo/index.html", get("/foo/index.html")
        assert_html "/foo/index.html", get("/foo/")
        assert_html "/foo/index.html", get("/foo")
      end
