class YouController < ApplicationController
  before_filter :require_user
  before_filter :fetch_newsletters

  def index
    @hrefs = if params[:id].present?
      current_user.hrefs.where(good: true).where(['id < ?', params[:id]]).order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)
    else
      current_user.hrefs.where(good: true).order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)
    end

    if request.xhr?
      render :partial => 'shared/hrefs'
    else
      render
    end
  end

  def highlights
    #@hrefs = current_user.hrefs.where(good: true).where('rating > -25 OR rating2 > 0').group('DATE(created_at), newsletter_id').order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)
    @hrefs = current_user.hrefs.where(good: true).where('rating > -25').group('DATE(created_at), newsletter_id').order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)

    if request.xhr?
      render :partial => 'shared/href', :collection => @hrefs
    else
      render action: :index
    end
  end

  def lowlights
    #@hrefs = current_user.hrefs.where(good: true).where('rating < 25 OR rating2 < 0').group('DATE(created_at), newsletter_id').order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)
    @hrefs = current_user.hrefs.where(good: true).where('rating < 25').group('DATE(created_at), newsletter_id').order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)

    if request.xhr?
      render :partial => 'shared/href', :collection => @hrefs
    else
      render action: :index
    end
  end

  def newsletter
    @newsletter = Newsletter.where(id: params[:newsletter_id]).first
    @hrefs = current_user.hrefs.where(good: true, newsletter_id: @newsletter.id).order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)

    if request.xhr?
      render :partial => 'shared/hrefs'
    else
      render action: :index
    end
  end

  def search
    query = '%' + params[:q].downcase + '%'
    @hrefs = current_user.hrefs.joins(:newsletter).where(good: true).where(['LOWER(hrefs.url) LIKE ? OR LOWER(newsletters.email) = ?', query, query]).order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)

    if request.xhr?
      render :partial => 'shared/href', :collection => @hrefs
    else
      render action: :index
    end
  end

  def spam
    @hrefs = current_user.hrefs.where(good: false).order('created_at DESC, rating ASC').paginate(:page => params[:page], :per_page => 6)

    if request.xhr?
      render :partial => 'shared/href', :collection => @hrefs
    else
      render action: :index
    end
  end

  def up
    @href = Href.find(params[:id])
    render # do this asap

    @href.train(:Up, @href.url)
    @href.train(:Up, @href.domain)
    @href.train(:Up, @href.path)

    @href.update_attributes(good: true, good_host: true, good_path: true, good_host2: true, good_path2: true)

    current_user.snapshot if rand(3) == 0
  end

  def down
    @href = Href.find(params[:id])
    render # do this asap

    @href.train(:Down, @href.url)
    @href.train(:Down, @href.domain)
    @href.train(:Down, @href.path)

    @href.update_attributes(good: false, good_host: false, good_path: false, good_host2: false, good_path2: false)

    current_user.snapshot if rand(3) == 0
  end

  protected
  def fetch_newsletters
    # written a bit longhand to avoid a weird/slow MySQL query
    newsletter_ids = current_user.hrefs.select(:newsletter_id).where(good: true).group(:newsletter_id)
    ids = newsletter_ids.collect{ |n| n.newsletter_id }.uniq
    @newsletters = Newsletter.where(id: ids).order('updated_at DESC')
  end
end
