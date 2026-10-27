# pgvector's vector type (see ProductEmbedding), known to rails so reading a vector column doesn't warn "unknown OID
# ... failed to recognize type". its values stay strings in pgvector's text form (ex: '[0.1,-0.2]'), like rails'
# own tsvector
ActiveSupport.on_load(:active_record_postgresqladapter) do
  singleton_class.prepend(Module.new do
    def initialize_type_map(m)
      super
      m.register_type 'vector', ActiveRecord::ConnectionAdapters::PostgreSQL::OID::SpecializedString.new(:vector)
    end
  end)
end
