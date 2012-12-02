class SlugValidator < ActiveModel::Validator
  def validate(record)
    if record.slug =~ /^(my|do|go|users|tags|genres|songs-new|activity|genres|blogs|stations|follows|broadcasts|listens|l|songs|search|mac|loading|admin|delayed_job_admin)$/
      record.errors[:base] << 'Cannot use, restricted name'
    end
  end
end