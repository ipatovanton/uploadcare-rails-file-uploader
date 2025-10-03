# frozen_string_literal: true

require 'action_view'
require 'uploadcare/rails/configuration'

module Uploadcare
  module Rails
    module ActionView
      # A module containing a view field helper
      module UploadcareUploaderTags
        # A view helper to add the new File Uploader component to a html-page
        # See https://uploadcare.com/docs/file-uploader/ for more info.
        #
        # Example:
        #   <%= uploadcare_uploader_field :post, :picture %>
        #   => <uc-config ctx-name="post-picture" pubkey="demopublickey"></uc-config>
        #      <uc-file-uploader-regular ctx-name="post-picture" class="uploadcare-uploader"></uc-file-uploader-regular>
        #      <input type="hidden" name="post[picture]" id="post_picture">
        #
        # Arguments:
        #   object_name: (String/Symbol) - object name which a field belongs to
        #   method_name: (String/Symbol) - object method name
        #   options: (Hash, default: {}) - options for the uploader
        #     mode: (String, default: 'regular') - uploader mode: 'regular', 'minimal', 'inline'
        #     config: (Hash, default: {}) - configuration options for uc-config

        def uploadcare_uploader_field(object_name, method_name, options = {})
          mode = options.delete(:mode) || 'regular'
          config_options = options.delete(:config) || {}

          ctx_name = "#{object_name}-#{method_name}"
          is_multiple = uploadcare_uploader_multiple?(object_name, method_name)

          # Get current value from object instance for pre-population
          current_value = get_current_uploadcare_value(object_name, method_name)

          # Build uc-config tag
          config_attrs = {
            :'ctx-name' => ctx_name,
            :pubkey => Uploadcare::Rails.configuration.public_key
          }.merge(uploadcare_config_attributes(config_options, is_multiple))

          # Build uc-config manually because Rails tag helper treats 'multiple' as boolean HTML attribute
          # and converts it to multiple="multiple" instead of multiple="true"/"false"
          attrs_string = config_attrs.map { |k, v| "#{k}=\"#{ERB::Util.html_escape(v)}\"" }.join(' ')
          config_tag = "<uc-config #{attrs_string}></uc-config>".html_safe

          # Build uc-upload-ctx-provider (context provider for API access)
          ctx_provider_tag = tag.send('uc-upload-ctx-provider', 'ctx-name': ctx_name)

          # Build uc-file-uploader-* tag
          uploader_component = "uc-file-uploader-#{mode}"
          uploader_attrs = {
            'ctx-name': ctx_name,
            'class': 'uploadcare-uploader'
          }
          # Add data attribute for initial value if exists
          uploader_attrs['data-initial-value'] = current_value if current_value.present?

          uploader_tag = tag.send(uploader_component, **uploader_attrs)

          # File count indicator (clickable to open dialog)
          file_count_id = "#{ctx_name}-file-count"
          file_count_tag = tag.span('',
            id: file_count_id,
            class: 'uploadcare-file-count',
            style: 'cursor: pointer; color: #157cfc; text-decoration: underline; display: none;',
            title: 'Click to manage files')

          # Hidden field to store the result with initial value
          hidden_tag = hidden_field(object_name, method_name,
            id: "#{object_name}_#{method_name}",
            value: current_value)

          # JavaScript to sync uploader output with hidden field
          script_tag = javascript_tag(<<~JS)
            (function() {
              // Wait for Web Components to be defined before initializing
              Promise.all([
                customElements.whenDefined('uc-config'),
                customElements.whenDefined('uc-upload-ctx-provider'),
                customElements.whenDefined('#{uploader_component}')
              ]).then(() => {
                // Add small delay to ensure components are fully initialized
                setTimeout(() => {
                  initUploader();
                }, 100);
              }).catch(err => {
                console.error('Error waiting for Uploadcare components:', err);
              });

              function initUploader() {
                const ctxProvider = document.querySelector('uc-upload-ctx-provider[ctx-name="#{ctx_name}"]');
                const input = document.getElementById('#{object_name}_#{method_name}');
                const uploaderElement = document.querySelector('#{uploader_component}[ctx-name="#{ctx_name}"]');
                const fileCountElement = document.getElementById('#{file_count_id}');
                const isMultiple = #{is_multiple};

                if (!ctxProvider || !input) {
                  console.error('Uploadcare: ctxProvider or input not found');
                  return;
                }

                // Function to update file count indicator
                function updateFileCount(count) {
                  if (!fileCountElement) return;

                  if (count > 0) {
                    const label = count === 1 ? 'image' : 'files';
                    fileCountElement.textContent = `${count} ${label}`;
                    fileCountElement.style.display = 'inline';
                  } else {
                    fileCountElement.style.display = 'none';
                  }
                }

                // Make file count clickable to open uploader dialog
                if (fileCountElement) {
                  fileCountElement.addEventListener('click', () => {
                    const api = ctxProvider.getAPI ? ctxProvider.getAPI() : ctxProvider;
                    if (api.initFlow) {
                      api.initFlow();
                    }
                  });
                }

              // Function to update hidden input from uploader state
              function updateHiddenInput() {
                const api = ctxProvider.getAPI ? ctxProvider.getAPI() : ctxProvider;
                const state = api.getOutputCollectionState ? api.getOutputCollectionState() : null;
                if (!state) return;

                // getOutputCollectionState() returns an object with successEntries array
                const successFiles = state.successEntries || [];

                // Update file count indicator
                updateFileCount(successFiles.length);

                // Don't clear input if files are still uploading/processing
                if (successFiles.length === 0 && state.uploadingCount === 0) {
                  input.value = '';
                } else if (successFiles.length > 0) {
                  if (isMultiple) {
                    input.value = successFiles.map(f => f.cdnUrl).join(',');
                  } else {
                    input.value = successFiles[0].cdnUrl;
                  }
                }

                console.log('Updated input value:', input.value);
              }

              // Pre-populate existing files
              const initialValue = uploaderElement?.dataset?.initialValue;
              if (initialValue) {
                console.log('Pre-populating files:', initialValue);

                // Get API from context provider
                const api = ctxProvider.getAPI ? ctxProvider.getAPI() : ctxProvider;

                if (isMultiple && initialValue.includes(',')) {
                  // Multiple files separated by comma
                  const urls = initialValue.split(',').map(url => url.trim()).filter(url => url);
                  urls.forEach(url => {
                    try {
                      if (api.addFileFromCdnUrl) {
                        api.addFileFromCdnUrl(url);
                      } else {
                        console.error('addFileFromCdnUrl not available');
                      }
                    } catch (err) {
                      console.error('Failed to add file:', url, err);
                    }
                  });
                } else if (initialValue) {
                  // Single file
                  try {
                    if (api.addFileFromCdnUrl) {
                      api.addFileFromCdnUrl(initialValue);
                    } else {
                      console.error('addFileFromCdnUrl not available');
                    }
                  } catch (err) {
                    console.error('Failed to add file:', initialValue, err);
                  }
                }
              }

              // Event handlers
              ctxProvider.addEventListener('file-upload-success', (e) => {
                console.log('File uploaded:', e.detail);
                updateHiddenInput();
              });

              ctxProvider.addEventListener('file-removed', (e) => {
                console.log('File removed:', e.detail);
                updateHiddenInput();
              });

              ctxProvider.addEventListener('change', (e) => {
                console.log('Upload state changed:', e.detail);
                updateHiddenInput();
              });

              ctxProvider.addEventListener('file-url-changed', (e) => {
                console.log('File URL changed (edited):', e.detail);
                updateHiddenInput();
              });

              ctxProvider.addEventListener('file-upload-failed', (e) => {
                console.error('File upload failed:', e.detail);
              });
              }
            })();
          JS

          safe_join([config_tag, ctx_provider_tag, uploader_tag, file_count_tag, hidden_tag, script_tag])
        end

        def uploadcare_uploader_field_tag(object_name, options = {})
          mode = options.delete(:mode) || 'regular'
          value = options.delete(:value)
          config_options = options.delete(:config) || {}

          ctx_name = object_name.to_s.parameterize
          is_multiple = options[:multiple] || false

          config_attrs = {
            :'ctx-name' => ctx_name,
            :pubkey => Uploadcare::Rails.configuration.public_key
          }.merge(uploadcare_config_attributes(config_options, is_multiple))

          # Build uc-config manually because Rails tag helper treats 'multiple' as boolean HTML attribute
          # and converts it to multiple="multiple" instead of multiple="true"/"false"
          attrs_string = config_attrs.map { |k, v| "#{k}=\"#{ERB::Util.html_escape(v)}\"" }.join(' ')
          config_tag = "<uc-config #{attrs_string}></uc-config>".html_safe

          # Build uc-upload-ctx-provider
          ctx_provider_tag = tag.send('uc-upload-ctx-provider', 'ctx-name': ctx_name)

          uploader_component = "uc-file-uploader-#{mode}"
          uploader_attrs = {
            'ctx-name': ctx_name,
            'class': 'uploadcare-uploader'
          }
          # Add data attribute for initial value if exists
          uploader_attrs['data-initial-value'] = value if value.present?

          uploader_tag = tag.send(uploader_component, **uploader_attrs)

          # File count indicator (clickable to open dialog)
          file_count_id = "#{ctx_name}-file-count"
          file_count_tag = tag.span('',
            id: file_count_id,
            class: 'uploadcare-file-count',
            style: 'cursor: pointer; color: #157cfc; text-decoration: underline; display: none;',
            title: 'Click to manage files')

          hidden_tag = hidden_field_tag(object_name, value, id: ctx_name)

          script_tag = javascript_tag(<<~JS)
            (function() {
              // Wait for Web Components to be defined before initializing
              Promise.all([
                customElements.whenDefined('uc-config'),
                customElements.whenDefined('uc-upload-ctx-provider'),
                customElements.whenDefined('#{uploader_component}')
              ]).then(() => {
                // Add small delay to ensure components are fully initialized
                setTimeout(() => {
                  initUploader();
                }, 100);
              }).catch(err => {
                console.error('Error waiting for Uploadcare components:', err);
              });

              function initUploader() {
                const ctxProvider = document.querySelector('uc-upload-ctx-provider[ctx-name="#{ctx_name}"]');
                const input = document.getElementById('#{ctx_name}');
                const uploaderElement = document.querySelector('#{uploader_component}[ctx-name="#{ctx_name}"]');
                const fileCountElement = document.getElementById('#{file_count_id}');
                const isMultiple = #{is_multiple};

                if (!ctxProvider || !input) {
                  console.error('Uploadcare: ctxProvider or input not found');
                  return;
                }

                // Function to update file count indicator
                function updateFileCount(count) {
                  if (!fileCountElement) return;

                  if (count > 0) {
                    const label = count === 1 ? 'image' : 'files';
                    fileCountElement.textContent = `${count} ${label}`;
                    fileCountElement.style.display = 'inline';
                  } else {
                    fileCountElement.style.display = 'none';
                  }
                }

                // Make file count clickable to open uploader dialog
                if (fileCountElement) {
                  fileCountElement.addEventListener('click', () => {
                    const api = ctxProvider.getAPI ? ctxProvider.getAPI() : ctxProvider;
                    if (api.initFlow) {
                      api.initFlow();
                    }
                  });
                }

              // Function to update hidden input from uploader state
              function updateHiddenInput() {
                const api = ctxProvider.getAPI ? ctxProvider.getAPI() : ctxProvider;
                const state = api.getOutputCollectionState ? api.getOutputCollectionState() : null;
                if (!state) return;

                // getOutputCollectionState() returns an object with successEntries array
                const successFiles = state.successEntries || [];

                // Update file count indicator
                updateFileCount(successFiles.length);

                // Don't clear input if files are still uploading/processing
                if (successFiles.length === 0 && state.uploadingCount === 0) {
                  input.value = '';
                } else if (successFiles.length > 0) {
                  if (isMultiple) {
                    input.value = successFiles.map(f => f.cdnUrl).join(',');
                  } else {
                    input.value = successFiles[0].cdnUrl;
                  }
                }

                console.log('Updated input value:', input.value);
              }

              // Pre-populate existing files
              const initialValue = uploaderElement?.dataset?.initialValue;
              if (initialValue) {
                console.log('Pre-populating files:', initialValue);

                // Get API from context provider
                const api = ctxProvider.getAPI ? ctxProvider.getAPI() : ctxProvider;

                if (isMultiple && initialValue.includes(',')) {
                  // Multiple files separated by comma
                  const urls = initialValue.split(',').map(url => url.trim()).filter(url => url);
                  urls.forEach(url => {
                    try {
                      if (api.addFileFromCdnUrl) {
                        api.addFileFromCdnUrl(url);
                      } else {
                        console.error('addFileFromCdnUrl not available');
                      }
                    } catch (err) {
                      console.error('Failed to add file:', url, err);
                    }
                  });
                } else if (initialValue) {
                  // Single file
                  try {
                    if (api.addFileFromCdnUrl) {
                      api.addFileFromCdnUrl(initialValue);
                    } else {
                      console.error('addFileFromCdnUrl not available');
                    }
                  } catch (err) {
                    console.error('Failed to add file:', initialValue, err);
                  }
                }
              }

              // Event handlers
              ctxProvider.addEventListener('file-upload-success', (e) => {
                console.log('File uploaded:', e.detail);
                updateHiddenInput();
              });

              ctxProvider.addEventListener('file-removed', (e) => {
                console.log('File removed:', e.detail);
                updateHiddenInput();
              });

              ctxProvider.addEventListener('change', (e) => {
                console.log('Upload state changed:', e.detail);
                updateHiddenInput();
              });

              ctxProvider.addEventListener('file-url-changed', (e) => {
                console.log('File URL changed (edited):', e.detail);
                updateHiddenInput();
              });

              ctxProvider.addEventListener('file-upload-failed', (e) => {
                console.error('File upload failed:', e.detail);
              });
              }
            })();
          JS

          safe_join([config_tag, ctx_provider_tag, uploader_tag, file_count_tag, hidden_tag, script_tag])
        end

        private

        def get_current_uploadcare_value(object_name, method_name)
          # Try to get object instance from instance variables
          object = instance_variable_get("@#{object_name}")
          return nil unless object.respond_to?(:read_attribute)

          # Get raw value from database (not the wrapped Uploadcare::File object)
          object.read_attribute(method_name).to_s.presence
        end

        def uploadcare_uploader_multiple?(object_name, method_name)
          model = object_name.to_s.camelize.safe_constantize
          method_name = "has_uploadcare_file_group_for_#{method_name}?"
          model.respond_to?(method_name) && model.public_send(method_name)
        end

        def uploadcare_config_attributes(config_options, is_multiple)
          attrs = {}

          # Map configuration options to attributes first
          config = Uploadcare::Rails.configuration

          # Normalize config_options keys to symbols to prevent string/symbol key conflicts
          normalized_options = config_options.transform_keys { |k| k.to_s.underscore.to_sym }

          # Add locale if present
          locale_value = normalized_options[:locale] || config.locale
          attrs[:locale] = normalize_attr_value(locale_value) if locale_value

          # Add any custom config options (skip multiple - we handle it separately)
          normalized_options.each do |key, value|
            # Skip special keys that are handled separately
            next if %i[locale multiple].include?(key)
            attr_name = key.to_s.dasherize.to_sym
            # Skip if value is the same as the key (invalid) or if already exists
            next if value.to_s == key.to_s || attrs.key?(attr_name)
            # Normalize boolean values to strings for consistency
            attrs[attr_name] = normalize_attr_value(value)
          end

          # Add img_only from global config if not already set
          if config.images_only && !attrs.key?(:'img-only')
            attrs[:'img-only'] = 'true'
          end

          # Always add multiple attribute explicitly at the end (as string per Uploadcare docs)
          # This ensures we override any incorrect values from config_options
          attrs[:multiple] = is_multiple ? 'true' : 'false'

          attrs.compact
        end

        def normalize_attr_value(value)
          case value
          when TrueClass
            'true'
          when FalseClass
            'false'
          else
            value.to_s
          end
        end
      end
    end
  end
end

ActionView::Base.include Uploadcare::Rails::ActionView::UploadcareUploaderTags
