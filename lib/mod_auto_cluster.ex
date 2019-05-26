defmodule ModAutoCluster do
  alias :erlzk, as: ZooKeeper

  import Ejabberd.Logger

  @behaviour :gen_mod

  @moduledoc """
  Module to take care of autoclustering for Ejabberd.
  """

  def start(_host, opts) do
    info("Starting mod_auto_cluster")

    backend = 
      :gen_mod.get_opt(:backend, opts) 
      |> String.to_atom

    case backend do
      :zookeeper ->
        zookeeper_opts = get_zookeeper_opts(opts)
        ModAutoCluster.ZooKeeperBackend.join_cluster(zookeeper_opts)
        :ok
      _ ->
        error("Non-valid backend was provided to mod_auto_cluster.")
        :error
    end
  end

  def stop(_host) do
    info("Stopping mod_auto_cluster")

    # Stop all backends, no way to tell the actal active one at this point?
    ZooKeeper.stop()
  end

  def get_zookeeper_opts(opts) do
    [
      host:     :gen_mod.get_opt(:host, opts),
      port:     :gen_mod.get_opt(:port, opts),
      timeout:  :gen_mod.get_opt(:timeout, opts),
      node:     :gen_mod.get_opt(:node, opts)
    ]
  end

  def mod_opt_type(:backend), do: fn (opt) when is_binary(opt)  -> opt end
  def mod_opt_type(:host),    do: fn (opt) when is_binary(opt)  -> opt end
  def mod_opt_type(:port),    do: fn (opt) when is_integer(opt) -> opt end
  def mod_opt_type(:timeout), do: fn (opt) when is_integer(opt) -> opt end
  def mod_opt_type(:node),    do: fn (opt) when is_binary(opt)  -> opt end

  def mod_options(_host) do 
    [
      backend:  "",
      host:     "localhost",
      port:     2181,
      timeout:  30000,
      node:     "/mod_auto_cluster"
    ]
  end

  def depends(_host, _opts), do: []
end
