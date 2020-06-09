defmodule HukumSocketsWeb.SpaController do
  use HukumSocketsWeb, :controller

  def index(conn, _params) do
    redirect(conn, to: "/index.html")
  end
end
