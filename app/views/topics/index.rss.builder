xml.channel do
  xml.atom :link, nil, {
    :href => formatted_topics_url(:rss),
    :rel => 'self', :type => 'application/rss+xml'
  }

  xml.title t('forums.rss.topics.title', :site_title => @site_title)
  xml.description t('forums.rss.topics.description')
  xml.link topics_url
  xml.language "en-us"
  xml.ttl "60"

  render :partial => "topic", :collection => @topics, :locals => {:xm => xml}
end
