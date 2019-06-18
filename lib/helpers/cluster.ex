defmodule ModAutoCluster.Helpers.Cluster do

  import Ejabberd.Logger

  @moduledoc """
  Module of helper functions related to clustering.
  """

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

end
