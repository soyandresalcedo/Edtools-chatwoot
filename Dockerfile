FROM ruby:3.4.4-bullseye

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
    cmake \
    libprotobuf-dev \
    protobuf-compiler \
    libsqlite3-dev \
    libmaxminddb-dev \
    && rm -rf /var/lib/apt/lists/*

# Install specific bundler version
RUN gem install bundler:2.5.16

# Install Node.js 23
RUN curl -fsSL https://deb.nodesource.com/setup_23.x | bash - \
    && apt-get install -y nodejs

# Install pnpm
RUN npm install -g pnpm@10.2.0

# Set working directory
WORKDIR /app

# Configure build environment for gems
ENV BUNDLE_BUILD__GRPC="--with-grpc-dir=/usr/local"
ENV BUNDLE_BUILD__NOKOGIRI="--use-system-libraries"
ENV BUNDLE_BUILD__PG="--with-pg-config=/usr/bin/pg_config"
ENV BUNDLE_BUILD__SASSC="--disable-march-tune-native"

# Copy Ruby dependencies first (for better caching)
COPY Gemfile Gemfile.lock ./

# Install Ruby dependencies
RUN bundle config set --local without 'development test' && \
    bundle config set --local jobs 4 && \
    bundle config set --local retry 3 && \
    bundle install --verbose

# Copy package files
COPY package.json pnpm-lock.yaml ./

# Install Node dependencies
RUN pnpm install --frozen-lockfile

# Copy application code
COPY . .

# Precompile assets
RUN RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# Expose port
EXPOSE 3000

# Start command
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb", "-b", "0.0.0.0", "-p", "3000"]