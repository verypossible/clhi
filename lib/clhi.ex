defmodule Clhi do
  @moduledoc """
  A CLI helper for asking questions.
  """

  def ask(question, options, opts \\ []) do
    default_opts = [
      boolean_options: false,
      number_options: false,
      hide_options: false,
      stringyify_options: true,
      cast_answer: false,
      default: nil
    ]

    opts = override_defaults(default_opts, opts)

    gets_msg = build_gets_msg(opts)

    info(question)

    _ =
      unless opts.hide_options or opts.boolean_options do
        print_options(options, Map.to_list(opts))
      end

    parsed_options =
      if opts.stringyify_options,
        do: Enum.map(options, &to_string/1),
        else: options

    with {:ok, answer} <- parse_choice(gets(msg: gets_msg), parsed_options, opts),
         {:ok, parsed_answer} <- parse_answer(answer, opts) do
      parsed_answer
    else
      {:error, error} ->
        warn("invalid choice: #{inspect(error)}")
        ask(question, options, opts)
    end
  end

  defp build_gets_msg(opts) do
    base_msg =
      case opts do
        %{boolean_options: true} -> "(y/n) "
        %{number_options: true} -> "(specify the number associated with your choice) "
        _ -> ""
      end

    defaulted_msg =
      if is_nil(opts.default),
        do: base_msg,
        else: "#{base_msg}default: #{opts.default} "

    "#{defaulted_msg}> "
  end

  defp parse_choice(choice, options, opts)

  defp parse_choice("", _, %{default: default}) when not is_nil(default), do: {:ok, "#{default}"}

  defp parse_choice("y", _, %{boolean_options: true}), do: {:ok, true}

  defp parse_choice("n", _, %{boolean_options: true}), do: {:ok, false}

  defp parse_choice(choice, options, %{number_options: true}) do
    options_length = length(options)

    case Integer.parse(choice) do
      :error ->
        {:error, :bad_integer}

      {index, _} ->
        if index > 0 and index < options_length,
          do: {:ok, Enum.at(options, index - 1)},
          else: {:error, :invalid_index}
    end
  end

  defp parse_choice(choice, [], _), do: {:ok, choice}

  defp parse_choice(choice, options, _) do
    if Enum.member?(options, choice),
      do: {:ok, choice},
      else: {:error, :not_a_provided_option}
  end

  defp parse_answer(answer, opts)

  defp parse_answer(answer, %{cast_answer: false}), do: {:ok, answer}

  defp parse_answer(answer, %{cast_answer: cast_answer}) when is_function(cast_answer),
    do: cast_answer.(answer)

  defp parse_answer(answer, %{cast_answer: :atom}), do: {:ok, String.to_existing_atom(answer)}

  defp parse_answer(answer, %{cast_answer: :date}), do: Date.from_iso8601(answer)

  defp print_options(options, opts) do
    default_opts = [
      number_options: true
    ]

    opts = override_defaults(default_opts, opts)

    for {option, index} <- Enum.with_index(options) do
      formatted_option =
        if opts.number_options,
          do: "#{index + 1}. #{option}",
          else: "* #{option}"

      IO.puts(formatted_option)
    end
  end

  def info(msg), do: IO.puts(["\n", msg, IO.ANSI.reset()])

  def warn(msg), do: info([IO.ANSI.yellow(), msg])

  def error(msg), do: info([IO.ANSI.red(), msg])

  def gets(opts) do
    default_opts = [
      msg: "> ",
      trim: true
    ]

    opts = override_defaults(default_opts, opts)

    IO.puts("")

    ret =
      opts.msg
      |> IO.gets()
      |> String.slice(0..-2)

    if opts.trim,
      do: ret,
      else: String.trim(ret)
  end

  defp override_defaults(default_opts, opts) do
    opt_map = Enum.into(opts, %{})

    default_opts
    |> Enum.into(%{})
    |> Map.merge(opt_map)
  end
end
