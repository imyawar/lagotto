class RetrievalStatusDecorator < Draper::Decorator
  # helper methods
  include Measurable

  delegate_all
  decorates_association :article

  def test_name
    "test" # model.source.group.name
  end

  def metrics
    if model.event_metrics.present?
      model.event_metrics
    else
      { :pdf => nil,
        :html => nil,
        :shares => nil,
        :groups => nil,
        :comments => nil,
        :likes => nil,
        :citations => nil,
        :total => 0 }
    end
  end

  def new_metrics
    { :pdf => metrics[:pdf],
      :html => metrics[:html],
      :readers => metrics[:shares],
      :comments => metrics[:comments],
      :likes => metrics[:likes],
      :total => metrics[:total] }
  end

  def by_year
    return [] if by_month.blank?

    by_month.group_by { |event| event["year"] }.sort.map do |k, v|
      if ['counter', 'pmc', 'figshare', 'copernicus'].include?(name)
        { year: k.to_i,
          pdf: v.reduce(0) { |sum, hash| sum + hash['pdf'].to_i },
          html: v.reduce(0) { |sum, hash| sum + hash['html'].to_i } }
      else
        { year: k.to_i,
          total: v.reduce(0) { |sum, hash| sum + hash['total'].to_i } }
      end
    end
  end

  def update_date
    updated_at.utc.iso8601
  end

  def events_csl
    return [] unless model.events.is_a?(Array)

    model.events.map { |event| event['event_csl'] }.compact
  end

  def cache_key
    { :id => id,
      :update_date => update_date,
      :info => context[:info] }
  end
end
