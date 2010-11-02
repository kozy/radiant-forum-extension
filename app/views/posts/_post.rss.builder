xm.item do
  if post.first?
    xm.title t('forums.rss.new_topic_first_post', :topic_name => h(post.topic.name), :reader_name => h(post.reader.name))
  elsif (@topic && @topic == post.topic)
    xm.title t('forums.rss.topic_reply', :reader_name => h(post.reader.name))
  else
    xm.title t('forums.rss.topic_reply_and_from', :topic_name => h(post.topic.name), :reader_name => h(post.reader.name))
  end
  xm.description clean_textilize(truncate_words(post.body, 64))
  xm.pubDate post.created_at.to_s(:rfc822)
  xm.guid [ActionController::Base.session_options[:session_key], post.forum_id.to_s, post.topic_id.to_s, post.id.to_s].join(":"), "isPermaLink" => "false"
  xm.link paged_post_url(post)
end
