require 'json'
require 'nokogiri'
require 'open-uri'
require_relative 'image_download'

class Harvest
  def self.harvest(uri_str)
    doc = begin
            URI.open(uri_str)
          rescue Errno::ENOENT
            $stderr.puts "Unable to open #{uri_str}"
            exit
          end

    html = Nokogiri::HTML(doc)
    attrs = parse(html, link_for(html, uri_str))
    attrs.merge(image: ImageDownload.fetch(attrs[:thumbnail]))
  end

  # The link to store for the recipe: the page's canonical URL when it declares one, so
  # share links don't carry tracking parameters or personal tokens (e.g. NYT's
  # ?unlocked_article_code=...&smid=...) into the published recipe; otherwise the URL given.
  def self.link_for(html, uri_str)
    href = html.at_css('link[rel="canonical"]')&.[]('href').to_s.strip
    return uri_str if href.empty?

    canonical = URI.join(uri_str, href)
    canonical.is_a?(URI::HTTP) ? canonical.to_s : uri_str
  rescue URI::Error
    uri_str
  end

  # Override this in subclasses
  def self.parse(html, uri_str)
    html
  end
end
