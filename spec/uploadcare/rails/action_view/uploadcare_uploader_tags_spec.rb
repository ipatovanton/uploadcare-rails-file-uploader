# frozen_string_literal: true

require 'spec_helper'
require 'uploadcare/rails/action_view/uploadcare_uploader_tags'

describe Uploadcare::Rails::ActionView::UploadcareUploaderTags, type: :helper do
  before do
    allow(Uploadcare::Rails.configuration).to receive(:public_key).and_return('test_public_key')
  end

  describe '#uploadcare_uploader_field' do
    it 'generates Web Components with uc-config' do
      tag = uploadcare_uploader_field(:post, :title)

      expect(tag).to include('<uc-config')
      expect(tag).to include('ctx-name="post-title"')
      expect(tag).to include('pubkey="test_public_key"')
    end

    it 'generates uc-file-uploader-regular component' do
      tag = uploadcare_uploader_field(:post, :title)

      expect(tag).to include('<uc-file-uploader-regular')
      expect(tag).to include('ctx-name="post-title"')
      expect(tag).to include('class="uploadcare-uploader"')
    end

    it 'generates uc-upload-ctx-provider component' do
      tag = uploadcare_uploader_field(:post, :title)

      expect(tag).to include('<uc-upload-ctx-provider')
      expect(tag).to include('ctx-name="post-title"')
    end

    it 'includes hidden field for form submission' do
      tag = uploadcare_uploader_field(:post, :title)

      expect(tag).to include('<input')
      expect(tag).to include('type="hidden"')
      expect(tag).to include('name="post[title]"')
      expect(tag).to include('id="post_title"')
    end

    it 'sets multiple="false" for single upload by default' do
      tag = uploadcare_uploader_field(:post, :title)

      expect(tag).to include('multiple="false"')
      expect(tag).not_to include('multiple="true"')
      expect(tag).not_to include('multiple="multiple"')
    end

    it 'supports different uploader modes' do
      tag = uploadcare_uploader_field(:post, :title, mode: 'minimal')

      expect(tag).to include('<uc-file-uploader-minimal')
      expect(tag).not_to include('<uc-file-uploader-regular')
    end

    it 'passes custom config options to uc-config' do
      tag = uploadcare_uploader_field(:post, :title, config: { locale: 'en' })

      expect(tag).to include('locale="en"')
    end

    it 'ignores invalid multiple value from config options' do
      tag = uploadcare_uploader_field(:post, :title, config: { multiple: 'multiple' })

      # Should have correct value based on is_multiple, not the invalid value
      expect(tag).to include('multiple="false"')
      expect(tag).not_to include('multiple="multiple"')
    end

    it 'includes initialization JavaScript' do
      tag = uploadcare_uploader_field(:post, :title)

      expect(tag).to include('<script>')
      expect(tag).to include('customElements.whenDefined')
      expect(tag).to include('uc-file-uploader-regular')
    end
  end

  describe '#uploadcare_uploader_field_tag' do
    it 'generates Web Components for standalone field' do
      tag = uploadcare_uploader_field_tag(:avatar)

      expect(tag).to include('<uc-config')
      expect(tag).to include('<uc-file-uploader-regular')
      expect(tag).to include('<uc-upload-ctx-provider')
    end

    it 'sets multiple="false" when multiple option is false' do
      tag = uploadcare_uploader_field_tag(:avatar, multiple: false)

      expect(tag).to include('multiple="false"')
      expect(tag).not_to include('multiple="true"')
    end

    it 'sets multiple="true" when multiple option is true' do
      tag = uploadcare_uploader_field_tag(:avatar, multiple: true)

      expect(tag).to include('multiple="true"')
      expect(tag).not_to include('multiple="false"')
    end

    it 'includes hidden field with provided value' do
      tag = uploadcare_uploader_field_tag(:avatar, value: 'https://ucarecdn.com/test/')

      expect(tag).to include('<input')
      expect(tag).to include('type="hidden"')
      expect(tag).to include('name="avatar"')
    end
  end
end

RSpec.configure do |c|
  c.include Uploadcare::Rails::ActionView::UploadcareUploaderTags, type: :helper
end
