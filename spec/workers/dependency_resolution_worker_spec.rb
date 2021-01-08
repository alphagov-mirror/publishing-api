require "rails_helper"

RSpec.describe DependencyResolutionWorker, :perform do
  let(:content_id) { SecureRandom.uuid }
  let(:locale) { "en" }
  let(:document) { create(:document, content_id: content_id, locale: locale) }
  let(:live_edition) { create(:live_edition, document: document) }

  subject(:worker_perform) do
    described_class.new.perform(
      content_id: content_id,
      locale: locale,
      content_store: "Adapters::ContentStore",
    )
  end

  let(:edition_dependee) { double(:edition_dependent, call: []) }
  let(:dependencies) do
    [
      [content_id, "en"],
    ]
  end

  before do
    stub_request(:put, %r{.*content-store.*/content/.*})
    allow_any_instance_of(Queries::ContentDependencies).to receive(:call).and_return(dependencies)
  end

  it "finds the edition dependees" do
    expect(Queries::ContentDependencies).to receive(:new).with(
      content_id: content_id,
      locale: locale,
      content_stores: %w[live],
    ).and_return(edition_dependee)
    worker_perform
  end

  it "the dependees get queued in the content store worker" do
    expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
      "downstream_low",
      a_hash_including(
        :content_id,
        :locale,
        message_queue_event_type: "links",
        update_dependencies: false,
      ),
    )
    worker_perform
  end

  context "when orphaned content_ids are present" do
    let(:orphaned_link_content_id) { create(:live_edition).content_id }

    it "sends the content_ids downstream" do
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(content_id: content_id),
      )
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(content_id: orphaned_link_content_id),
      )

      described_class.new.perform(
        content_id: content_id,
        locale: locale,
        content_store: "Adapters::ContentStore",
        orphaned_content_ids: [orphaned_link_content_id],
      )
    end

    it "doesn't send the content_ids downstream if they don't support the locale" do
      expect(DownstreamLiveWorker).to_not receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(content_id: orphaned_link_content_id),
      )

      described_class.new.perform(
        content_id: content_id,
        locale: "fr",
        content_store: "Adapters::ContentStore",
        orphaned_content_ids: [orphaned_link_content_id],
      )
    end
  end

  context "with a draft version available" do
    let!(:draft_edition) do
      create(
        :draft_edition,
        document: document,
        user_facing_version: 2,
      )
    end

    it "doesn't send draft content to the live content store" do
      expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(
          content_id: content_id,
          locale: "en",
        ),
      )

      described_class.new.perform(
        content_id: "123",
        locale: "en",
        content_store: "Adapters::ContentStore",
      )
    end

    it "does send draft content to the draft content store" do
      expect(DownstreamDraftWorker).to receive(:perform_async_in_queue).with(
        anything,
        a_hash_including(
          content_id: content_id,
          locale: "en",
        ),
      )

      described_class.new.perform(
        content_id: "123",
        locale: "en",
        content_store: "Adapters::DraftContentStore",
      )
    end
  end

  context "when there are translations of an edition" do
    context "and locale is specified" do
      let(:dependencies) do
        [
          [content_id, "fr"],
          [content_id, "es"],
        ]
      end

      after do
        described_class.new.perform(
          content_id: content_id,
          locale: "en",
          content_store: "Adapters::ContentStore",
        )
      end

      it "downstreams all but the locale specified" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "fr"),
        )
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "es"),
        )
      end
    end

    context "but locale is not specified" do
      let(:dependencies) do
        [
          [content_id, "en"],
          [content_id, "fr"],
          [content_id, "es"],
        ]
      end

      after do
        described_class.new.perform(
          content_id: content_id,
          content_store: "Adapters::ContentStore",
          locale: "en",
        )
      end

      it "downstreams all but the locale specified" do
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "en"),
        )
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "fr"),
        )
        expect(DownstreamLiveWorker).to receive(:perform_async_in_queue).with(
          anything,
          a_hash_including(content_id: content_id, locale: "es"),
        )
      end
    end
  end

  context "with source information" do
    after do
      described_class.new.perform(
        content_id: content_id,
        content_store: "Adapters::ContentStore",
        locale: "en",
        source_command: "patch_link_set",
        source_document_type: "answer",
        source_fields: %w[description details.body],
      )
    end

    it "sends source stats to statsd" do
      expect(GovukStatsd).to receive(:increment)
        .with("dependency_resolution.source.command.patch_link_set")

      expect(GovukStatsd).to receive(:increment)
        .with("dependency_resolution.source.document_type.answer")

      expect(GovukStatsd).to receive(:increment)
        .with("dependency_resolution.source.field.description")

      expect(GovukStatsd).to receive(:increment)
        .with("dependency_resolution.source.field.details.body")
    end
  end
end
