# v3.0

module HawthorneCore::User::Name
  extend ActiveSupport::Concern

  included do

    # -----------------------------------------------------------------------------

    # find the users name - cannot label the method 'name' as it is restricted
    def self.user_name(user_id:) = where(user_id:).pick(:name)

    # -----------------------------------------------------------------------------

    # determine if the user has a first name
    def first_name? = name.present?

    # find the first name of the user
    def first_name = first_name? ? name.split(' ').first : nil

    # -----------------------------------------------------------------------------

    # updates a users name
    def update_name(name:)
      update(name:)
      HawthorneCore::UserAction::Log.update_profile(note: { old_name: name_before_last_save, name: })
    end
    def self.update_name(user_id:, name:) = find_by(user_id:).update_name(name:)


    # -----------------------------------------------------------------------------

  end

end