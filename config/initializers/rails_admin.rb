# RailsAdmin config file. Generated on July 14, 2012 11:38
# See github.com/sferik/rails_admin for more informations

RailsAdmin.config do |config|

  config.current_user_method { current_user } # auto-generated

  # Or with a PaperTrail: (you need to install it first)
  # config.audit_with :paper_trail, User

  config.main_app_name = ['2u.fm', 'admin']

  config.authorize_with :cancan

  # Application wide tried label methods for models' instances
  config.label_methods << [:name, :title]

  # Your model's configuration, to help you get started:

  # All fields marked as 'hidden' won't be shown anywhere in the rails_admin unless you mark them as visible. (visible(true))

  config.model Artist do
    list do
      field :id
      field :name
      field :created_at
    end
  end

  config.model Blog do
    list do
      field :id
      field :name
      field :url
      field :feed_updated_at
    end
  end

  config.model Post do
    # Found associations:
    list do
      field :id
      field :title
      field :url
      field :blog
    end
  end

  config.model Genre do
    list do
      field :name
      field :includes_remixes
    end
  end

  config.model User do
    list do
      field :full_name
      field :username
      field :sign_in_count
    end
  end

end
