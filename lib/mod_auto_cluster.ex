defmodule ModAutoCluster do
  alias :erlzk, as: ZooKeeper

  import Ejabberd.Logger

  @behaviour :gen_mod

  @moduledoc """
  Module to take care of autoclustering for Ejabberd.
  """

  def start(host, opts) do
    info("Starting mod_auto_cluster")

    backend = 
      :gen_mod.get_opt(:backend, opts) 
      |> String.to_atom

    case backend do
      :zookeeper ->
        zookeeper_opts = get_zookeeper_opts(opts)
        ModAutoCluster.ZooKeeperBackend.cluster(zookeeper_opts)
        :ok
      :etcd ->
        etcd_opts = get_etcd_opts(opts)
        ModAutoCluster.EtcdBackend.cluster(host, etcd_opts)
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

  # Takes values from backend, covertes them from binaries to a list of atoms and iterates over them.
  def join_cluster(node_list) do 
    {_, new_node_list} = 
      node_list
      |> :erlang.binary_to_term
      |> Enum.reduce({:false, []}, &adjust_node_list/2)
    
    info("Joined cluster and scrubbed old nodes!")

    new_node_list ++ [node()] |> :erlang.term_to_binary
  end

  # Loops through all values.
  # If the ping doesn't succeed / we're the node, remove from list.
  # If already clustered and ping succeeds, append to output.
  # If not clustered and clustering fails, remove from list and try again.
  # If not clustered and clustering succeeds, add to list and set clustered.
  defp adjust_node_list(value, {clustered, acc}) do
      case {clustered, :net_adm.ping(value)} do
        {:true, :pong} ->
          debug("Already clustered and found a live node")
          {clustered, acc ++ [value]}

        {:false, :pong} ->
          case :ejabberd_cluster.join(value) do
            :ok ->
              debug("Was able to join the ejabberd cluster.")
              {:true, acc ++ [value]}
            _ ->
              debug("Joining the ejabberd cluster failed.")
              {:false, acc}
          end
        _ ->
          debug("Found a dead node, removing from the list")
          {clustered, acc}
      end
  end

  def get_zookeeper_opts(opts) do
    [
      host:     :gen_mod.get_opt(:host, opts),
      port:     :gen_mod.get_opt(:port, opts, 2181),
      timeout:  :gen_mod.get_opt(:timeout, opts),
      node:     :gen_mod.get_opt(:node, opts)
    ]
  end

  def get_etcd_opts(opts) do
    [
      host: :gen_mod.get_opt(:host, opts),
      port: :gen_mod.get_opt(:port, opts, 2379),
      key:  :gen_mod.get_opt(:key, opts)
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
      host:     "127.0.0.1",
      timeout:  30000,
      node:     "/mod_auto_cluster"
    ]
  end

  def depends(_host, _opts), do: []
end
