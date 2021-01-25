class Newsletter
  attr_reader :data

  def initialize(params)
    @data = params
  end

  def valid?
    # data["X-Mailgun-Incoming"] == "Yes" && signature_valid?
    true
  end

  def token
    @token ||= begin
      full_token.split("+").first
    end
  end

  def full_token
    @full_token ||= begin
      to_email.sub("@" + ENV.fetch("NEWSLETTER_HOST", "newsletters.feedbin.com"), "").sub("@development.newsletters.feedbin.com", "").sub("test-subscribe+", "").sub("subscribe+", "")
    end
  end

  def to_email
    data["to"]
  end

  def from_email
    parsed_from.address
  end

  def from_name
    parsed_from.name || from_email
  end

  def name
    parsed_from.name
  end

  def subject
    data["subject"]
  end

  def text
    data["text"]
  end

  def html
    data["html"]
  end

  def content
    html || text
  end

  def timestamp
    Time.now.to_i
  end

  def feed_id
    @feed_id ||= Digest::SHA1.hexdigest("#{full_token}#{from_email}")
  end

  def entry_id
    @entry_id ||= Digest::SHA1.hexdigest("#{feed_id}#{subject}#{timestamp}")
  end

  def domain
    parsed_from.domain
  end

  def feed_url
    "#{site_url}?#{feed_id}"
  end

  def site_url
    @site_url ||= URI::HTTP.build(host: domain).to_s
  end

  def format
    html ? "html" : "text"
  end

  def headers
    {
      "List-Unsubscribe" => data["List-Unsubscribe"]
    }
  end

  private

  def parsed_from
    Mail::Address.new(data["from"])
  rescue Mail::Field::ParseError
    name, address = data["from"].split(/[<>]/).map(&:strip)
    domain = address.split("@").last
    OpenStruct.new(name: name, address: address, domain: domain)
  end

  def signature_valid?
    data["signature"] == signature
  end

  def signature
    @signature ||= begin
      digest = OpenSSL::Digest::SHA256.new
      signed_data = [data["timestamp"], data["token"]].join
      OpenSSL::HMAC.hexdigest(digest, ENV["MAILGUN_INBOUND_KEY"], signed_data)
    end
  end
end
