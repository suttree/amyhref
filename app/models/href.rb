# encoding: utf-8

class Href < ActiveRecord::Base
  validates_presence_of :url

  # the following gives...
  # uniq urls per user/newsletter
  # uniq domain+path per user/newsletter
  # saves on dupe urls with different query strings (common in newsletter tracking)
  validates_uniqueness_of :url, :scope => [:newsletter, :user] 
  validates_uniqueness_of :path, :scope => [:domain, :newsletter, :user] 

  belongs_to :user
  belongs_to :newsletter, :touch => true

  before_save :strip_tracking_parameters!
  before_save :set_domain
  before_save :set_path

  after_create :initial_classification

  require 'uri'

  def parse
    URI.parse(self.url.to_s)
  end

  def host
    self.parse.host
  end

  def parse_path
    self.parse.path
  end

  def query_string
    self.parse.query
  end

  def unshorten
    self.url = RedirectFollower(self.url)
  end

  def follow_simple_redirects
    RedirectFollower(self.url)
  end

  def reclassify
    initial_classification
    self.save
  end

  def train(key, value)
    5.times do
      self.user.bayes.train(key.to_sym, value)
      GlobalBayes.instance.train(key.to_sym, value)
      #self.user.bayes_alt.train(key.to_sym, value)
    end

    self.reclassify

    self.user.bayes.classifications(value)
  end

  def strip_tracking_parameters!
    # From http://stackoverflow.com/questions/12822347/how-can-i-remove-google-tracking-parameters-utm-from-an-url
    uri = URI.parse(self.url)
    begin
      clean_key_vals = URI.decode_www_form(uri.query).reject{|k, _| k.start_with?('utm_')}
      uri.query = URI.encode_www_form(clean_key_vals)
    rescue Exception => e
      #puts e.message
    end

    if uri.to_s.ends_with? '?'
      uri = uri.to_s.chomp('?')
    end

    self.url = uri.to_s
  end

  protected
  def set_domain
    self.domain = self.host
  end

  def set_path
    self.path = self.parse.path
  end

  # Callback to set the initial classification
  # - skip the bayes_alt stuff as it's not as good as the original
  def initial_classification
    self.url.to_s.strip!

    # per-user ranking
    bayes = self.user.bayes
    path_status = bayes.classify(self.path).downcase rescue 'down'
    host_status = bayes.classify(self.host).downcase rescue 'down'
    url_status = bayes.classify(self.url).downcase rescue 'down'

    # alt per-user ranking
    #bayes_alt = self.user.bayes_alt
    #path_status2 = bayes_alt.classify(self.path).downcase rescue 'down'
    #host_status2 = bayes_alt.classify(self.host).downcase rescue 'down'
    #url_status2 = bayes_alt.classify(self.url).downcase rescue 'down'

    # global ranking
    GlobalBayes.instance.classify(self.path).downcase rescue 'down'
    GlobalBayes.instance.classify(self.host).downcase rescue 'down'
    GlobalBayes.instance.classify(self.url).downcase rescue 'down'

    # save rankings
    self.good_host = true if host_status == 'up'
    self.good_path = true if path_status == 'up'
    self.good_path = false if self.path == '/' # we much prefer deep links

    self.rating = bayes.classifications(self.url).sort{ |k,v| v[0].to_i }.reverse.first[1].to_f rescue false
    self.rating = false if self.rating.to_s == 'Infinity'

    # save alt rankings
    #self.good_host2 = true if host_status2 == 'up'
    #self.good_path2 = true if path_status2 == 'up'

    #self.rating2 = bayes_alt.cat_scores(self.url)[0][1].to_f rescue false

    # reinforce good urls
    if self.good_host? && self.good_path?
      self.user.bayes.train(:Up, self.url)
      self.user.bayes_alt.train(:Up, self.url)
    end

    if url_status == 'up' || (self.good_host? && self.good_path?)
      self.good = true
    #elsif url_status2 == 'up' || (self.good_host2? && self.good_path2?)
    #  self.good = true
    else
      self.good = false
    end

    self.save
  end
end
