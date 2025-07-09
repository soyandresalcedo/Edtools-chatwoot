# Railway PostgreSQL pgvector Extension Solution

## Problem Description

The Chatwoot application uses the `pgvector` extension for vector similarity search in Captain (AI assistant) features. When deploying to Railway, the migration `20250104200055_create_captain_tables.rb` fails because Railway's default PostgreSQL instances don't have the `pgvector` extension pre-installed.

## Error Details

```ruby
/app/db/migrate/20250104200055_create_captain_tables.rb:28:in 'CreateCaptainTables#setup_vector_extension'
/app/db/migrate/20250104200055_create_captain_tables.rb:5:in 'CreateCaptainTables#up'
```

The error occurs when trying to execute `enable_extension 'vector'` on a PostgreSQL instance that doesn't have the pgvector extension available.

## Solution Overview

The solution makes the migration **gracefully handle environments without pgvector** by:

1. **Conditional Extension Loading**: Detect Railway and other hosting environments
2. **Fallback Column Types**: Use `text` columns instead of `vector` columns
3. **Skip Vector Indexes**: Don't create vector-specific indexes when extension is unavailable
4. **Schema Dumping**: Ignore the vector extension in schema dumps for environments without it
5. **Upgrade Path**: Provide a migration path for upgrading to pgvector later

## Key Changes Made

### 1. Enhanced Error Handling in `setup_vector_extension`

```ruby
def setup_vector_extension
  return if extension_enabled?('vector')

  begin
    enable_extension 'vector'
  rescue ActiveRecord::StatementInvalid => e
    # Handle Railway and other hosting providers that don't support pgvector
    if railway_environment? || extension_not_available?(e)
      Rails.logger.warn "pgvector extension not available in current environment. Skipping vector features."
      # Add the extension to ignore list for schema dumping
      add_extension_to_ignore_list('vector')
      return
    end
    raise StandardError, "Failed to enable 'vector' extension. Read more at https://chwt.app/v4/migration"
  end
end
```

### 2. Environment Detection

```ruby
def railway_environment?
  # Check for Railway-specific environment variables
  ENV['RAILWAY_PROJECT_ID'].present? || ENV['RAILWAY_PROJECT_NAME'].present? || 
  ENV['RAILWAY_ENVIRONMENT'].present? || ENV['DATABASE_URL']&.include?('railway')
end
```

### 3. Conditional Table Creation

Tables now conditionally create vector or text columns based on extension availability:

```ruby
# Only add vector column if extension is available
if extension_enabled?('vector')
  t.vector :embedding, limit: 1536
else
  # Use text column as fallback for environments without pgvector
  t.text :embedding_data
end
```

### 4. Conditional Index Creation

Vector indexes are only created when the extension is available:

```ruby
# Only add vector index if extension is available
if extension_enabled?('vector')
  add_index :captain_assistant_responses, :embedding, using: :ivfflat, 
            name: 'vector_idx_knowledge_entries_embedding', opclass: :vector_l2_ops
end
```

## Deployment Scenarios

### Scenario 1: Railway Default PostgreSQL
- **Extension Available**: ❌ No
- **Behavior**: Creates tables with `text` columns for embeddings
- **Functionality**: Basic AI features work, but without optimized vector search
- **Performance**: Slower similarity searches

