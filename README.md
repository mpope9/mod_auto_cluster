# ModAutoCluster

This module is used for autoclustering, using common distributed configuration services/key value stores.

Follow the [ejabberd documentation](https://docs.ejabberd.im/admin/guide/clustering/) on clustering and cookies before attempting to configure this module.  Its recommended that manual custering works well before this is attempted.

Currently the only supported backend is [Apache ZooKeeper](https://zookeeper.apache.org/).

## Installation
If you're using mix to run ejabberd, you can add this repo as a dep in the `mix.exs` file, or clone this repo and copy the `.ex` files from `mod_auto_cluster/lib` to `ejabberd/lib`.  Then run `mix compile` then `iex --sname <short_node_name> -S mix` to spin up a new named node.

If you're doing a traditional ejabberd deploy using `make` and `rebar`, you'll need to clone this module to `.ejabberd_modules/sources` and make a mix task to copy the `.beam` files to `~/.ejabberd_modules/ModAutoCluster`

## Backends and Example Configuration
### ZooKeeper 
   * Only providing `backend` will use these default values for convenience.
   * Watches for changes so that when 
   * Current behavior is: if nothing is returned, create ZooKeeper node and add self.  Otherwise, join cluster, add self, and sweep previous nodes that are not responsive.
```
ModAutoCluster:
  backend: zookeeper
  host: "localhost"
  port: 2181
  timeout: 30000
  node: "/mod_auto_cluter"
```

## TODOs
* etcd
* consul
* ????
* Tests
* Cookie / cookie file from backend?

Background for this module can be found [in ejabberd's Elixir sips](https://blog.process-one.net/elixir-sips-ejabberd-with-elixir-part-1/).
