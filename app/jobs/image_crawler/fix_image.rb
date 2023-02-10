module ImageCrawler
  class FixImage
    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(entry_id)
      entry = Entry.find(entry_id)
      processed_url = entry.image.safe_dig("processed_url")

      return unless processed_url

      if exists?(processed_url)
        Sidekiq.logger.info "Skipping, image exists public_id=#{entry.public_id} processed_url=#{processed_url}"
        return
      else
        Sidekiq.logger.info "Attempting to fix image public_id=#{entry.public_id} processed_url=#{processed_url}"
      end

      entry.update(image: nil)

      ImageCrawler::EntryImage.perform_async(entry.public_id)
    end

    def exists?(url)
      url = URI.parse(url)
      response = client.head_object(ImageCrawler::Image::BUCKET, url.path.delete_prefix("/"))
      response.status == 200
    rescue Excon::Error::NotFound
      false
    end

    def client
      @client ||= Fog::Storage.new(STORAGE)
    end
  end
end