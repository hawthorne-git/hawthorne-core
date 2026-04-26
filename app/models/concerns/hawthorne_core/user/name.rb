# v3.0

module HawthorneCore::User::Name
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # get the first name of the user
    def first_name = full_name.present? ? full_name.split(' ').first : ''

    # determine if the user has a first name
    def first_name? = full_name.present?

    # -----------------------------------------------------------------------------

    # updates a users full name
    def update_full_name(full_name:)
      update(full_name: full_name)
      HawthorneCore::UserAction::Log.update_profile(note: { old_full_name: full_name_before_last_save, new_full_name: full_name })
    end

    # -----------------------------------------------------------------------------

  end

end