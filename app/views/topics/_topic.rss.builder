xm.item do
  suffix = 
  xm.title h("#{topic.name} (" + t("forums.started_by_reader_name") + topic.reader.name)
  
  xm.description truncate_words(topic.posts.first.body, 64)
  xm.pubDate topic.created_at.to_s(:rfc822)
  xm.guid [ActionController::Base.session_options[:session_key], topic.forum_id.to_s, topic.id.to_s].join(":"), "isPermaLink" => "false"
  xm.author h(topic.reader.name)
  xm.link forum_topic_url(topic.forum, topic)
end
