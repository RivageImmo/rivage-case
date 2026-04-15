FROM ruby:3.3-slim

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    libyaml-dev \
    curl \
    git \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN gem install foreman

WORKDIR /app

COPY Gemfile ./
RUN bundle install

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

EXPOSE 3000 3036

ENTRYPOINT ["bin/docker-entrypoint"]
CMD ["bin/dev"]
