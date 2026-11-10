class DocumentType < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted

  has_paper_trail versions: { class_name: 'Version' }

  # the file types a document type can accept, with their names (ex: on the DevOps form)
  CONTENT_TYPES = {
    'application/pdf' => 'PDF',
    'image/jpeg' => 'JPEG',
    'image/png' => 'PNG',
    'text/csv' => 'CSV',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => 'Excel (.xlsx)',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => 'Word (.docx)'
  }.freeze

  # each file type's extension, for its stored file's key (see HawthorneCore::DocumentHelper)
  EXTENSIONS = {
    'application/pdf' => '.pdf',
    'image/jpeg' => '.jpg',
    'image/png' => '.png',
    'text/csv' => '.csv',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => '.xlsx',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => '.docx'
  }.freeze

  # a slug is a storage folder path (documents/<slug>/<token>.<ext>), named like the image types' slugs: lowercase
  # words joined by underscores, in folders split by slashes (ex: product/sample_card/color_card)
  SLUG_FORMAT = %r{\A[a-z0-9]+(_[a-z0-9]+)*(/[a-z0-9]+(_[a-z0-9]+)*)*\z}

  validates :handle, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: SLUG_FORMAT, message: 'must be lowercase words joined by underscores, in folders split by slashes (ex: product/sample_card/color_card)', allow_blank: true }
  validate :content_types_known
  validate :no_active_documents_when_inactivating
  validate :slug_cannot_change_with_documents

  has_many :documents

  # -----------------------------------------------------------------------------

  self.table_name = 'document_types'
  self.primary_key = 'document_type_id'

  def id = document_type_id

  # the accepted file types' names (ex: "PDF, Excel (.xlsx)")
  def content_type_names = content_types.to_a.map { |content_type| CONTENT_TYPES[content_type] || content_type }.join(', ')

  # -----------------------------------------------------------------------------

  private

  # at least one file type, each one CONTENT_TYPES knows
  def content_types_known
    if content_types.blank?
      errors.add(:content_types, "can't be blank")
    elsif (unknown = content_types - CONTENT_TYPES.keys).any?
      errors.add(:content_types, "has unknown file types: #{unknown.join(', ')}")
    end
  end

  # a document type cannot be set as inactive while active documents still use it
  def no_active_documents_when_inactivating
    return unless deleted? && deleted_changed?
    if Document.where(document_type_id:, deleted: false).exists?
      errors.add(:base, 'Cannot be set as inactive while it has active documents')
    end
  end

  # the slug is its documents' storage folder, so it cannot change once any document (active or inactive) uses it
  def slug_cannot_change_with_documents
    return unless persisted? && slug_changed?
    if Document.where(document_type_id:).exists?
      errors.add(:slug, 'cannot be edited once the document type has documents')
    end
  end

end
