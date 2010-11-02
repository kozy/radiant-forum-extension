xml.channel do
  xml.atom :link, nil, {
    :href => forum_topic_url(@topic.forum, @topic, :format => 'rss'),
    :rel => 'self', :type => 'application/rss+xml'
  }

  xml.title "#{@site_title} : #{@topic.name}"
  xml.description t('forums.rss.show_topic.description', :posts_length => @posts.length, :last_post_reader_name => @posts.last.reader.name, :date => @posts.last.created_at.to_s(:informal))
  xml.link forum_topic_url(@topic.forum, @topic)
  xml.language t('forums.lang')
  xml.ttl "60"

  render :partial => "posts/post", :collection => @posts, :locals => {:xm => xml}
end
