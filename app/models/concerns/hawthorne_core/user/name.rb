# v3.0

module HawthorneCore::User::Name
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # determine if the user has a first name
    def first_name? = name.present?

    # get the first name of the user
    def first_name = first_name? ? name.split(' ').first : nil

    # -----------------------------------------------------------------------------

    # updates a users name
    def update_name(name:)
      update(name:)
      HawthorneCore::UserAction::Log.update_profile(note: { old_name: name_before_last_save, name: })
    end

    # -----------------------------------------------------------------------------

  end

end