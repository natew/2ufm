require "open-uri"

module PaperclipExtensions
  class UrlTempfile < Tempfile
    attr :content_type

    def initialize(url)
      @url = URI.parse(url)

      raise "Unable to determine filename for URL uploaded file." unless original_filename

      super("url_tempfile")

      Kernel.open(url) do |file|
        @content_type = file.content_type
        binmode
        write(file.read)
        flush
      end
    end

    def original_filename
      # Take the URI path and strip off everything after last slash, assume this
      # to be filename (URI path already removes any query string)
      match = @url.path.match(/^.*\/(.+)$/)
      return (match ? match[1] : nil)
    end
  end
end