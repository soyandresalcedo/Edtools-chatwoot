# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Chatwoot Development Guidelines

## Build / Test / Lint

- **Setup**: `bundle install && pnpm install`
- **Run Dev**: `pnpm dev` or `overmind start -f ./Procfile.dev`
- **Lint JS/Vue**: `pnpm eslint` / `pnpm eslint:fix`
- **Lint Ruby**: `bundle exec rubocop -a`
- **Test JS**: `pnpm test` or `pnpm test:watch`
- **Test Ruby**: `bundle exec rspec spec/path/to/file_spec.rb`
- **Single Test**: `bundle exec rspec spec/path/to/file_spec.rb:LINE_NUMBER`
- **Run Project**: `overmind start -f Procfile.dev`
- **Ruby Version**: Manage Ruby via `rbenv` and install the version listed in `.ruby-version` (e.g., `rbenv install $(cat .ruby-version)`)
- **rbenv setup**: Before running any `bundle` or `rspec` commands, init rbenv in your shell (`eval "$(rbenv init -)"`) so the correct Ruby/Bundler versions are used
- Always prefer `bundle exec` for Ruby CLI tasks (rspec, rake, rubocop, etc.)

## Code Style

- **Ruby**: Follow RuboCop rules (150 character max line length)
- **Vue/JS**: Use ESLint (Airbnb base + Vue 3 recommended)
- **Vue Components**: Use PascalCase
- **Events**: Use camelCase
- **I18n**: No bare strings in templates; use i18n
- **Error Handling**: Use custom exceptions (`lib/custom_exceptions/`)
- **Models**: Validate presence/uniqueness, add proper indexes
- **Type Safety**: Use PropTypes in Vue, strong params in Rails
- **Naming**: Use clear, descriptive names with consistent casing
- **Vue API**: Always use Composition API with `<script setup>` at the top

## Styling

- **Tailwind Only**:
  - Do not write custom CSS
  - Do not use scoped CSS
  - Do not use inline styles
  - Always use Tailwind utility classes
- **Colors**: Refer to `tailwind.config.js` for color definitions

## General Guidelines

- MVP focus: Least code change, happy-path only
- No unnecessary defensive programming
- Ship the happy path first: limit guards/fallbacks to what production has proven necessary, then iterate
- Prefer minimal, readable code over elaborate abstractions; clarity beats cleverness
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- Remove dead/unreachable/unused code
- Don't write multiple versions or backups for the same logic — pick the best approach and implement it
- Don't reference Claude in commit messages

## Project-Specific

- **Translations**:
  - Only update `en.yml` and `en.json`
  - Other languages are handled by the community
  - Backend i18n → `en.yml`, Frontend i18n → `en.json`
- **Frontend**:
  - Use `components-next/` for message bubbles (the rest is being deprecated)

## Ruby Best Practices

- Use compact `module/class` definitions; avoid nested styles

## Architecture Overview

### Tech Stack
- **Backend**: Ruby on Rails 7.1+ with PostgreSQL, Redis, Sidekiq
- **Frontend**: Vue 3 with Composition API, Vite, Tailwind CSS
- **Process Management**: Overmind (development), Foreman (production)
- **Node**: v23.x, **Package Manager**: pnpm 10.x

### Key Directories
- `/app/javascript/dashboard/` - Main dashboard Vue app
- `/app/javascript/widget/` - Customer-facing chat widget
- `/app/javascript/portal/` - Help center portal
- `/app/javascript/shared/` - Shared components and utilities
- `/app/javascript/components-next/` - New component system (preferred)
- `/app/controllers/api/` - API controllers
- `/app/services/` - Business logic services
- `/app/jobs/` - Background jobs (Sidekiq)
- `/enterprise/` - Enterprise features

### Development Workflow
- **Branch Model**: git-flow (base: `develop`, stable: `master`)
- **Process Manager**: Use `overmind start -f ./Procfile.dev` for development
- **Hot Reload**: Vite handles frontend hot reloading
- **Background Jobs**: Sidekiq for async processing

### Key Configuration Files
- `Procfile.dev` - Development services (Rails server, Sidekiq worker, Vite)
- `tailwind.config.js` - Tailwind configuration with custom colors and components
- `vite.config.ts` - Vite build configuration
- `config/features.yml` - Feature flags configuration

### Component Architecture
- **Vue 3 Composition API**: All new components use `<script setup>`
- **Tailwind-Only Styling**: No custom CSS, scoped styles, or inline styles
- **Component Library**: Migrating to `components-next/` directory
- **State Management**: Vuex 4 (consider migrating to Pinia for new features)

### Testing Strategy
- **Frontend**: Vitest with Vue Test Utils
- **Backend**: RSpec with FactoryBot
- **Test Commands**: `pnpm test` (JS), `bundle exec rspec` (Ruby)
- **Coverage**: Available via `pnpm test:coverage`

### Integration Points
- **ActionCable**: Real-time features via WebSocket
- **Third-party APIs**: Facebook, Instagram, Twitter, WhatsApp, Slack
- **AI/ML**: OpenAI integration for Captain (AI assistant)
- **Notifications**: Push notifications via FCM and web-push

## Railway Deployment - SPECIFIC CONFIGURATION

### 🚀 Railway Deployment Setup

This project has been optimized for Railway deployment with the following configuration:

