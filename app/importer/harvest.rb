require 'open-uri'

class Harvest
  def self.harvest(uri_str)
    doc = begin
            open(uri_str)
          rescue Errno::ENOENT
            $stderr.puts "Unable to open #{uri_str}"
            exit
          end

    html = Nokogiri::HTML(doc)
    parse(html, uri_str)
  end
end
