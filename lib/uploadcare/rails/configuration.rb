# frozen_string_literal: true

require 'singleton'

module Uploadcare
  module Rails
    # A class for storing config parameters
    class Configuration
      include Singleton

      CONFIG_GLOBAL_PARAMS = %w[
        public_key secret_key cache_files cache_expires_in cache_namespace
        store_files_after_save store_files_async
        delete_files_after_destroy delete_files_async
        do_not_store
      ].freeze

      # File Uploader parameters
      WIDGET_PARAMS = %w[
        public_key img_only max_local_file_size_bytes source_list
        use_cloud_image_editor locale confirm_upload store
      ].freeze

      attr_accessor(*(CONFIG_GLOBAL_PARAMS + WIDGET_PARAMS).uniq)

      def widget
        Struct
          .new(*WIDGET_PARAMS.map(&:to_sym))
          .new(*WIDGET_PARAMS.map { |param| public_send(param) })
      end

      # Compatibility layer: map old param names to new ones
      alias_method :images_only, :img_only
      alias_method :images_only=, :img_only=
    end
  end
end
