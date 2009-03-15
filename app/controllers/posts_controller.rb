class PostsController < ApplicationController
  require 'cgi'

  no_login_required
  before_filter :find_topic_or_page, :except => [:index]
  before_filter :find_post, :except => [:index, :new, :preview, :create, :monitored]
  before_filter :build_post, :only => [:new, :preview, :create]
  before_filter :authenticate_reader, :except => [:index, :show]
  radiant_layout { |controller| controller.layout_for :forum }

  # protect_from_forgery :except => :create # because the post form is typically generated from radius tags, which are defined in a model with no access to the controller

  @@query_options = { :per_page => 25, :select => 'posts.*, topics.name as topic_name, forums.name as forum_name', :joins => 'inner join topics on posts.topic_id = topics.id inner join forums on topics.forum_id = forums.id', :order => 'posts.created_at desc' }
  
  # *** clear the cache

  # def initialize
  #   super
  #   @cache = ResponseCache.instance
  # end

  def index
    conditions = []
    params.delete :commit
    @searching = false
    [:reader_id, :forum_id, :topic_id, :q].each { |attr| params[attr].blank? ? params.delete(attr) : @searching = true }
    [:reader_id, :forum_id, :topic_id].each { |attr| conditions << Post.send(:sanitize_sql, ["posts.#{attr} = ?", params[attr]]) if params[attr] && !params[attr].blank? }
    conditions << Post.send(:sanitize_sql, ['LOWER(posts.body) LIKE ?', "%#{params[:q]}%"]) unless params[:q].blank?
    conditions = conditions.any? ? conditions.collect { |c| "(#{c})" }.join(' AND ') : nil
    @posts = Post.paginate(:all, @@query_options.merge(:conditions => conditions, :page => params[:page] || 1))
    @reader = Reader.find(params[:reader_id]) unless params[:reader_id].blank?
    @topic = Topic.find(params[:topic_id]) unless params[:topic_id].blank?
    @forum = Forum.find(params[:forum_id]) unless params[:forum_id].blank?
    @readers = Reader.find(:all, :select => 'distinct *', :conditions => ['id in (?)', @posts.collect(&:reader_id).uniq]).index_by(&:id)

    @title = ((defined? Site) ? current_site.name : Radiant::Config['site.title']) || ''
    @title << ": posts"
    @title << " matching '#{params[:q]}'" if params[:q]
    @title << " from #{@reader.name}" if @reader
    if @topic
      @title << " under #{@topic.name}"
    elsif @forum
      @title << " in #{@forum.name}"
    end
    render_page_or_feed
  end

  def monitored
    @searching = true
    options = @@query_options.merge(:conditions => ['monitorships.reader_id = ? and monitorships.active = ?', params[:reader_id], true])
    options[:joins] += ' inner join monitorships on monitorships.topic_id = topics.id'
    options[:page] = params[:page] || 1
    @posts = Post.paginate(:all, options)
    render_page_or_feed
  end

  def show
    respond_to do |format|
      format.html { redirect_to_page_or_topic }
      format.js { render :layout => false }
    end
  end

  # this is typically called by ajax to bring a comment form into a page or a reply form into a topic
  # if the reader is not logged in, authenticate_reader should intervene and return a login form instead

  def new
    return topic_locked if @topic && @topic.locked?
    respond_to do |format|
      format.html { render :template => 'posts/new' } # we specify because sometimes we're reverting from a post to create 
      format.js { render :template => 'posts/new', :layout => false }
    end
  end
  
  def preview
    return topic_locked if @topic && @topic.locked?
    @post.created_at = Time.now()
    respond_to do |format|
      format.html { render :template => 'posts/preview' }
      format.js { render :template => 'posts/preview', :layout => false }
    end
  end
  
  # javascript form sender sets params[:dispatch]
  # params[:commit] is set by clicking one of the submit buttons
  
  def create
    if (params[:dispatch] == 'revise' || params[:commit] =~ /revise/i)
      return new
    elsif (params[:dispatch] == 'preview' || params[:commit] =~ /preview/i)
      return preview
    else
      @topic = @page.find_or_build_topic if @page && !@topic
      @forum = @topic.forum
      return topic_locked if @topic.locked?
      @post  = @topic.posts.create!(params[:post])
      @cache.expire_response(@page.url) if @page
      respond_to do |format|
        format.html { redirect_to_page_or_topic }
        format.js { render :action => 'show', :layout => false }
      end
    end
  rescue ActiveRecord::RecordInvalid
    flash[:error] = 'Please post something!'
    respond_to do |format|
      format.html { render :action => 'new' }
      format.js { render :action => 'new', :layout => false }
    end
  end

  def topic_locked
    respond_to do |format|
      format.html do
        flash[:notice] = 'Topic is locked.'
        redirect_to_page_or_topic
      end
      format.js { render :partial => 'topics/locked' }
    end
    return
  end
    
  def edit
    respond_to do |format| 
      format.html { render }
      format.js { render :layout => false }
    end
  end
  
  def update
    @post.attributes = params[:post]
    @post.save!
  rescue ActiveRecord::RecordInvalid
    flash[:bad_reply] = 'Zut Alors!'
  ensure
    respond_to do |format|
      format.html { redirect_to_page_or_topic }
      format.js { render :layout => false }
      format.json {}
    end
  end

  def destroy
    @post.destroy
    flash[:notice] = "Post deleted."
    # check for posts_count == 1 because it's cached and counting the currently deleted post
    @post.topic.destroy and redirect_to forum_path(params[:forum_id]) if @post.topic && @post.topic.posts_count == 1
    respond_to do |format|
      format.html { redirect_to_page_or_topic }
    end
  end

  protected
    def authorized?
      action_name == 'create' || @post.editable_by?(current_user)
    end
            
    def find_topic_or_page
      if params[:page_id]
        @page = Page.find(params[:page_id])
      elsif params[:topic_id]
        @topic = Topic.find(params[:topic_id], :include => :forum)
      end
    end

    def find_post
      @post = @topic.posts.find(params[:id])
    end
    
    def build_post
      @post = Post.new(params[:post])
      @post.body.gsub!(/ +/, ' ') if @post.body
      @post.topic = @topic if @topic
      @post.reader = current_reader
    end

    def render_page_or_feed(template_name = action_name)
      respond_to do |format|
        format.html { render :action => template_name }
        format.rss  { render :action => template_name, :layout => false }
      end
    end
    
    def redirect_to_page_or_topic
      if (@post.topic.page)
        redirect_to @post.topic.page.url + "#comment_#{@post.id}"
      else
        redirect_to topic_url(@topic.forum, @topic, {:page => @post.topic_page, :anchor => "post_#{@post.id}"})
      end
    end
    
    def topic_locked
      respond_to do |format|
        format.html {
          flash[:notice] = 'This topic is locked.'
          redirect_to topic_url(@topic.forum, @topic)
        }
        format.js {
          render :template => 'locked', :layout => false
        }
      end
    end
    
end
