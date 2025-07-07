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
- Break down complex tasks into small, testable units
- Iterate after confirmation
- Avoid writing specs unless explicitly asked
- Remove dead/unreachable/unused code
- Don’t write multiple versions or backups for the same logic — pick the best approach and implement it
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