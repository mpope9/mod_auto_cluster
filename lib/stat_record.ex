defmodule StatRecord do
  require Record

  Record.defrecord :stat, Record.extract(:stat, from: "deps/erlzk/include/erlzk.hrl")
end
