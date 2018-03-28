defmodule Logger.Backends.Stackdriver do
  alias GoogleApi.Logging.V2.Api.Entries
  alias GoogleApi.Logging.V2.Connection

  @moduledoc """
  Backend integration for Google Stackdriver Logging.
  """

  @behaviour :gen_event
  @default_format "$time $metadata[$level] $message\n"
  @logging_api_endpoint "https://www.googleapis.com/auth/logging.write"
  @timestamp_format "{ISO:Extended}"

  defstruct level: nil,
            format: nil,
            metadata: nil,
            project: nil,
            logname: nil,
            session: nil,
            connection: nil

  def init({__MODULE__, :stackdriver}) do
    config =
      Application.get_env(:logger, :stackdriver)
      |> configure(%__MODULE__{})

    {:ok, config}
  end

  def init({__MODULE__, opts}) when is_list(opts) do
    config = Keyword.merge(Application.get_env(:logger, :stackdriver), opts)
    {:ok, configure(config, %__MODULE__{})}
  end

  def handle_call({:configure, options}, state) do
    {:ok, :ok, configure(options, state)}
  end

  defp configure(config, state) do
    # Common config
    level = Keyword.get(config, :level)
    format_opts = Keyword.get(config, :format, @default_format)
    format = Logger.Formatter.compile(format_opts)
    metadata = Keyword.get(config, :metadata, [])

    # Stackdriver config
    project = Keyword.get(config, :project)
    logname = Keyword.get(config, :logname)

    session = get_session()
    connection = get_connection(session.token)

    %{
      state
      | level: level,
        format: format,
        metadata: metadata,
        project: project,
        logname: logname,
        session: session,
        connection: connection
    }
  end

  defp get_session() do
    case Application.ensure_started(:goth) do
      {:error, {:not_started, _}} ->
        Goth.start(:normal, [])
    end

    {:ok, session} = Goth.Token.for_scope(@logging_api_endpoint)
    session
  end

  defp get_connection(token) do
    Connection.new(token)
  end

  def handle_event({level, _group_leader, {_lg, message, _ts, _md} = log_payload}, state) do
    state = renew_session(state)
    payload = compose_entry(level, log_payload, state)

    state.connection
    |> Entries.logging_entries_write(access_token: state.session.token, pp: true, body: payload)
    |> handle_response(message, state)
  end

  def handle_event(:flush, state), do: {:ok, state}

  def handle_event(_unknown, state) do
    {:ok, state}
  end

  defp handle_response({:ok, _response}, _message, state), do: {:ok, state}

  defp handle_response({:error, response}, message, state) do
    IO.inspect(response)
    IO.inspect(message)
    {:error, state}
  end

  defp renew_session(%__MODULE__{session: %Goth.Token{expires: expiry}} = state) do
    current_time = DateTime.utc_now() |> DateTime.to_unix()

    if current_time > expiry do
      session = get_session()

      %{
        state
        | session: session,
          connection: get_connection(session.token)
      }
    else
      state
    end
  end

  defp compose_entry(level, {Logger, message, timestamp, _metadata}, state) do
    time =
      timestamp
      |> format_timestamp

    %{
      entries: %{
        logName: get_logname(state),
        resource: get_resource(state),
        timestamp: time,
        receiveTimestamp: time,
        severity: get_severity(level),
        textPayload: message
      }
    }
    |> Poison.encode!()
  end

  defp get_logname(%__MODULE__{logname: logname, project: project}) do
    "projects/#{project}/logs/#{logname}"
  end

  defp get_resource(%__MODULE__{project: project}) do
    %{type: "global", labels: %{project_id: project}}
  end

  defp get_severity(:debug), do: "DEBUG"
  defp get_severity(:info), do: "INFO"
  defp get_severity(:warn), do: "WARNING"
  defp get_severity(:error), do: "ERROR"

  defp format_timestamp(timestamp) do
    timestamp
    |> Timex.to_datetime(:local)
    |> Timex.format!(@timestamp_format)
  end

  def handle_info(_unknown, state), do: {:ok, state}
  def terminate(_reason, _state), do: :ok
end
