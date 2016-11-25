class HomeController < ApplicationController
  def index
    #@hrefs = Href.where(good: true).where('rating > -25 OR rating2 > 0').group('DATE(created_at)').order('created_at DESC').limit(12)
    @hrefs = Href.where(good: true).where('rating > -25').group('DATE(created_at)').order('created_at DESC').limit(12)
  end
end
