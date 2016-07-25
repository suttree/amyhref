# encoding: utf-8

class User < ActiveRecord::Base
  has_many :tokens, dependent: :destroy
  has_many :hrefs

  validates_uniqueness_of :email

  attr_accessor :classifier

  def bayes
    if @classifier.nil?
      @classifier = begin
        data = File.read(Rails.root + "bayes/#{self.email}.dat")
        Marshal.load(data)
      rescue Errno::ENOENT, ArgumentError
        ::ClassifierReborn::Bayes.new('Up', 'Down')
      end

      if @classifier.nil?
        @classifier = ClassifierReborn::Bayes.new('Up', 'Down')
      end
    end

    @classifier
  end

  # TODO switch to using StuffClassifier::TfIdf if the bayes alt is no good
  # see - https://github.com/alexandru/stuff-classifier
  def bayes_alt
    store = StuffClassifier::FileStorage.new("bayes/#{self.email}.dat2")

    if @classifier2.nil?
      @classifier2 = begin
        StuffClassifier::Bayes.new('Up or Down', :storage => store)
      rescue
        ::StuffClassifier::Bayes.new('Up or Down', :storage => store)
      end

      if @classifier2.nil?
        @classifier2 = StuffClassifier::Bayes.new('Up or Down', :storage => store)
      end
    end

    @classifier2
  end

  def snapshot
    snapshot = Marshal.dump(self.bayes)
    File.open('bayes/' + self.email + '.dat', 'wb') {|f| f.write(snapshot) }

    self.bayes_alt.save_state
  end
end
