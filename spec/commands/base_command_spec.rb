require "rails_helper"

RSpec.describe Commands::BaseCommand do
  let(:top_level_worker) { double(:top_level_worker, some_method: nil) }
  let(:nested_worker) { double(:nested_worker, some_method: nil) }

  class TopLevelCommand < Commands::BaseCommand
    def call
      after_transaction_commit do
        payload[:top_level_worker].some_method
      end

      NestedCommand.call(payload, callbacks: callbacks, nested: true)
    end
  end

  class NestedCommand < Commands::BaseCommand
    def call
      after_transaction_commit do
        payload[:nested_worker].some_method
      end
    end
  end

  class Commands::SlowCommand < Commands::BaseCommand
    def call
      :foo
    end
  end

  describe "callbacks for nested commands" do
    it "executes callbacks at the top level of the command tree" do
      expect(TopLevelCommand).to receive(:execute_callbacks)
      expect(NestedCommand).not_to receive(:execute_callbacks)

      TopLevelCommand.call({})
    end

    it "executes all callbacks from every level of the command tree" do
      expect(top_level_worker).to receive(:some_method)
      expect(nested_worker).to receive(:some_method)

      payload = {
        top_level_worker: top_level_worker,
        nested_worker: nested_worker,
      }

      TopLevelCommand.call(payload)
    end
  end

  describe "timing" do
    it "sends a command's duration to statsd" do
      stub_const("Process::CLOCK_MONOTONIC", 6)
      allow(Process).to receive(:clock_gettime)
      allow(Process).to receive(:clock_gettime)
        .with(Process::CLOCK_MONOTONIC, :nanosecond)
        .and_return(1_472_243_573_027_000, 1_472_246_723_347_000)

      expect(PublishingAPI.service(:statsd)).to receive(:timing) do |name, time, sample_rate|
        expect(name).to eq "Commands.SlowCommand"
        expect(time).to eq(3150)
        expect(sample_rate).to eq 1
      end

      expect(Commands::SlowCommand.call({ foo: "bar" })).to eq :foo
    end
  end
end