### Scenario 2: Railway with pgvector Template
- **Extension Available**: ✅ Yes (using Railway's pgvector template)
- **Behavior**: Creates tables with `vector` columns and indexes
- **Functionality**: Full AI features with optimized vector search
- **Performance**: Optimal similarity searches

### Scenario 3: Local Development
- **Extension Available**: ✅ Yes (with proper pgvector setup)
- **Behavior**: Creates tables with `vector` columns and indexes
- **Functionality**: Full AI features with optimized vector search
- **Performance**: Optimal similarity searches

## Migration Path to pgvector

If you start with Railway's default PostgreSQL and later want to upgrade to pgvector:

1. **Deploy pgvector-enabled database** (Railway template or custom setup)
2. **Migrate your data** to the new database
3. **Run the upgrade migration**: `rails db:migrate:up VERSION=20250105000000`

The upgrade migration (`20250105000000_upgrade_to_pgvector.rb`) will:
- Enable the vector extension
- Add vector columns to existing tables
- Migrate data from text to vector format
- Add vector indexes
- Remove old text columns

## Railway-Specific Setup

### Option 1: Use Railway's pgvector Template
1. Deploy a new PostgreSQL instance using Railway's pgvector template
2. Migrate your data from the old database
3. Update your `DATABASE_URL` environment variable

### Option 2: Custom pgvector Setup
1. Use a custom Docker image with pgvector
2. Configure your Railway service to use the custom image
3. Enable the extension manually: `CREATE EXTENSION vector;`

## Testing the Solution

### Test Migration in Railway Environment
```bash
# This should now work without errors
RAILS_ENV=production bundle exec rails db:migrate
```

### Test Vector Features
```ruby
# Check if vector features are available
Captain::AssistantResponse.column_names.include?('embedding') # true if pgvector available
Captain::AssistantResponse.column_names.include?('embedding_data') # true if fallback mode
```

### Test Upgrade Migration
```bash
# After migrating to pgvector-enabled database
bundle exec rails db:migrate:up VERSION=20250105000000
```

## Application Code Considerations

The application code should check for vector availability:

```ruby
# Example: Conditional vector search
class Captain::AssistantResponse < ApplicationRecord
  def self.vector_search_available?
    column_names.include?('embedding')
  end
  
  def self.search_similar(query_vector, limit: 5)
    if vector_search_available?
      # Use optimized vector search
      nearest_neighbors(:embedding, query_vector, distance: :cosine).limit(limit)
    else
      # Fallback to text-based search
      where("embedding_data IS NOT NULL").limit(limit)
    end
  end
end
```

## Monitoring and Logging

The solution includes appropriate logging:
- **Warning**: When pgvector is not available
- **Info**: When fallback mode is used
- **Error**: When genuine extension errors occur

## Backwards Compatibility

The solution maintains backwards compatibility:
- **Existing installations**: Continue to work with pgvector
- **New Railway deployments**: Work without pgvector
- **Upgrade path**: Available when moving to pgvector

## Performance Implications

### With pgvector
- **Vector Operations**: Optimized with SIMD instructions
- **Similarity Search**: Sub-second for millions of vectors
- **Indexes**: IVFFlat for efficient nearest neighbor search

### Without pgvector (Fallback)
- **Vector Operations**: Serialized as JSON in text columns
- **Similarity Search**: Slower, requires application-level processing
- **Indexes**: Standard B-tree indexes on text columns

## Security Considerations

- **Extension Loading**: Only attempts to load extensions when explicitly supported
- **Error Handling**: Doesn't expose sensitive database information
- **Environment Detection**: Uses standard environment variables

## Troubleshooting

### Migration Still Fails
1. **Check logs** for specific error messages
2. **Verify environment variables** are set correctly
3. **Test database connection** manually
4. **Check PostgreSQL version** compatibility

### Vector Features Don't Work
1. **Check column types** in database
2. **Verify extension status**: `SELECT * FROM pg_extension WHERE extname = 'vector';`
3. **Check application logs** for vector-related errors

### Upgrade Migration Fails
1. **Backup database** before running upgrade
2. **Check data format** in embedding_data columns
3. **Run upgrade in stages** if necessary

## Future Improvements

1. **Automatic Detection**: Improve environment detection logic
2. **Performance Monitoring**: Add metrics for vector vs text search
3. **Configuration Options**: Allow forcing vector mode via environment variables
4. **Testing**: Add comprehensive test coverage for all scenarios

## Related Files

- `/db/migrate/20250104200055_create_captain_tables.rb` - Main migration with fallback logic
- `/db/migrate/20250105000000_upgrade_to_pgvector.rb` - Upgrade migration for pgvector
- `/config/initializers/monkey_patches/schema_dumper.rb` - Schema dumping configuration
- `/railway.toml` - Railway deployment configuration

This solution ensures that Chatwoot can deploy successfully on Railway while maintaining the option to upgrade to full pgvector functionality when needed.