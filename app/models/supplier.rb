class Supplier < HawthorneCore::ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'suppliers'
  self.primary_key = 'supplier_id'

  def id = supplier_id

  # -----------------------------------------------------------------------------

end
