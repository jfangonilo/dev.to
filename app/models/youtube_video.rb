class YoutubeVideo
  attr_reader :id

  def initialize(data)
    @id = data[:id][:videoId]
  end
end
