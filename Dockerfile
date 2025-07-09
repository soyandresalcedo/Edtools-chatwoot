FROM ruby:3.2.0-bullseye

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    libpq-dev \
    libssl-dev \
    libreadline-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libffi-dev \
    libvips-dev \
    libxml2-dev \
    libxslt1-dev \
    libgdbm-dev \
    libncurses5-dev \
    libyaml-dev \
    pkg-config \
    wget \
    curl \
    git \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 23
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y nodejs

# Install pnpm
RUN npm install -g pnpm@10.2.0

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install Node dependencies
RUN pnpm install --frozen-lockfile

# Copy Ruby dependencies
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy application code
COPY . .

# Precompile assets
RUN RAILS_ENV=production bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]