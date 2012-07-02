class SlugValidator < ActiveModel::Validator
  def validate(record)
    if record.slug =~ /^(users|songs-new|activity|genres|blogs|stations|follows|broadcasts|listens|l|songs|search|mac|loading|admin|delayed_job_admin)$/
      record.errors[:base] << 'Cannot use, restricted name'
    end
  end
end