FROM ruby:3.2
WORKDIR /app
COPY Gemfile* ./
RUN bundle install
COPY . .
EXPOSE 3004
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "3004"]