class DataciteOrcid < Agent
  # include common methods for Import
  include Importable

  def get_query_url(options={})
    offset = options[:offset].to_i
    rows = options[:rows].presence || job_batch_size
    from_date = options[:from_date].presence || (Time.zone.now.to_date - 1.day).iso8601
    until_date = options[:until_date].presence || Time.zone.now.to_date.iso8601

    updated = "updated:[#{from_date}T00:00:00Z TO #{until_date}T23:59:59Z]"
    params = { q: "nameIdentifier:ORCID\\:*",
               start: offset,
               rows: rows,
               fl: "doi,creator,title,publisher,publicationYear,resourceTypeGeneral,datacentre_symbol,nameIdentifier,xml,updated",
               fq: "#{updated} AND has_metadata:true AND is_active:true",
               wt: "json" }
    url +  URI.encode_www_form(params)
  end

  def get_relations_with_related_works(items)
    Array(items).reduce([]) do |sum, item|
      doi = item.fetch("doi", nil)
      pid = doi_as_url(doi)
      year = item.fetch("publicationYear", nil).to_i
      type = item.fetch("resourceTypeGeneral", nil)
      type = DATACITE_TYPE_TRANSLATIONS[type] if type
      publisher_id = item.fetch("datacentre_symbol", nil)

      xml = Base64.decode64(item.fetch('xml', "PGhzaD48L2hzaD4=\n"))
      xml = Hash.from_xml(xml).fetch("resource", {})
      authors = xml.fetch("creators", {}).fetch("creator", [])
      authors = [authors] if authors.is_a?(Hash)

      subject = { "pid" => pid,
                  "DOI" => doi,
                  "author" => get_hashed_authors(authors),
                  "title" => item.fetch("title", []).first,
                  "container-title" => item.fetch("publisher", nil),
                  "issued" => { "date-parts" => [[year]] },
                  "publisher_id" => publisher_id,
                  "registration_agency" => "datacite",
                  "tracked" => true,
                  "type" => type }

      name_identifiers = item.fetch('nameIdentifier', []).select { |id| id =~ /^ORCID:.+/ }
      sum += get_relations(subject, name_identifiers)
    end
  end

  def get_relations(subject, items)
    prefix = subject["DOI"][/^10\.\d{4,5}/]

    Array(items).map do |item|
      orcid = item.split(':', 2).last

      { prefix: prefix,
        message_type: "contributor",
        relation: { "subject" => subject["pid"],
                    "object" => "http://orcid.org/#{orcid}",
                    "source_id" => source_id,
                    "publisher_id" => subject["publisher_id"] },
        subject: subject }
    end
  end

  def config_fields
    [:url]
  end

  def url
    "http://search.datacite.org/api?"
  end

  def cron_line
    config.cron_line || "40 18 * * *"
  end

  def timeout
    config.timeout || 120
  end

  def job_batch_size
    config.job_batch_size || 200
  end
end
