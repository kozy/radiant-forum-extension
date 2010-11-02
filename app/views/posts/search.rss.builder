xml.channel do
  xml.atom :link, nil, {
    :href => search_posts_url(:rss),
    :rel => 'self', :type => 'application/rss+xml'
  }

  xml.title "#{@site_title} : " + t('forums.forum_search_title')
  xml.description @title
  xml.link search_posts_url(params)
  xml.language t('forums.lang')
  xml.ttl "60"

  render :partial => "post", :collection => @posts, :locals => {:xm => xml}
end
