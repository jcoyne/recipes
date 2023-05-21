require 'open-uri'

class Harvest
  def self.harvest(uri_str)
    doc = begin
            URI.open(uri_str)
          rescue Errno::ENOENT
            $stderr.puts "Unable to open #{uri_str}"
            exit
          end

    html = Nokogiri::HTML(doc)
    parse(html, uri_str)
  end

  # Override this in subclasses
  def self.parse(html, uri_str)
    html
  end
end
