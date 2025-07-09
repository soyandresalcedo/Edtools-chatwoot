class UpgradeToPgvector < ActiveRecord::Migration[7.0]
  def up
    # This migration allows upgrading from text-based embeddings to pgvector
    # Run this after migrating to a pgvector-enabled database

    return unless should_upgrade_to_pgvector?

    # Enable vector extension if not already enabled
    enable_extension 'vector' unless extension_enabled?('vector')

    # Upgrade captain_assistant_responses table
    if table_exists?(:captain_assistant_responses) && column_exists?(:captain_assistant_responses, :embedding_data)
      add_column :captain_assistant_responses, :embedding, :vector, limit: 1536

      # Migrate existing data (if any)
      # Note: This assumes embeddings were stored as JSON arrays in embedding_data
      execute <<-SQL
        UPDATE captain_assistant_responses#{' '}
        SET embedding = embedding_data::vector#{' '}
        WHERE embedding_data IS NOT NULL AND embedding_data != '';
      SQL

      # Add the vector index
      add_index :captain_assistant_responses, :embedding, using: :ivfflat,
                                                          name: 'vector_idx_knowledge_entries_embedding', opclass: :vector_l2_ops

      # Remove the old text column
      remove_column :captain_assistant_responses, :embedding_data
    end

    # Upgrade article_embeddings table
    return unless table_exists?(:article_embeddings) && column_exists?(:article_embeddings, :embedding_data)

    add_column :article_embeddings, :embedding, :vector, limit: 1536

    # Migrate existing data (if any)
    execute <<-SQL
        UPDATE article_embeddings#{' '}
        SET embedding = embedding_data::vector#{' '}
        WHERE embedding_data IS NOT NULL AND embedding_data != '';
    SQL

    # Add the vector index
    add_index :article_embeddings, :embedding, using: :ivfflat, opclass: :vector_l2_ops

    # Remove the old text column
    remove_column :article_embeddings, :embedding_data
  end

  def down
    # This migration is not reversible as it would require converting
    # vector data back to text format
    raise ActiveRecord::IrreversibleMigration,
          'Cannot reverse pgvector upgrade migration. Manual intervention required.'
  end

  private

  def should_upgrade_to_pgvector?
    # Check if we have the old text-based embedding columns
    # and the pgvector extension is available

    enable_extension 'vector' unless extension_enabled?('vector')
    return true
  rescue ActiveRecord::StatementInvalid
    Rails.logger.info 'pgvector extension not available. Skipping upgrade.'
    return false
  end
end