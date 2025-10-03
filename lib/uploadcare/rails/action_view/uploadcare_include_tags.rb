# frozen_string_literal: true

require 'action_view'
require 'uploadcare/rails/configuration'

module Uploadcare
  module Rails
    module ActionView
      # A module containing a view include tags helper
      module UploadcareWidgetTags
        # A view helper to add the new File Uploader script and styles from CDN.
        # See https://uploadcare.com/docs/file-uploader/ for more info.
        #
        # Example:
        #   <%= uploadcare_include_tag %>
        #   => <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@uploadcare/file-uploader@v1/web/uc-file-uploader-regular.min.css">
        #      <script type="module">
        #        import * as UC from "https://cdn.jsdelivr.net/npm/@uploadcare/file-uploader@v1/web/file-uploader.min.js";
        #        UC.defineComponents(UC);
        #      </script>
        #
        # Arguments:
        #   version: (String, default: 'v1') - version of the File Uploader
        #   min: (true/false, default: true) - sets which version to get, minified or not
        #   modes: (Array, default: ['regular']) - uploader modes to load CSS for: 'regular', 'minimal', 'inline'

        def uploadcare_include_tag(version: 'v1', min: true, modes: ['regular'])

          min_suffix = min ? '.min' : ''
          js_cdn_url = "https://cdn.jsdelivr.net/npm/@uploadcare/file-uploader@#{version}/web/file-uploader#{min_suffix}.js"

          # CSS links for each mode
          css_tags = modes.map do |mode|
            css_cdn_url = "https://cdn.jsdelivr.net/npm/@uploadcare/file-uploader@#{version}/web/uc-file-uploader-#{mode}#{min_suffix}.css"
            stylesheet_link_tag(css_cdn_url)
          end.join.html_safe

          # JavaScript module
          js_tag = content_tag(:script, type: 'module') do
            %(
              import * as UC from "#{js_cdn_url}";
              UC.defineComponents(UC);
            ).html_safe
          end

          safe_join([css_tags, js_tag])
        end
      end
    end
  end
end

ActionView::Base.include Uploadcare::Rails::ActionView::UploadcareWidgetTags
