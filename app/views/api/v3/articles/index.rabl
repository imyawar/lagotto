collection ArticleDecorator.decorate(@articles)
  
attributes :doi, :title, :url, :mendeley, :mendeley_url, :pmid, :pmcid, :publication_date

unless params[:info] == "summary"
  child :retrieval_statuses => :sources do
    attributes :name, :events_url, :metrics, :update_date
    
    attributes :events if ["detail","event"].include?(params[:info])
    attributes :histories if ["detail","history"].include?(params[:info])
  end
end