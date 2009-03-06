require 'test_helper'

class SourceTest < ActiveSupport::TestCase
  def test_should_report_configured_sources
    assert_equal Source.all.to_set,
      [sources(:connotea), sources(:crossref)].to_set
  end

  def test_should_report_unconfigured_subclasses
    assert Source.unconfigured_source_names.include?("Bloglines")
  end

  def test_should_calculate_staleness_limit
    assert_equal Source.maximum_staleness, 1.year
  end
end
