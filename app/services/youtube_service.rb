class YoutubeService
  attr_reader :keywords, :tags

  def initialize(params)
    @keywords = params[:keywords]
    @tags = params[:tags]
  end

  def videos
    videos = get_from_cache_or_youtube(keywords)
    videos = get_from_cache_or_youtube(tags) if videos[:items].empty?
    videos
  end

  private

  def get_from_cache_or_youtube(query)
    $REDIS.get(query) ? eval($REDIS.get(query)) : get_json(query)
  end

  def get_json(query)
    response = conn.get { |req| req.params[:q] = query }
    json = JSON.parse(response.body, symbolize_names: true)
    $REDIS.set(query, json, ex: 1.day)
    json
  end

  def conn
    Faraday.new("https://www.googleapis.com/youtube/v3/search") do |f|
      f.adapter Faraday.default_adapter
      f.params[:key] = ENV["YOUTUBE_DATA_KEY"]
      f.params[:part] = "snippet"
      f.params[:type] = "video"
      f.params[:videoEmbeddable] = "true"
      f.params[:maxResults] = "50"
      f.params[:publishedAfter] = (Time.current - 1.year).rfc3339
    end
  end
end
