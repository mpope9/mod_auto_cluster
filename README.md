# ModAutoCluster

This module is used for autoclustering, using common distributed configuration services/key value stores.

Follow the [ejabberd documentation](https://docs.ejabberd.im/admin/guide/clustering/) on clustering and cookies before attempting to configure this module.  Its recommended that manual custering works well before this is attempted.

Generally behavior is as follows:
* If nothing is returned from the backend
    * Create list of nodes
    * Add self as the entry
* Otherwise
    * Get list of nodes from backend
    * Find first available node
    * Join cluster
    * Sweep previous nodes that are not responsive
    * Add self to list of nodes
    * Re-write list of nodes to backend

The reasoning behind this is that nodes may crash and not be able to remove themselves from the backend.  So cleanup happens when the current nodes attempts to join and finds them unresponsive.

Currently the folling backends are supported
* [Apache ZooKeeper](https://zookeeper.apache.org/).
* [etcd](https://github.com/etcd-io/etcd).

Note: This module is pretty heavy on dependencies.

## Installation
If you're using mix, then clone this repo and copy the `.ex` files from `mod_auto_cluster/lib` to `ejabberd/lib`.  Then run `mix compile` then `iex --sname <short_node_name> -S mix` to spin up a new named node.

If you're doing a traditional ejabberd deploy using `make` and `rebar`, you'll need to clone this module to `.ejabberd_modules/sources` and make a mix task to copy the `.beam` files to `~/.ejabberd_modules/ModAutoCluster`

To do manual testing for this repo, use the mix instructions, except in the root of this module.

## Backends and Example Configuration
Add these to your `ejabberd.yml` file.
Only providing the backend name as a `backend` defaults to the values shown.
### ZooKeeper 
```
ModAutoCluster:
  backend: zookeeper
  host: "localhost"
  port: 2181
  timeout: 30000
  node: "/mod_auto_cluter"
```

### etcd
* Note only one host is supported at this time even though `eetcd` supports a list of hosts.
* Also note that ssl is not supported right now.
```
ModAuthCluster:
  backend: etcd
  host: "localhost"
  port: 2379
  key: "mod_auto_cluster"
```

## TODOs
* etcd ssl
* etcd multi-host
* consul
* ????
* Tests
* Cookie / cookie file from backend?

Background for this module can be found [in ejabberd's Elixir sips](https://blog.process-one.net/elixir-sips-ejabberd-with-elixir-part-1/).
