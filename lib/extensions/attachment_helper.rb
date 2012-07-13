module AttachmentHelper
  class << self
    def included(base)
      base.extend ClassMethods
    end
  end

  module ClassMethods
    def has_attachment(name, options = {})

      # generates a string containing the singular model name and the pluralized attachment name.
      # Examples: "user_avatars" or "asset_uploads" or "message_previews"
      attachment_owner    = self.table_name.singularize
      attachment_folder   = "#{attachment_owner}_#{name.to_s.pluralize}"

      # we want to create a path for the upload that looks like:
      # message_previews/00/11/22/001122deadbeef/thumbnail.png
      attachment_path     = "#{attachment_folder}/:id_:style.:extension"

      options[:path]           ||= attachment_path
      options[:storage]        ||= :s3
      options[:s3_credentials] ||= File.join(Rails.root, 'config', 'amazon_s3.yml')
      options[:s3_permissions] ||= 'private'

      # Use s3 in production
      if Rails.env.production?
        options[:bucket] ||= '2u-songs'
      else
        options[:bucket] ||= '2u-songs-development'

        # For local Dev/Test envs, use the default filesystem, but separate the environments
        # into different folders, so you can delete test files without breaking dev files.
        # rails_env        = Rails.env
        # options[:path] ||= ":rails_root/public/attachments/#{rails_env}/#{attachment_path}"
        # options[:url]  ||= "/attachments/#{rails_env}/#{attachment_path}"
      end

      options[:default_url] ||= '/images/default.png'

      # pass things off to paperclip.
      has_attached_file name, options
    end
  end
end