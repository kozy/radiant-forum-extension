xml.channel do
  xml.atom :link, nil, {
    :href => formatted_posts_url(:rss),
    :rel => 'self', :type => 'application/rss+xml'
  }

  xml.title "#{@site_title} : " + t('forums.latest_posts.title')
  xml.description t('forums.latest_posts.description')
  xml.link posts_url
  xml.language t('forums.lang')
  xml.ttl "60"

  render :partial => "post", :collection => @posts, :locals => {:xm => xml}
end
