defmodule CollectedLiveWeb.Components.LinkPreview do
  use Phoenix.LiveComponent
  use Phoenix.HTML

  def render(assigns) do
    url = URI.parse(assigns.url)
    render_url(url)
  end

  def render_url(url = %{host: host, query: query}) when host in ["youtube.com", "www.youtube.com"] do
    assigns = %{}

    query_vars = URI.decode_query(query)

    ~L"""
    <div>
      YouTube Video
      <%= case query_vars["v"] do
        nil -> content_tag(:p, "Missing id of video")
        id -> content_tag(:"lite-video", "", videoid: id)
      end %>
    </div>
    """
  end

  def render_url(url = %{host: host, query: query}) do
    assigns = %{}
    ~L"""
    <div><%= host %></div>
    """
  end
end
