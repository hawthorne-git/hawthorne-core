class Document < ActiveRecordBaseApp

  include HawthorneCore::CanBeSoftDeleted,
          HawthorneCore::HasToken

  # exclude :touch so active storage attaching the file (which touches the record via the attachment's touch: true)
  # doesn't log empty update versions
  has_paper_trail versions: { class_name: 'Version' }, on: %i[create update destroy]

  has_one_attached :file

  belongs_to :document_type

  has_many :product_documents

  validate :document_type_active, if: -> { new_record? || (deleted_changed? && !deleted?) }
  validate :content_type_accepted, if: -> { content_type.present? && (content_type_changed? || document_type_id_changed?) }
  validate :source_url_web_link, if: -> { source_url.present? && source_url_changed? }

  # a replaced file (see HawthorneCore::DocumentHelper#attach_document_helper bumping file_version) is summarized again,
  # even over a hand edit, since the old summary no longer matches it; so is one AI is turned back on for
  before_update :reset_summary, if: -> { file_version_changed? || will_save_change_to_update_summary_with_ai?(to: true) }

  # a sample card pdf is summarized for product search once its file is stored or replaced, or AI is turned back on for
  # it (see Ai::DocumentSummaryJob, which skips one that doesn't need it)
  after_commit -> { Ai::DocumentSummaryJob.perform_later(document_id:) }, on: [:create, :update], if: :summary_wanted?

  # its products' search text is written from its summary (see Ai::ProductSearchTextJob), so it's written again when the
  # summary is (by AI or by hand)
  after_commit :queue_product_search_text, on: :update, if: -> { sample_card_pdf? && saved_change_to_summary? }

  # -----------------------------------------------------------------------------

  self.table_name = 'documents'
  self.primary_key = 'document_id'

  def id = document_id

  # the name shown with its link: the title, else the last part of its type's handle (ex: "Color Card")
  def display_title = title.presence || document_type&.handle.to_s.split(' / ').last

  # whether this is a sample card's pdf (see Product::SAMPLE_CARD_DOCUMENT_TYPE)
  def sample_card_pdf? = document_type&.handle == Product::SAMPLE_CARD_DOCUMENT_TYPE

  # -----------------------------------------------------------------------------

  private

  # whether the last save means a sample card pdf should be summarized (again)
  def summary_wanted?
    active? && sample_card_pdf? &&
      (%w[file_key file_version].any? { |column| saved_change_to_attribute?(column) } || saved_change_to_update_summary_with_ai?(to: true))
  end

  def queue_product_search_text
    ProductDocument.where(document_id:, deleted: false).distinct.pluck(:product_id).each do |product_id|
      Ai::ProductSearchTextJob.perform_later(product_id:)
    end
  end

  def reset_summary
    self.summary = nil
    self.summary_attrs = nil
    self.summary_ai_model_prompt_id = nil
    self.update_summary_with_ai = true
  end

  # a document can only be added (or set as active) while its type is active
  def document_type_active
    if document_type&.deleted?
      errors.add(:base, "Its document type '#{document_type.handle}' is inactive")
    end
  end

  # the file must be one of the types its document type accepts (see DocumentType#content_types)
  def content_type_accepted
    return if document_type.nil? || document_type.content_types.to_a.include?(content_type)

    errors.add(:base, "#{document_type.handle} only accepts #{document_type.content_type_names}")
  end

  def source_url_web_link
    uri = URI.parse(source_url)
    errors.add(:source_url, 'must be a web link (http:// or https://)') unless uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    errors.add(:source_url, 'must be a web link (http:// or https://)')
  end

end
