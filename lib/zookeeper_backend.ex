defmodule ModAutoCluster.ZooKeeperBackend do
  alias :erlzk, as: ZooKeeper
  import Ejabberd.Logger
  import StatRecord

  @moduledoc """
  This module is for the Apache ZooKeeper backend.
  Cuurrently auto-clusters only on startup.  
  Does not watch the ZooKeeper node for changes.

  Connects to ZooKeeper, then checks if the node exists.
  If not the node is created, and the data is set to the single node name.
  Otherwise, get the list, join first available, iterate overnodes while remove stale entries and adding self.
  This assumes that the list will never be empty if the node exists.
  """

  def join_cluster(opts) do
    info("Attempting to cluster using ZooKeeper as a backend")

    ZooKeeper.start()

    host_opts  = [{:erlang.binary_to_list(opts[:host]), opts[:port]}]
    znode      = opts[:node]

    # TODO: Fail more gracefully.
    {:ok, pid} = ZooKeeper.connect(host_opts, opts[:timeout])

    with {:ok, _stat}             <- ZooKeeper.exists(pid, znode),
         {:ok, {node_list, stat}} <- ZooKeeper.get_data(pid, znode)
    do 
      {_, new_node_list} = 
        node_list
        |> :erlang.binary_to_term
        |> Enum.reduce({:false, []}, &adjust_node_list/2)

      new_binary_list = 
        new_node_list ++ [node()]
        |> :erlang.term_to_binary
      
      version      = stat(stat, :version)
      {:ok, _stat} = ZooKeeper.set_data(pid, znode, new_binary_list, version)

      info("Joined cluster and scrubbed old nodes!")

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

  # Loops through all values.
  # If the ping doesn't succeed / we're the node, remove from list.
  # If already clustered and ping succeeds, append to output.
  # If not clustered and clustering fails, remove from list and try again.
  # If not clustered and clustering succeeds, add to list and set clustered.
  defp adjust_node_list(value, {clustered, acc}) do
      case {clustered, :net_adm.ping(value)} do
        {:true, {_, :pong}} ->
          {clustered, acc ++ [value]}

        {:false, {_, :pong}} ->
          case :ejabberd_cluster.join(value) do
            :ok ->
              {:true, acc ++ [value]}
            _ ->
              {:false, acc}
          end
        _ ->
          {clustered, acc}
      end
  end
end
