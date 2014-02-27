ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
  :access_key_id     => 'CHANGE_ME',
  :secret_access_key => 'CHANGE_ME'