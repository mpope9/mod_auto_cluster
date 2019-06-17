defmodule ModAutoCluster.ZooKeeperBackend do
  alias :erlzk, as: ZooKeeper
  import Ejabberd.Logger
  import StatRecord

  @moduledoc """
  This module is for the Apache ZooKeeper backend.
  Does not watch the ZooKeeper node for changes.

  Connects to ZooKeeper, then checks if the node exists.
  If not the node is created, and the data is set to the single node name.
  """

  def cluster(opts) do
    info("Attempting to cluster using ZooKeeper as a backend")

    ZooKeeper.start()

    host_opts  = [{:erlang.binary_to_list(opts[:host]), opts[:port]}]
    znode      = opts[:node]

    # TODO: Fail more gracefully.
    {:ok, pid} = ZooKeeper.connect(host_opts, opts[:timeout])

    with {:ok, _stat}             <- ZooKeeper.exists(pid, znode),
         {:ok, {node_list, stat}} <- ZooKeeper.get_data(pid, znode)
    do 
      new_node_list = ModAutoCluster.join_cluster(node_list)
      version       = stat(stat, :version)
      {:ok, _stat}  = ZooKeeper.set_data(pid, znode, new_node_list, version)

      ZooKeeper.close(pid)

      :ok
    else
      {:error, :no_node} -> 
        info("No existing ZooKeeper node.  Setting as 'master'.")
        binary_list   = :erlang.term_to_binary([node()])
        {:ok, znode}  = ZooKeeper.create(pid, znode)
        {:ok, stat}   = ZooKeeper.exists(pid, znode)
        version       = stat(stat, :version)
        {:ok, _stat}  = ZooKeeper.set_data(pid, znode, binary_list, version)
        ZooKeeper.close(pid)
        :ok

      {:error, :closed} ->
        error("ZooKeeper appears to be re-connecting.")
        ZooKeeper.close(pid)
        :error
      {:error, :no_auth} ->
        error("ZooKeeper is not propertly auth'd.")
        ZooKeeper.close(pid)
        :error
      {:error, _} ->
        error("Undefined ZooKeeper error.")
        ZooKeeper.close(pid)
        :error
    end
  end
end
