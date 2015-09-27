class PlosImport < Agent
  # include common methods for Import
  include Importable

  def get_query_url(options={})
    offset = options[:offset].presence || 0
    rows = options[:rows].presence || job_batch_size
    from_date = options[:from_date].presence || (Time.zone.now.to_date - 1.day).iso8601
    until_date = options[:until_date].presence || Time.zone.now.to_date.iso8601

    date_range = "publication_date:[#{from_date}T00:00:00Z TO #{until_date}T23:59:59Z]"
    params = { q: "*:*",
               start: offset,
               rows: rows,
               fl: "id,publication_date,title_display,cross_published_journal_name,author_display,volume,issue,elocation_id",
               fq: "+#{date_range}+doc_type:full",
               wt: "json" }
    url + params.to_query
  end

  def get_works(result)
    # return early if an error occured
    return [] unless result.is_a?(Hash) && result.fetch("response", nil)

    items = result.fetch('response', {}).fetch('docs', nil)
    Array(items).map do |item|
      timestamp = get_iso8601_from_time(item.fetch("publication_date", nil))
      date_parts = get_date_parts(timestamp)

      { "author" => get_authors(item.fetch("author_display", [])),
        "container-title" => item.fetch("cross_published_journal_name", []).first,
        "title" => item.fetch("title_display", nil),
        "issued" => date_parts,
        "DOI" => item.fetch("id", nil),
        "publisher_id" => publisher_id,
        "volume" => item.fetch("volume", nil),
        "issue" => item.fetch("issue", nil),
        "page" => item.fetch("elocation_id", nil),
        "tracked" => tracked,
        "type" => "article-journal" }
    end
  end

  def config_fields
    [:url]
  end

  def url
    "http://api.plos.org/search?"
  end

  # publisher_id is PLOS CrossRef member id
  def publisher_id
    340
  end

  def cron_line
    config.cron_line || "20 11,16 * * 1-5"
  end
end