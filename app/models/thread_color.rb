class ThreadColor < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # a blank number is saved as null, so a color without one is unique by its name alone (see handle's uniqueness)
  normalizes :handle, with: ->(handle) { handle.strip }
  normalizes :color_nbr, with: ->(color_nbr) { color_nbr.strip.presence }

  validates :handle, presence: true
  # a color is its number and name together, unique within its brand: a brand may reuse a number for another color (ex:
  # Mettler 0020 is Rough Sea in Metrosene and Black in Poly Sheen), or a name under another number (ex: Mettler 0091
  # and 6051 are both Jalapeno); a brand without color numbers tells its colors apart by name
  validates :handle, uniqueness: { scope: %i[supplier_id color_nbr], case_sensitive: false }, if: -> { handle.present? }

  belongs_to :supplier

  # -----------------------------------------------------------------------------

  self.table_name = 'thread_colors'
  self.primary_key = 'thread_color_id'

  def id = thread_color_id

  # the color as the brand shows it: its number then name (ex: "2615 Aluminium"), or the name alone
  def display_name = [color_nbr, handle].compact.join(' ')

  # -----------------------------------------------------------------------------

end
