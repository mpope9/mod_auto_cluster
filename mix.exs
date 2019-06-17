defmodule ModAutoCluster.MixProject do
  use Mix.Project

  def project do
    [
      app: :mod_auto_cluster,
      version: "0.0.1",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      applications: [:logger, :ejabberd]
    ]
  end

  defp deps do
    [ 
      {:ejabberd, git: "https://github.com/processone/ejabberd.git", branch: "master"},
      {:erlzk, "~> 0.6.4"},
      {:eetcd, git: "https://github.com/zhongwencool/eetcd", branch: "master"}
    ]
  end
end
