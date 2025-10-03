# Changelog
All notable changes to this project will be documented in this file.

The format is based now on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## 4.0.0 — TBD

### Added

* **New File Uploader Support**: Integrated support for the new [Uploadcare File Uploader](https://uploadcare.com/docs/file-uploader/) based on Web Components, which is 57% lighter and more modern than the legacy widget 3.x.
* **Automatic CSS Loading**: `uploadcare_include_tag` now automatically loads CSS files for the File Uploader from CDN.
* **Three Uploader Modes**: Added support for `regular`, `minimal`, and `inline` uploader modes via the `mode` parameter in `uploadcare_uploader_field`.
* **Multi-Mode CSS Support**: Added `modes` parameter to `uploadcare_include_tag` to load CSS for multiple uploader modes on the same page.
* **Pre-population of Existing Files**: When editing forms, uploader now automatically displays previously uploaded files. Works for both single and multiple file modes.
* **Complete Event Handling**: Added comprehensive event listeners for:
  - `file-upload-success` - successful file upload
  - `file-removed` - file deletion
  - `file-url-changed` - file edited (image transformations applied)
  - `change` - any state change
  - `file-upload-failed` - upload errors
* **Image Editor Integration**: Full support for Uploadcare's cloud image editor with automatic URL transformation handling. Enable via `use_cloud_image_editor` config option.
* **Smart Multiple Files Handling**: Support for multiple storage formats:
  - Official Uploadcare group format: `uuid~5`
  - Comma-separated URLs: `url1,url2,url3`
  - Automatic detection and proper loading of both formats
* **Configuration Options**: Added new configuration parameters for the File Uploader:
  - `img_only` - restrict to image uploads only
  - `max_local_file_size_bytes` - maximum file size limit
  - `source_list` - specify allowed upload sources
  - `use_cloud_image_editor` - enable cloud image editing
  - `confirm_upload` - ask for confirmation before uploading
  - `use_legacy_widget` - switch to legacy widget mode globally
* **Legacy Widget Support**: Full backward compatibility with widget 3.x through `legacy: true` option or `use_legacy_widget` config setting.
* **Per-Field Configuration**: Added ability to pass custom configuration options per uploader field via the `config` parameter.
* **Compatibility Layer**: Added `images_only` as an alias for `img_only` to maintain backward compatibility.
* **Comprehensive Documentation**: Added detailed usage scenarios in README covering all common use cases: creating, editing, multiple files, image editor, etc.

### Changed

* **Breaking**: Default uploader changed from legacy widget 3.x to new File Uploader. To continue using the old widget, set `config.use_legacy_widget = true` or use `legacy: true` option in helpers.
* **Breaking**: `uploadcare_include_tag` now loads the new File Uploader by default. Use `legacy: true` option for old widget.
* **Breaking**: `uploadcare_uploader_field` now generates Web Components (`<uc-config>` and `<uc-file-uploader-*>`) instead of simple input with `role="uploadcare-uploader"`. Legacy mode available via `legacy: true` option.
* Updated configuration template to include new File Uploader options and mark legacy options as deprecated.
* Updated README with comprehensive migration guide from widget 3.x to File Uploader.

### Fixed

* Fixed pre-population of existing files when editing forms - now correctly uses `state.successEntries` array instead of treating state as array.
* Fixed timing issue with Web Components initialization - now waits for `customElements.whenDefined()` before accessing API.
* Fixed `addFileFromCdnUrl` method calls - now properly waits for File Uploader to be fully initialized before adding files.
* Fixed `multiple` attribute - now passes boolean `true` instead of string `"true"` to avoid validation errors.
* Fixed input clearing during file processing - now checks `uploadingCount` before clearing to prevent data loss during transformations.

### Deprecated

* Legacy widget 3.x support is now deprecated. It will be removed in version 5.0.0. Please migrate to the new File Uploader.
* All legacy widget-specific configuration options (`live`, `manual_start`, `preview_step`, `crop`, `clearable`, `tabs`, etc.) are deprecated when using the new File Uploader.

### Migration Guide

See the [Migration from Widget 3.x to File Uploader](#migration-from-widget-3x-to-file-uploader) section in README for detailed migration instructions.

For users who want to continue using the legacy widget temporarily, add to `config/initializers/uploadcare.rb`:

```ruby
config.use_legacy_widget = true
```

Or use the `legacy: true` option in view helpers:

```erb
<%= uploadcare_include_tag legacy: true %>
<%= uploadcare_uploader_field :post, :picture, legacy: true %>
```

## 3.4.4 — 2024-11-07

### Added

* Add mongoid support for `mount_uploadcare_file` and `mount_uploadcare_file_group` methods.

### Breaking Changes

* Drop support for Rails 6.1x in line with the currently supported Rails versions: https://rubyonrails.org/maintenance

## 3.4.3 — 2024-06-01

### Added

* For `Uploadcare::ConversionApi` added `get_document_conversion_formats_info` method to get the possible document conversion formats.

## 3.4.2 — 2024-05-11

### Added

* Added API support for `AWS Rekognition Moderation` Add-On.

## 3.4.1 — 2024-03-24

### Fixed

* Fixed invalid group id error when >= 10 files are uploaded when using `mount_uploadcare_file_group`.

## 3.4.0 — 2024-03-05

### Fixed

* Documentation issue with `uploadcare_include_tag`

### Breaking Changes

* Drop support for Ruby < 3.x
* Drop support for Rails < 6.1x

## 3.3.4 — 2023-04-04

### Changed

* Skipped network requests when the file attribute was unchanged (fixed https://github.com/uploadcare/uploadcare-rails/issues/127)

## 3.3.3 — 2023-03-27

### Changed

* Improved readme to look better at ruby-doc

## 3.3.2.1 — 2023-03-26

### Changed

* Updated links in the gemspec

## 3.3.2 — 2023-03-26

### Changed

* Fixed an issue with the configuration
* Updated the gem documentation

## 3.3.1 — 2023-03-20

### Changed

* Updated gem description
* Respect data-multiple in helper options (https://github.com/uploadcare/uploadcare-rails/issues/119)

## 3.3.0 — 2023-03-16

Guarantee support of maintainable versions of Ruby and Rails.

### Breaking Changes

Drop support of unmaintainable Ruby 2.4, 2.5, 2.6 and Rails before 6.0.

### Added

Add support of Ruby 3.1 and 3.2 and Rails 7.0.

## 3.0.0 — 2022-12-29

This version supports latest Uploadcare REST API — [v0.7](https://uploadcare.com/api-refs/rest-api/v0.7.0/), which introduces new file management features:
* [File metadata](https://uploadcare.com/docs/file-metadata/)
* New [add-ons API](https://uploadcare.com/api-refs/rest-api/v0.7.0/#tag/Add-Ons):
  * [Background removal](https://uploadcare.com/docs/remove-bg/)
  * [Virus checking](https://uploadcare.com/docs/security/malware-protection/)
  * [Object recognition](https://uploadcare.com/docs/intelligence/object-recognition/)

### Breaking Changes

- For `Uploadcare::FileApi#get_file`
  - File information doesn't return `image_info` and `video_info` fields anymore
  - Removed `rekognition_info` in favor of `appdata`
  - Parameter `add_fields` was renamed to `include`
- For `Uploadcare::FileApi#get_files`
  - Removed the option of sorting the file list by file size
- For `Uploadcare::GroupApi#store_group`
  - Changed response format
- For `Uploadcare::FileApi`
  - Removed method `copy_file` in favor of `local_copy_file` and `remote_copy_file` methods

### Changed

- For `Uploadcare::FileApi#get_file`
  - Field `content_info` that includes mime-type, image (dimensions, format, etc), video information (duration, format, bitrate, etc), audio information, etc
  - Field `metadata` that includes arbitrary metadata associated with a file
  - Field `appdata` that includes dictionary of application names and data associated with these applications

### Added

- Add Uploadcare API interface:
  - `Uploadcare::FileMetadataApi`
  - `Uploadcare::AddonsApi`
- Added an option to delete a Group
- For `Uploadcare::FileApi` add `local_copy_file` and `remote_copy_file` methods

## 2.1.1 2022-05-13
### Fix

Fixed Rails 4 tests by enforcing https.

## 2.1.0 2021-11-16
### Added

- Option `signing_secret` in the `Uploadcare::WebhookApi`.

## 2.0.0 - 2021-10-11
### :heavy_exclamation_mark: *Note: the gem uploadcare-rails 2.x is not backward compatible with 1.x.*

### Added

- Add Uploadcare API interface:
  - Uploadcare::FileApi
  - Uploadcare::UploadApi
  - Uploadcare::GroupApi
  - Uploadcare::ConversionApi
  - Uploadcare::ProjectApi
  - Uploadcare::WebhookApi
- Add uploadcare_widget_tag helper for views
- Add methods File#store, File#delete, File#load
- Add methods Group#transform_file_urls, Group#store, Group#load

### Changed

- Change File Uploader widget view helpers
- Rename has_uploadcare_file -> mount_uploadcare_file
- Rename has_uploadcare_group -> mount_uploadcare_file_group
- Change generated config path from config/uploadcare.yml to config/initializers/uploadcare.rb and add more options
- Rename the class `Uploadcare::Rails::Settings` to `Uploadcare::Rails::Configuration`
- Rename the class `Uploadcare::Rails::Operations` to `Uploadcare::Rails::Transformations::ImageTransformations`.
Configuration object is available as `Uploadcare::Rails.configuration` now
- Change methods File#url -> File#transform_url
- Change methods Group#urls -> Group#file_urls
- Change methods Group#load_data -> Group#load

### Removed

- Remove uploadcare_uploader_tag helper
- Remove uploadcare_multiple_uploader_field helper
- Remove uploadcare_single_uploader_field helper
- Remove uploadcare_uploader_options (now options are included in uploadcare_widget_tag)
- Remove FormBuilder support
- Remove Formtastic support
- Remove SimpleForm support
- Remove caching files and groups on delete
- Remove callback ```ruby after_save after_save "store_#{ attribute }".to_sym```. Now managed by the `do_not_store` option in `config/initializers/uploadcare.rb`
- Remove methods File#prepared_operations, File#to_builder, File#to_json, File#as_json, File#marshal_dump, File#image
- Remove methods Group#cache_data, Group#to_json, Group#as_json, Group#map_files, Group#load_data!, Group#marshal_dump

## 1.2.1 - 2018-10-01
### Fixed
- Allow to use multiple files or groups

## 1.2.0 - 2018-06-03

## 1.2.0-alpha3 - 2018-05-29
### Fixed

- Require `uploadcare/rails/version` in `lib/uploadcare-rails.rb`

## 1.2.0-alpha2 - 2018-05-28 - YANKED
### Changed
- Gem now reports us your `uploadcare-rails` and `rails` versions using the User-Agent header (overridable via config)
- `uploadcare-ruby` gem version bumped to 1.2.x


## 1.2.0-alpha - 2018-04-18
### Changed
- Allow gem in rails 5.2
- Update default widget version to 3.x

### Removed
- Tests against Ruby 2.0 and 2.1 that [had reached their EOL](https://www.ruby-lang.org/en/downloads/branches/)


## 1.1.1 - 2017-11-07
### Fixed
- Uploadcare config generator
- Issues preventing the gem to be used with rails 5.1


## 1.1.0 - 2016-07-12
### Added
- Removed widget from the asset pipeline. It is expected to use helper or to append to the asset pipeline manually.
- Operations for image_tag helpers.

### Fixed
- Bug with creating object with empty file or file_group.
- Workaround to remove unnecessary API-calls for groups of images.

### Development
- Tests have been refactored, VCR appended to development environment.
- Tests performance improvements.
