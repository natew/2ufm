module CommonScopes
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.instance_eval do
      scope :has_image, where("#{self.to_s.tableize}.image_file_name is not null")
    end
  end
end