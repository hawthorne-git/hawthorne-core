class ProductDocument < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # -----------------------------------------------------------------------------

  self.table_name = 'product_documents'
  self.primary_key = 'product_document_id'

  def id = product_document_id

  # -----------------------------------------------------------------------------

  belongs_to :product
  belongs_to :document

  delegate :document_type, to: :document

  # a product has at most one active document of a type that doesn't allow multiple (ex: a sample card's color card);
  # adding another means retiring the current one first (see the product form)
  validate :one_per_product, if: -> { active? && (new_record? || deleted_changed?) }

  # a product's search text (ex: a sample card's) is written from its pdf's summary (see Ai::ProductSearchTextJob, which
  # waits while the pdf hasn't been summarized yet), so it's written again as one is added or removed
  after_commit -> { Ai::ProductSearchTextJob.perform_later(product_id:) }, on: [:create, :update],
               if: -> { (previously_new_record? || saved_change_to_deleted?) && product.search_text? }

  # -----------------------------------------------------------------------------

  private

  def one_per_product
    return if document.nil? || document.document_type.allows_multiple?

    others = ProductDocument.active.joins(:document)
                            .where(product_id:, documents: { document_type_id: document.document_type_id, deleted: false })
    others = others.where.not(product_document_id:) if persisted?
    errors.add(:base, "The product already has a #{document.document_type.handle} document (only one is allowed)") if others.exists?
  end

end
