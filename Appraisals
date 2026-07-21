# frozen_string_literal: true

appraise "rails" do
  gem "rails"
  gem "sidekiq"
end

appraise "activerecord_8" do
  gem "activerecord", "~> 8.0", require: "active_record"
  gem "sqlite3", "~> 2.0"
  gem "sidekiq"
end

appraise "activerecord_7" do
  gem "activerecord", "~> 7.0", require: "active_record"
  gem "sqlite3", "~> 1.4.0"
  gem "sidekiq"
end

appraise "activerecord_6" do
  gem "activerecord", "~> 6.0", require: "active_record"
  gem "sqlite3", "~> 1.4.0"
  gem "sidekiq", "~> 6.0"
end

appraise "activerecord_5" do
  gem "activerecord", "~> 5.0", require: "active_record"
  gem "sqlite3", "~> 1.3.0"
end
