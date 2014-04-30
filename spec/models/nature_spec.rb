require 'spec_helper'

describe Nature do
  subject { FactoryGirl.create(:nature) }

  let(:article) { FactoryGirl.build(:article, :doi => "10.1371/journal.pone.0008776") }

  context "get_data" do
    it "should report that there are no events if the doi is missing" do
      article = FactoryGirl.build(:article, :doi => "")
      subject.get_data(article).should eq(events: [], event_count: nil)
    end

    it "should report if there are no events and event_count returned by the Nature Blogs API" do
      article = FactoryGirl.build(:article, :doi => "10.1371/journal.pone.0044294")
      body = File.read(fixture_path + 'nature_nil.json')
      stub = stub_request(:get, subject.get_query_url(article)).to_return(:headers => { "Content-Type" => "application/json" }, :body => body, :status => 200)
      response = subject.get_data(article)
      response.should eq(JSON.parse(body))
      stub.should have_been_requested
    end

    it "should report if there are events and event_count returned by the Nature Blogs API" do
      body = File.read(fixture_path + 'nature.json')
      stub = stub_request(:get, subject.get_query_url(article)).to_return(:headers => { "Content-Type" => "application/json" }, :body => body, :status => 200)
      response = subject.get_data(article)
      response.should eq(JSON.parse(body))
      stub.should have_been_requested
    end

    it "should catch timeout errors with the Nature Blogs API" do
      article = FactoryGirl.build(:article, :doi => "10.1371/journal.pone.0000001")
      stub = stub_request(:get, subject.get_query_url(article)).to_return(:status => [408])
      response = subject.get_data(article, options = { :source_id => subject.id })
      response.should eq(error: "the server responded with status 408 for http://blogs.nature.com/posts.json?doi=#{article.doi_escaped}")
      stub.should have_been_requested
      Alert.count.should == 1
      alert = Alert.first
      alert.class_name.should eq("Net::HTTPRequestTimeOut")
      alert.status.should == 408
      alert.source_id.should == subject.id
    end
  end

  context "parse_data" do
    it "should report if there are no events and event_count returned by the Nature Blogs API" do
      body = File.read(fixture_path + 'nature_nil.json')
      result = JSON.parse(body)
      response = subject.parse_data(result, article)
      response.should eq(events: [], :events_url=>nil, event_count: 0, event_metrics: { pdf: nil, html: nil, shares: nil, groups: nil, comments: nil, likes: nil, citations: 0, total: 0 })
    end

    it "should report if there are events and event_count returned by the Nature Blogs API" do
      body = File.read(fixture_path + 'nature.json')
      result = JSON.parse(body)
      response = subject.parse_data(result, article)
      response[:event_count].should eq(10)
    end

    it "should catch timeout errors with the Nature Blogs APi" do
      article = FactoryGirl.create(:article, :doi => "10.1371/journal.pone.0000001")
      result = { error: "the server responded with status 408 for http://blogs.nature.com/posts.json?doi=#{article.doi_escaped}" }
      response = subject.parse_data(result, article)
      response.should eq(result)
    end
  end
end
