# v3.0XXX

module HawthorneCore::HasSmallWebId
  extend ActiveSupport::Concern

  included do

    # ---------------------------------------------------------------------------------

    # length of 1: 36 unique values
    # length of 2: 1,296
    # length of 3: 46,656
    # length of 4: 1,679,616 (1.6 million)
    # length of 5: 60,466,176 (60 million)
    # length of 6: 2,176,782,336 (2.1 billion)
    # length of 7: 78,364,164,096 (78 billion)
    # length of 8: 2,821,109,907,453 (2.8 trillion)

    # ---------------------------------------------------------------------------------

    SMALL_WEB_ID_LENGTHS =
      {
        'designers' => 4,
        'fabric_collections' => 4,
        'fabric_collection_theme_types' => 2,
        'fabric_type_genres' => 2,
        'products' => 5,
        'site_users' => 8,
        'suppliers' => 3,
        'thread_color_types' => 3,
        'thread_products' => 4
      }.freeze

    # ---------------------------------------------------------------------------------

    # set a small web id value to the object
    # the length of the id is based on the object type (table name)
    def set_small_web_id

      # return if the object already has a small web id
      return if small_web_id.present?

      # assign the id length by table name
      # return if the id length is not set
      length = SMALL_WEB_ID_LENGTHS[self.class.table_name]
      return if length.zero?

      # create the small web id, then save it
      small_web_id = generate_unique_small_web_id(length)
      update_column(:small_web_id, small_web_id)

    end

    # ---------------------------------------------------------------------------------

    private

    # generates a (unique) small web id at a specified length
    # if the id is already in use, generates another
    def generate_unique_small_web_id(length)
      loop do
        candidate = SecureRandom.alphanumeric(length).upcase
        return candidate unless self.class.exists?(small_web_id: candidate)
      end
    end

    # ---------------------------------------------------------------------------------

  end

end