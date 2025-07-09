class CreateCaptainTables < ActiveRecord::Migration[7.0]
  def up
    # The 'vector' extension is preferred for optimal performance but not mandatory.
    # If the extension is not available (e.g., Railway, some hosting providers),
    # the migration will gracefully fallback to text columns for embeddings.
    setup_vector_extension
    create_assistants
    create_documents
    create_assistant_responses
    create_old_tables
  end

  def down
    drop_table :captain_assistant_responses if table_exists?(:captain_assistant_responses)
    drop_table :captain_documents if table_exists?(:captain_documents)
    drop_table :captain_assistants if table_exists?(:captain_assistants)
    drop_table :article_embeddings if table_exists?(:article_embeddings)

    # We are not disabling the extension here because it might be
    # used by other tables which are not part of this migration.
  end

  private

  def setup_vector_extension
    return if extension_enabled?('vector')

    begin
      enable_extension 'vector'
    rescue ActiveRecord::StatementInvalid => e
      # Handle Railway and other hosting providers that don't support pgvector
      Rails.logger.warn 'pgvector extension not available in current environment. Skipping vector features.'
      Rails.logger.warn "Error: #{e.message}"
      # Add the extension to ignore list for schema dumping
      add_extension_to_ignore_list('vector')
      return
    end
  end

  def railway_environment?
    # Check for Railway-specific environment variables
    ENV['RAILWAY_PROJECT_ID'].present? || ENV['RAILWAY_PROJECT_NAME'].present? ||
      ENV['RAILWAY_ENVIRONMENT'].present? || ENV['DATABASE_URL']&.include?('railway')
  end

  def extension_not_available?(error)
    # Check if the error indicates the extension is not available
    error.message.include?('does not exist') ||
      error.message.include?('extension "vector" is not available') ||
      error.message.include?('could not open extension control file')
  end

  def add_extension_to_ignore_list(extension_name)
    # Add to the ignore list for schema dumping
    return unless defined?(ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper)

    ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.ignore_extentions ||= []
    ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.ignore_extentions << extension_name
  end

  def create_assistants
    create_table :captain_assistants do |t|
      t.string :name, null: false
      t.bigint :account_id, null: false
      t.string :description

      t.timestamps
    end

    add_index :captain_assistants, :account_id
    add_index :captain_assistants, [:account_id, :name], unique: true
  end

  def create_documents
    create_table :captain_documents do |t|
      t.string :name, null: false
      t.string :external_link, null: false
      t.text :content
      t.bigint :assistant_id, null: false
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :captain_documents, :account_id
    add_index :captain_documents, :assistant_id
    add_index :captain_documents, [:assistant_id, :external_link], unique: true
  end

  def create_assistant_responses
    create_table :captain_assistant_responses do |t|
      t.string :question, null: false
      t.text :answer, null: false

      # Only add vector column if extension is available
      if extension_enabled?('vector')
        t.vector :embedding, limit: 1536
      else
        # Use text column as fallback for environments without pgvector
        t.text :embedding_data
      end

      t.bigint :assistant_id, null: false
      t.bigint :document_id
      t.bigint :account_id, null: false

      t.timestamps
    end

    add_index :captain_assistant_responses, :account_id
    add_index :captain_assistant_responses, :assistant_id
    add_index :captain_assistant_responses, :document_id

    # Only add vector index if extension is available
    return unless extension_enabled?('vector')

    add_index :captain_assistant_responses, :embedding, using: :ivfflat, name: 'vector_idx_knowledge_entries_embedding', opclass: :vector_l2_ops
  end

  def create_old_tables
    create_table :article_embeddings, if_not_exists: true do |t|
      t.bigint :article_id, null: false
      t.text :term, null: false

      # Only add vector column if extension is available
      if extension_enabled?('vector')
        t.vector :embedding, limit: 1536
      else
        # Use text column as fallback for environments without pgvector
        t.text :embedding_data
      end

      t.timestamps
    end

    # Only add vector index if extension is available
    return unless extension_enabled?('vector')

    add_index :article_embeddings, :embedding, if_not_exists: true, using: :ivfflat, opclass: :vector_l2_ops
  end
end
