defmodule NVim.PluginSpec do
  use ESpec

  before do
    plugin.start_link
  end

  context "empty module" do
    defmodule EmptyPlugin do
      use NVim.Plugin
    end
    let :plugin, do: EmptyPlugin

    it "returns empty specs" do
      expect(plugin.specs).to eq([])
    end
  end

  describe ".on_event" do
    defmodule PluginWithEvents do
      use NVim.Plugin

      on_event :simple do
        "simple_event"
      end

      on_event :with_custom_pattern,
        pattern: "*.ex"
      do
        "event_with_custom_pattern"
      end

      on_event :with_eval_value,
        pre_evaluate: %{
          "getcwd()" => evaluated_value
        }
      do
        {"event_with_eval", evaluated_value}
      end

      on_event :with_multiple_evals,
        pre_evaluate: %{
          "getcwd()" => evaluated_value,
          "current_column()" => another_value
        }
      do
        {"event_with_multiple_evals", [evaluated_value, another_value]}
      end
    end

    let :plugin, do: PluginWithEvents
    let :simple_event_spec, do: Enum.at(plugin.specs, 0)
    let :event_with_custom_pattern_spec, do: Enum.at(plugin.specs, 1)
    let :event_with_eval_spec, do: Enum.at(plugin.specs, 2)
    let :event_with_multiple_evals_spec, do: Enum.at(plugin.specs, 3)

    it "creates a proper specification" do
      expect(simple_event_spec) |> to(have {:type, "autocmd"})
      expect(simple_event_spec) |> to(have {:name, "Simple"})
      expect(simple_event_spec) |> to(have {:sync, false})
      expect(simple_event_spec.opts) |> to(have {:pattern, "*"})

      expect(event_with_custom_pattern_spec.opts) |> to(have {:pattern, "*.ex"})
      expect(event_with_eval_spec.opts) |> to(have {:eval, "[getcwd()]"})
      expect(event_with_multiple_evals_spec.opts) |> to(have {:eval, "[getcwd(),current_column()]"})
    end

    it "addes command handlers" do
      expect(plugin.handle_rpc_method("autocmd", "Simple:*", []))
      |> to(eq {:ok, "simple_event"})

      expect(plugin.handle_rpc_method("autocmd", "WithCustomPattern:*.ex", []))
      |> to(eq {:ok, "event_with_custom_pattern"})

      expect(plugin.handle_rpc_method("autocmd", "WithEvalValue:*", [["evaluated_value"]]))
      |> to(eq {:ok, {"event_with_eval", "evaluated_value"}})

      expect(plugin.handle_rpc_method("autocmd", "WithMultipleEvals:*", [["evaluated_value", "another_evaluated_value"]]))
      |> to(eq {:ok, {"event_with_multiple_evals", ["evaluated_value", "another_evaluated_value"]}})
    end
  end

    describe ".function" do
      defmodule PlugWithFunction do
        use NVim.Plugin

        function simple_func do
          "simple_func"
        end

        function func_with_param(param) do
          {"func_with_param", param}
        end

        function func_with_param_and_eval(param),
          pre_evaluate: %{
            "some_value" => some_value
          }
        do
          {"func_with_param_and_eval", [param, some_value]}
        end
      end

      let :plugin, do: PlugWithFunction
      let :simple_func_spec, do: hd(plugin.specs)
      let :func_with_param_spec, do: List.at(plugin.specs, 1)
      let :func_with_param_and_eval_spec, do: List.at(plugin.specs, 1)

      it "creates a proper spec" do
        expect(simple_func_spec) |> to(have {:type, "function"})
        expect(simple_func_spec) |> to(have {:name, "SimpleFunc"})
        expect(simple_func_spec) |> to(have {:sync, true})
      end

      it "addes function handlers" do
        expect(plugin.handle_rpc_method("function", "SimpleFunc", []))
        |> to(eq {:ok, "simple_func"})
        expect(plugin.handle_rpc_method("function", "FuncWithParam", [["test_param"]]))
        |> to(eq {:ok, {"func_with_param", "test_param"}})
        expect(plugin.handle_rpc_method("function", "FuncWithParamAndEval", [["test_param"],["some_eval"]]))
        |> to(eq {:ok, {"func_with_param_and_eval", ["test_param", "some_eval"]}})
      end
    end

    describe ".command" do
      defmodule PlugWithCommands do
        use NVim.Plugin

        command simple_command  do
          "simple_command"
        end

        command command_with_params(param) do
          {"command_with_params", param}
        end

        command command_with_eval,
        pre_evaluate: %{
          "col('.')" => current_column
        }
        do
          {"command_with_eval", current_column}
        end

        command command_with_range,
        range: true
        do
          {"command_with_range", [range_start, range_end]}
        end

        command command_with_all_opts(params),
        pre_evaluate: %{
          "some_value_eval" => current_column
        },
        range: true
        do
          {"command_with_all_opts", [[range_start,range_end], [params], [current_column]]}
        end

        command command_with_complete, complete: "file" do
          "command_with_complete"
        end
      end

      let :plugin, do: PlugWithCommands
      let :simple_command_spec, do: Enum.at(plugin.specs, 0)
      let :command_with_params_spec, do: Enum.at(plugin.specs, 1)
      let :command_with_eval_spec, do: Enum.at(plugin.specs, 2)
      let :command_with_range_spec, do: Enum.at(plugin.specs, 3)
      let :command_with_all_opts_spec, do: Enum.at(plugin.specs, 4)
      let :command_with_complete_spec, do: Enum.at(plugin.specs, 5)

      it "creates a proper specification" do
        expect(simple_command_spec) |> to(have {:type, "command"})
        expect(simple_command_spec) |> to(have {:name, "SimpleCommand"})
        expect(simple_command_spec) |> to(have {:sync, false})

        expect(command_with_params_spec) |> to(have {:name, "CommandWithParams"})
        expect(command_with_params_spec.opts) |> to(have {:nargs, "*"})

        expect(command_with_eval_spec) |> to(have {:name, "CommandWithEval"})
        expect(command_with_eval_spec.opts) |> to(have {:eval, "[col('.')]"})

        expect(command_with_range_spec) |> to(have {:name, "CommandWithRange"})
        expect(command_with_range_spec.opts) |> to(have {:range, "%"})

        expect(command_with_all_opts_spec) |> to(have {:name, "CommandWithAllOpts"})
        expect(command_with_all_opts_spec.opts) |> to(have {:nargs, "*"})
        expect(command_with_all_opts_spec.opts) |> to(have {:eval, "[some_value_eval]"})
        expect(command_with_all_opts_spec.opts) |> to(have {:range, "%"})

        expect(command_with_complete_spec.opts) |> to(have {:complete, "file"})
      end

      it "addes command handlers" do
        expect(PlugWithCommands.handle_rpc_method("command", "SimpleCommand", []))
        |> to(eq {:ok, "simple_command"})

        expect(PlugWithCommands.handle_rpc_method("command", "CommandWithParams", [["some_param"]]))
        |> to(eq {:ok, {"command_with_params", ["some_param"]}})

        expect(PlugWithCommands.handle_rpc_method("command", "CommandWithParams", [["some_param","another_param"]]))
        |> to(eq {:ok, {"command_with_params", ["some_param", "another_param"]}})

        expect(PlugWithCommands.handle_rpc_method("command", "CommandWithEval", [["current_column_value"]]))
        |> to(eq {:ok, {"command_with_eval", "current_column_value"}})

        expect(PlugWithCommands.handle_rpc_method("command", "CommandWithRange", [[0,10]]))
        |> to(eq {:ok, {"command_with_range", [0,10]}})

        expect(PlugWithCommands.handle_rpc_method("command", "CommandWithAllOpts",
          [[0,10],["param1", "param2"],["evaluated_value"]]))
        |> to(eq {:ok, {"command_with_all_opts", [[0,10],[["param1", "param2"]],["evaluated_value"]]}})
      end
    end
end
