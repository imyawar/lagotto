/*global d3 */

var params = d3.select("#api_key");

if (!params.empty()) {
  var api_key = params.attr('data-api-key');
  var page = params.attr('data-page');
  if (page === null) { page = 1; }
  var per_page = params.attr('data-per-page');
  var publisher_id = params.attr('data-publisher-id');
  var source_id = params.attr('data-source-id');
  var sort = params.attr('data-sort');

  var query = encodeURI("/api/publishers/" + publisher_id + "/works?page=" + page);
  if (per_page !== null) { query += "&per_page=" + per_page; }
  if (source_id !== null) { query += "&source_id=" + source_id; }
  if (sort !== null) { query += "&sort=" + sort; }
}

// asynchronously load data from the Lagotto API
queue()
  .defer(d3.json, encodeURI("/api/sources"))
  .defer(d3.json, query)
  .await(function(error, s, w) {
    if (error) { return console.warn(error); }
    worksViz(w, s.sources);
    paginate(w, "#content");
});

// add data to page
function worksViz(json, sources) {
  data = json.works;

  json.href = "?page={{number}}";
  if (q !== "") { json.href += "&q=" + q; }
  if (publisher_id !== "" && model !== "publisher") { json.href += "&publisher_id=" + publisher_id; }
  if (source_id !== "") { json.href += "&source_id=" + source_id; }
  if (sort !== "") { json.href += "&sort=" + sort; }

  d3.select("#loading-results").remove();

  if (typeof data === "undefined" || data.length === 0) {
    d3.select("#content").text("")
      .insert("div")
      .attr("class", "alert alert-info")
      .text("There are currently no works");
    if (model === "source") { d3.select("div#rss").remove(); }
    return;
  }

  if (json.meta.total > 1) {
    d3.select("#content").insert("h4")
      .attr("class", "results")
      .text(numberWithDelimiter(json.meta.total) + " Results");

    d3.select("#publisher-sort").classed("hidden", false);
  }

  for (var i=0; i<data.length; i++) {
    var work = data[i];

    d3.select("#content").insert("div")
      .attr("class", "panel panel-default")
      .attr("id", "panel-" + i).insert("div")
      .attr("class", "panel-body")
      .attr("id", "panel-body-" + i);

    d3.select("#panel-body-" + i).append("h4")
      .attr("class", "work")
      .append("a")
      .attr("href", function() { return "/works/" + pathForWork(work.id); })
      .html(work.title);
    d3.select("#panel-body-" + i).append("p")
      .html(formattedAuthor(work.author)).append("p")
      .html(metadataToString(work));
    d3.select("#panel-body" + i).append("p")
      .text(signpostsToString(work, sources, source_id, sort));

    d3.select("#panel-" + i).insert("div")
      .attr("class", "panel-footer").append("a")
      .attr("href", function() { return work.id; })
      .html('<i class="fa fa-external-link"/>').append('span')
      .text(work.work_id);
  }
}
