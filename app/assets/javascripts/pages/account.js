$('#user_preference_attributes_digests').change(updateEmailCheckboxes).trigger('change');

function updateEmailCheckboxes() {
  if ($(this).val() == 'none') {
    $('#user-email-preferences').removeClass('disabled');
    $('#user-email-preferences input[type="checkbox"]:not(:checked)').click();
  } else {
    $('#user-email-preferences').addClass('disabled');
    $('#user-email-preferences input[type="checkbox"]:checked').click();
  }
}