#### **Files Modified for Railway:**
- `railway.toml` - Optimized configuration using nixpacks
- `Procfile` - Simplified for Railway compatibility
- `nixpacks.toml` - Build configuration without runtime migrations
- `bin/entrypoint-web.sh` - Railway-specific entrypoint script
- `RAILWAY_DEPLOY_GUIDE.md` - Complete deployment guide

#### **Critical Environment Variables for Railway:**
```bash
# Generated automatically by Railway
DATABASE_URL=postgresql://... (PostgreSQL service)
REDIS_URL=redis://... (Redis service)
PORT=3000 (automatic)

# MUST be configured manually
SECRET_KEY_BASE=generate-with-rails-secret-64-chars
DEVISE_JWT_SECRET_KEY=generate-with-rails-secret-64-chars
FRONTEND_URL=https://your-app.railway.app
HELPCENTER_URL=https://your-app.railway.app

# Optional but recommended
MAILER_SENDER_EMAIL=noreply@yourdomain.com
ENABLE_ACCOUNT_SIGNUP=true
FORCE_SSL=true
ACTIVE_STORAGE_SERVICE=local
```

#### **Railway-Specific Issues Resolved:**

1. **Error 502 Fix**: Simplified Procfile and proper port configuration
2. **pgvector Compatibility**: Fallback mode for Railway's standard PostgreSQL
3. **Build Optimization**: Separated build-time and runtime operations
4. **Secret Generation**: Automatic secret generation in entrypoint script
5. **Database Migrations**: Handled in runtime, not build-time

#### **Deployment Commands:**
```bash
# Generate secret keys locally
rails secret  # Use for SECRET_KEY_BASE
rails secret  # Use for DEVISE_JWT_SECRET_KEY

# Deploy to Railway
git add .
git commit -m "Deploy to Railway"
git push origin main
```

#### **Common Railway Deployment Issues:**

**Error 502 (Bad Gateway):**
- Verify SECRET_KEY_BASE and DEVISE_JWT_SECRET_KEY are set
- Check that FRONTEND_URL matches your Railway domain
- Ensure PostgreSQL and Redis services are connected

**Database Migration Failures:**
- pgvector extension handling is automatic (fallback mode)
- Migrations run in entrypoint script, not build phase
- Check Railway logs for specific migration errors

**Asset Compilation Issues:**
- Assets are precompiled during nixpacks build phase
- Ensure pnpm dependencies are installed correctly
- Check for JavaScript/CSS compilation errors in logs

#### **pgvector Configuration:**
This project includes automatic pgvector fallback for Railway:
- **With pgvector**: Full AI features with optimized vector search
- **Without pgvector**: Basic AI features with text-based fallback
- **Migration**: `20250104200055_create_captain_tables.rb` handles both scenarios

#### **Performance Optimizations for Railway:**
- **Nixpacks**: Optimized build configuration
- **Process Management**: Simplified Procfile for stability
- **Asset Pipeline**: Vite-based build with efficient caching
- **Database**: Optimized connection pooling and query timeouts

#### **Monitoring and Debugging:**
```bash
# View Railway logs
railway logs

# Connect to database
railway connect

# Run migrations manually
railway run bundle exec rails db:migrate

# Check environment variables
railway variables
```

### 📋 Railway Deployment Checklist

Before deploying to Railway:
1. ✅ PostgreSQL service connected
2. ✅ Redis service connected
3. ✅ SECRET_KEY_BASE configured
4. ✅ DEVISE_JWT_SECRET_KEY configured
5. ✅ FRONTEND_URL set to Railway domain
6. ✅ HELPCENTER_URL set to Railway domain
7. ✅ All code changes committed and pushed

### 🔧 Railway-Specific Development

When working on Railway deployment issues:
- Check `railway.toml` for service configuration
- Review `nixpacks.toml` for build settings
- Examine `bin/entrypoint-web.sh` for startup sequence
- Consult `RAILWAY_DEPLOY_GUIDE.md` for detailed instructions
- Monitor Railway dashboard for service health and logs

This configuration ensures reliable deployment on Railway while maintaining compatibility with other deployment methods.

## Enterprise Edition Notes

- Chatwoot has an Enterprise overlay under `enterprise/` that extends/overrides OSS code.
- When you add or modify core functionality, always check for corresponding files in `enterprise/` and keep behavior compatible.
- Follow the Enterprise development practices documented here:
  - https://chatwoot.help/hc/handbook/articles/developing-enterprise-edition-features-38

Practical checklist for any change impacting core logic or public APIs
- Search for related files in both trees before editing (e.g., `rg -n "FooService|ControllerName|ModelName" app enterprise`).
- If adding new endpoints, services, or models, consider whether Enterprise needs:
  - An override (e.g., `enterprise/app/...`), or
  - An extension point (e.g., `prepend_mod_with`, hooks, configuration) to avoid hard forks.
- Avoid hardcoding instance- or plan-specific behavior in OSS; prefer configuration, feature flags, or extension points consumed by Enterprise.
- Keep request/response contracts stable across OSS and Enterprise; update both sets of routes/controllers when introducing new APIs.
- When renaming/moving shared code, mirror the change in `enterprise/` to prevent drift.
- Tests: Add Enterprise-specific specs under `spec/enterprise`, mirroring OSS spec layout where applicable.
