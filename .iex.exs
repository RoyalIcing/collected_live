defmodule App do
  def restart do
    Application.stop(:collected_live)
    Application.stop(:collected_live_web)
    recompile()
    Application.ensure_all_started(:collected_live)
    Application.ensure_all_started(:collected_live_web)
  end
end
