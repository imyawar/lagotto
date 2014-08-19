object false

node(:total) { |m| @alerts.total_entries }
node(:total_pages) { |m| (@alerts.total_entries.to_f / @alerts.per_page).ceil }
node(:page) { |m| @alerts.total_entries > 0 ? @alerts.current_page : 0 }
node(:error) { nil }

child @alerts => :data do
  cache ['v4', @alerts]

  attributes :id, :class_name, :message, :status, :hostname, :source, :article, :create_date, :update_date
  attributes :human_level_name => :level
end
