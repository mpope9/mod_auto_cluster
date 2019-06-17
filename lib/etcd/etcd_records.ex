defmodule EtcdRangeRequestRecord do
  require Record

  Record.defrecord :etcd_range_request, 
                   :'Etcd.RangeRequest', 
                   Record.extract(:'Etcd.RangeRequest', 
                                  from: "deps/eetcd/include/router_pb.hrl")
end

defmodule EtcdRangeResponseRecord do
  require Record

  Record.defrecord :etcd_range_response, 
                   :'Etcd.RangeResponse', 
                   Record.extract(:'Etcd.RangeResponse', 
                                  from: "deps/eetcd/include/router_pb.hrl")
end

defmodule EtcdPutRequestRecord do
  require Record

  Record.defrecord :etcd_put_request, 
                   :'Etcd.PutRequest', 
                   Record.extract(:'Etcd.PutRequest', 
                                  from: "deps/eetcd/include/router_pb.hrl")
end

defmodule EtcdKeyValueRecord do
  require Record

  Record.defrecord :etcd_key_value, 
                   :'mvccpb.KeyValue', 
                   Record.extract(:'mvccpb.KeyValue', 
                                  from: "deps/eetcd/include/kv_pb.hrl")
end
