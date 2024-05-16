defmodule Samly.State do
  @moduledoc false

  @state_store :state_store

  def init(store_provider, opts \\ [], relay_state \\ &gen_id/1) do
    opts = store_provider.init(opts)

    Application.put_env(:samly, @state_store, %{
      provider: store_provider,
      opts: opts,
      relay_state: relay_state
    })
  end

  def get_assertion(conn, assertion_key) do
    %{provider: store_provider, opts: opts} = Application.get_env(:samly, @state_store)
    store_provider.get_assertion(conn, assertion_key, opts)
  end

  def put_assertion(conn, assertion_key, assertion) do
    %{provider: store_provider, opts: opts} = Application.get_env(:samly, @state_store)
    store_provider.put_assertion(conn, assertion_key, assertion, opts)
  end

  def delete_assertion(conn, assertion_key) do
    %{provider: store_provider, opts: opts} = Application.get_env(:samly, @state_store)
    store_provider.delete_assertion(conn, assertion_key, opts)
  end

  @spec create_relay_state(Plug.Conn.t()) :: String.t()
  def create_relay_state(conn) do
    case Application.get_env(:samly, @state_store).relay_state do
      relay_state when is_function(relay_state, 1) ->
        relay_state.(conn)

      relay_state when is_binary(relay_state) ->
        relay_state

      relay_state ->
        raise "Invalid relay_state: expected a function of arity 1 or a string, got #{inspect(relay_state)}"
    end
  end

  @spec gen_id(Plug.Conn.t()) :: String.t()
  def gen_id(_conn) do
    gen_id()
  end

  @spec gen_id :: String.t()
  def gen_id do
    24 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
  end
end
