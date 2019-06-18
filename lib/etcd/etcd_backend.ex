defmodule ModAutoCluster.EtcdBackend do
  alias :eetcd_kv, as: Etcd
  alias ModAutoCluster.Helpers.Cluster, as: Cluster
  import Ejabberd.Logger
  import EtcdRangeRequestRecord
  import EtcdRangeResponseRecord
  import EtcdPutRequestRecord
  import EtcdKeyValueRecord

  @moduledoc """
  This is for the etcd backend.
  Does not watch etcd for changes.
  """

  def cluster(host, opts) do
    info("Attempting to cluster using etcd as a backend.")

    key      = opts[:key]
    hostname = "#{opts[:host]}:#{opts[:port]}" |> :erlang.binary_to_list

    Application.put_env(:eetcd, :etcd_cluster, [hostname])
    Application.put_env(:eetcd, :http2_transport, :tcp)
    Application.put_env(:eetcd, :http2_transport_opts, [])

    # Should probably detect startup failure better here.
    :gen_mod.start_child(:eetcd, host, opts)
    with range_request         <- etcd_range_request(key: key),
         {:ok, range_response} <- Etcd.range(range_request),
         count                 <- etcd_range_response(range_response, :count)
    do 
      case count do 
        0 ->
          new_node = 
            [node()] 
            |> :erlang.term_to_binary 
            |> :erlang.binary_to_list
          put_request = etcd_put_request(key: key, value: new_node)
          {:ok, _}    = Etcd.put(put_request)
        _ ->
          etcd_kvs      = etcd_range_response(range_response, :kvs)
          [key_value]   = etcd_kvs
          node_list     = etcd_key_value(key_value, :value)
          new_node_list = Cluster.join_cluster(node_list) |> :erlang.binary_to_list
          put_request   = etcd_put_request(key: key, value: new_node_list, ignore_value: true)
          {:ok, _}      = Etcd.put(put_request)
      end
    else
      {:error, _} -> 
        error("Error with etcd clustering.")
    end

    :gen_mod.stop_child(Etcd, host)

    :ok
  end
end
