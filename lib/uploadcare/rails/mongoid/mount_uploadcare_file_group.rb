# frozen_string_literal: true

require 'mongoid'
require 'active_support/concern'
require 'uploadcare/rails/services/id_extractor'
require 'uploadcare/rails/services/files_count_extractor'
require 'uploadcare/rails/jobs/store_group_job'
require 'uploadcare/rails/objects/group'

module Uploadcare
  module Rails
    module Mongoid
      # A module containing Mongoid extension. Allows to use uploadcare group methods in Rails models
      module MountUploadcareFileGroup
        extend ActiveSupport::Concern

        GROUP_ID_REGEX = /\b[0-9a-f]{8}\b-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-\b[0-9a-f]{12}\b~\d+/.freeze

        def build_uploadcare_file_group(attribute)
          cdn_url = read_attribute(attribute).to_s
          return if cdn_url.empty?

          # Support both formats:
          # 1. Group ID: "uuid~5" (official Uploadcare format)
          # 2. Comma-separated URLs: "https://ucarecdn.com/uuid1/,https://ucarecdn.com/uuid2/"
          if cdn_url.match?(GROUP_ID_REGEX)
            # Official group format
            group_id = IdExtractor.call(cdn_url, GROUP_ID_REGEX).presence
            cache_key = Group.build_cache_key(cdn_url)
            files_count = FilesCountExtractor.call(group_id)
            default_attributes = { cdn_url: cdn_url, id: group_id, files_count: files_count }
            file_attributes = ::Rails.cache.read(cache_key).presence || default_attributes
            Uploadcare::Rails::Group.new(file_attributes)
          elsif cdn_url.include?(',')
            # Comma-separated URLs format (for compatibility)
            urls = cdn_url.split(',').map(&:strip).reject(&:empty?)
            files_count = urls.count
            # Create a virtual group representation
            default_attributes = {
              cdn_url: cdn_url,
              id: nil,
              files_count: files_count,
              file_urls: urls
            }
            Uploadcare::Rails::Group.new(default_attributes)
          else
            # Single URL (treat as group of 1)
            default_attributes = {
              cdn_url: cdn_url,
              id: nil,
              files_count: 1,
              file_urls: [cdn_url]
            }
            Uploadcare::Rails::Group.new(default_attributes)
          end
        end

        class_methods do
          # rubocop:disable Metrics/MethodLength
          def mount_uploadcare_file_group(attribute)
            # Ensure the field exists in Mongoid
            field attribute, type: String unless fields.key?(attribute.to_s)

            define_singleton_method "has_uploadcare_file_group_for_#{attribute}?" do
              true
            end

            define_method attribute do
              build_uploadcare_file_group attribute
            end

            define_method "uploadcare_store_#{attribute}!" do |store_job = StoreGroupJob|
              group_id = public_send(attribute)&.id
              return unless group_id
              return store_job.perform_later(group_id) if Uploadcare::Rails.configuration.store_files_async

              Uploadcare::GroupApi.store_group(group_id)
            end

            return if Uploadcare::Rails.configuration.do_not_store

            set_callback :save, :after, :"uploadcare_store_#{attribute}!"
          end
          # rubocop:enable Metrics/MethodLength
        end
      end
    end
  end
end

Mongoid::Document.include Uploadcare::Rails::Mongoid::MountUploadcareFileGroup
