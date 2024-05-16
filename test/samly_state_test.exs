defmodule Samly.StateTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "create_relay_state" do
    conn = conn(:get, "/relay-state-path")

    default_relay_state_length = Samly.State.gen_id() |> String.length()
    assert Samly.State.init(Samly.State.ETS, [], &Samly.State.gen_id/1) == :ok
    assert Samly.State.create_relay_state(conn) |> String.length() == default_relay_state_length

    assert Samly.State.init(Samly.State.ETS, [], "relay_state_string") == :ok
    assert Samly.State.create_relay_state(conn) == "relay_state_string"

    relay_state_fun = fn conn -> "#{conn.scheme}://#{conn.host}#{conn.request_path}" end
    assert Samly.State.init(Samly.State.ETS, [], relay_state_fun) == :ok
    assert Samly.State.create_relay_state(conn) == relay_state_fun.(conn)

    for relay_state_param <- [1, fn -> "0arity" end, fn _, _ -> "2arity" end] do
      assert Samly.State.init(Samly.State.ETS, [], relay_state_param) == :ok

      assert_raise RuntimeError, ~r/^Invalid relay_state/, fn ->
        Samly.State.create_relay_state(conn)
      end
    end
  end

  describe "With Session Cache" do
    setup do
      opts =
        Plug.Session.init(
          store: :cookie,
          key: "_samly_state_test_session",
          encryption_salt: "salty enc",
          signing_salt: "salty signing",
          key_length: 64
        )

      Samly.State.init(Samly.State.Session)

      conn =
        conn(:get, "/")
        |> Plug.Session.call(opts)
        |> fetch_session()

      [conn: conn]
    end

    test "put/get assertion", %{conn: conn} do
      not_on_or_after = DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()
      assertion = %Samly.Assertion{subject: %{notonorafter: not_on_or_after}}
      assertion_key = {"idp1", "name1"}
      conn = Samly.State.put_assertion(conn, assertion_key, assertion)
      assert assertion == Samly.State.get_assertion(conn, assertion_key)
    end

    test "get failure for unknown assertion key", %{conn: conn} do
      assertion = %Samly.Assertion{}
      assertion_key = {"idp1", "name1"}
      conn = Samly.State.put_assertion(conn, assertion_key, assertion)
      assert is_nil(Samly.State.get_assertion(conn, {"idp1", "name2"}))
    end

    test "get failure for expired assertion key", %{conn: conn} do
      assertion = %Samly.Assertion{}
      assertion_key = {"idp1", "name1"}
      conn = Samly.State.put_assertion(conn, assertion_key, assertion)
      assert is_nil(Samly.State.get_assertion(conn, {"idp1", "name1"}))
    end

    test "delete assertion", %{conn: conn} do
      not_on_or_after = DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()
      assertion = %Samly.Assertion{subject: %{notonorafter: not_on_or_after}}
      assertion_key = {"idp1", "name1"}
      conn = Samly.State.put_assertion(conn, assertion_key, assertion)
      assert assertion == Samly.State.get_assertion(conn, assertion_key)
      conn = Samly.State.delete_assertion(conn, assertion_key)
      assert is_nil(Samly.State.get_assertion(conn, assertion_key))
    end
  end

  describe "With ETS Cache" do
    setup do
      Samly.State.init(Samly.State.ETS)
      [conn: conn(:get, "/")]
    end

    test "put/get assertion", %{conn: conn} do
      not_on_or_after = DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()
      assertion = %Samly.Assertion{subject: %{notonorafter: not_on_or_after}}
      assertion_key = {"idp1", "name1"}
      conn = Samly.State.put_assertion(conn, assertion_key, assertion)
      assert assertion == Samly.State.get_assertion(conn, assertion_key)
    end

    test "get failure for unknown assertion key", %{conn: conn} do
      assertion = %Samly.Assertion{}
      assertion_key = {"idp1", "name1"}
      conn = Samly.State.put_assertion(conn, assertion_key, assertion)
      assert is_nil(Samly.State.get_assertion(conn, {"idp1", "name2"}))
    end

    test "get failure for expired assertion key", %{conn: conn} do
      assertion = %Samly.Assertion{}
      assertion_key = {"idp1", "name1"}
      conn = Samly.State.put_assertion(conn, assertion_key, assertion)
      assert is_nil(Samly.State.get_assertion(conn, {"idp1", "name1"}))
    end

    test "delete assertion", %{conn: conn} do
      not_on_or_after = DateTime.utc_now() |> DateTime.add(8, :hour) |> DateTime.to_iso8601()
      assertion = %Samly.Assertion{subject: %{notonorafter: not_on_or_after}}
      assertion_key = {"idp1", "name1"}
      conn = Samly.State.put_assertion(conn, assertion_key, assertion)
      assert assertion == Samly.State.get_assertion(conn, assertion_key)
      conn = Samly.State.delete_assertion(conn, assertion_key)
      assert is_nil(Samly.State.get_assertion(conn, assertion_key))
    end
  end
end
