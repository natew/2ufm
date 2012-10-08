# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Fusefm::Application.initialize!

# Page type
Mime::Type.register "text/page", :page
Mime::Type.register "text/partial", :partial