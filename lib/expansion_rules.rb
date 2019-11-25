module ExpansionRules
  extend self

  module RecurringLinks
    refine Symbol do
      def recurring
        [self]
      end
    end
  end

  using RecurringLinks

  def details_fields(*fields)
    fields.map { |field| [:details, field] }
  end

  MULTI_LEVEL_LINK_PATHS = [
    [:associated_taxons.recurring],
    [:child_taxons, :associated_taxons.recurring],
    [:child_taxons.recurring, :legacy_taxons],
    [:child_taxons.recurring],
    [:parent.recurring],
    [:parent_taxons.recurring],
    [:parent_taxons.recurring, :root_taxon],
    [:taxons, :root_taxon],
    [:taxons, :parent_taxons.recurring],
    [:taxons, :parent_taxons.recurring, :root_taxon],
    [:ordered_related_items, :mainstream_browse_pages, :parent.recurring],
    [:ordered_related_items_overrides, :taxons],
    [:facets, :facet_values, :facet_group],
    [:facet_group, :facets, :facet_values],
    [:role_appointments, :person],
    [:role_appointments, :role, :ordered_parent_organisations],
  ].freeze

  REVERSE_LINKS = {
    parent: :children,
    documents: :document_collections,
    working_groups: :policies,
    parent_taxons: :child_taxons,
    root_taxon: :level_one_taxons,
    pages_part_of_step_nav: :part_of_step_navs,
    pages_related_to_step_nav: :related_to_step_navs,
    legacy_taxons: :topic_taxonomy_taxons,
    pages_secondary_to_step_nav: :secondary_to_step_navs,
    person: :role_appointments,
    role: :role_appointments,
  }.freeze

  DEFAULT_FIELDS = [
    :analytics_identifier,
    :api_path,
    :base_path,
    :content_id,
    :document_type,
    :locale,
    :public_updated_at,
    :schema_name,
    :title,
    :withdrawn,
  ].freeze

  DRAFT_ONLY_FIELDS = %i[auth_bypass_ids].freeze

  DEFAULT_FIELDS_AND_DESCRIPTION = (DEFAULT_FIELDS + [:description]).freeze

  CONTACT_FIELDS = (DEFAULT_FIELDS + details_fields(:description, :title, :contact_form_links, :post_addresses, :email_addresses, :phone_numbers)).freeze
  GOVERNMENT_FIELDS = (%i[content_id title api_path base_path document_type] + details_fields(:start_date, :end_date, :current)).freeze
  ORGANISATION_FIELDS = (DEFAULT_FIELDS - [:public_updated_at] + details_fields(:logo, :brand, :default_news_image)).freeze
  TAXON_FIELDS = (DEFAULT_FIELDS + %i[description details phase]).freeze
  NEED_FIELDS = (DEFAULT_FIELDS + details_fields(:role, :goal, :benefit, :met_when, :justifications)).freeze
  FINDER_FIELDS = (DEFAULT_FIELDS + details_fields(:facets)).freeze
  PERSON_FIELDS = (DEFAULT_FIELDS + details_fields(:body)).freeze
  ROLE_FIELDS = (DEFAULT_FIELDS + details_fields(:body)).freeze
  ROLE_APPOINTMENT_FIELDS = (DEFAULT_FIELDS + details_fields(:started_on, :ended_on, :current, :person_appointment_order)).freeze
  STEP_BY_STEP_FIELDS = (DEFAULT_FIELDS + [%i[details step_by_step_nav title], %i[details step_by_step_nav steps]]).freeze
  STEP_BY_STEP_AUTH_BYPASS_FIELDS = (STEP_BY_STEP_FIELDS + %i[auth_bypass_ids]).freeze
  TRAVEL_ADVICE_FIELDS = (DEFAULT_FIELDS + details_fields(:country, :change_description)).freeze
  WORLD_LOCATION_FIELDS = [:content_id, :title, :schema_name, :locale, :analytics_identifier].freeze
  FACET_GROUP_FIELDS = (%i[content_id title locale schema_name] + details_fields(:name, :description)).freeze
  FACET_FIELDS = (
    %i[content_id title locale schema_name] + details_fields(
      :combine_mode,
      :display_as_result_metadata,
      :filterable,
      :filter_key,
      :key,
      :name,
      :preposition,
      :short_name,
      :type,
    )
  ).freeze
  FACET_VALUE_FIELDS = (%i[content_id title locale schema_name] + details_fields(:label, :value)).freeze

  CUSTOM_EXPANSION_FIELDS_FOR_ROLES = (
    %i(
      ambassador_role
      board_member_role
      chief_professional_officer_role
      chief_scientific_advisor_role
      chief_scientific_officer_role
      deputy_head_of_mission_role
      governor_role
      high_commissioner_role
      military_role
      ministerial_role
      special_representative_role
      traffic_commissioner_role
      worldwide_office_staff_role
    ).map do |document_type|
      { document_type: document_type, fields: ROLE_FIELDS }
    end
  ).freeze

  CUSTOM_EXPANSION_FIELDS = (
    [
      { document_type: :redirect,
        fields: [] },
      { document_type: :gone,
        fields: [] },
      { document_type: :contact,
        fields: CONTACT_FIELDS },
      { document_type: :topical_event,
        fields: DEFAULT_FIELDS },
      { document_type: :placeholder_topical_event,
        fields: DEFAULT_FIELDS },
      { document_type: :organisation,
        fields: ORGANISATION_FIELDS },
      { document_type: :placeholder_organisation,
        fields: ORGANISATION_FIELDS },
      { document_type: :taxon,
        fields: TAXON_FIELDS },
      { document_type: :need,
        fields: NEED_FIELDS },
      { document_type: :finder,
        link_type: :finder,
        fields: FINDER_FIELDS },
      { document_type: :mainstream_browse_page,
        fields: DEFAULT_FIELDS_AND_DESCRIPTION },
      { document_type: :person,
        link_type: :person,
        fields: PERSON_FIELDS },
      { document_type: :role_appointment,
        fields: ROLE_APPOINTMENT_FIELDS },
      { document_type: :service_manual_topic,
        fields: DEFAULT_FIELDS_AND_DESCRIPTION },
      { document_type: :step_by_step_nav,
        link_type: :part_of_step_navs,
        fields: STEP_BY_STEP_AUTH_BYPASS_FIELDS },
      { document_type: :step_by_step_nav,
        link_type: :related_to_step_navs,
        fields: STEP_BY_STEP_AUTH_BYPASS_FIELDS },
      { document_type: :step_by_step_nav,
        fields: STEP_BY_STEP_FIELDS },
      { document_type: :travel_advice,
        fields: TRAVEL_ADVICE_FIELDS },
      { document_type: :world_location,
        fields: WORLD_LOCATION_FIELDS },
      { document_type: :facet_group,
        fields: FACET_GROUP_FIELDS },
      { document_type: :facet,
        fields: FACET_FIELDS },
      { document_type: :facet_value,
        fields: FACET_VALUE_FIELDS },
      { document_type: :government,
        fields: GOVERNMENT_FIELDS },
    ] +
    CUSTOM_EXPANSION_FIELDS_FOR_ROLES
  ).freeze

  POSSIBLE_FIELDS_FOR_LINK_EXPANSION = DEFAULT_FIELDS +
    %i[details] +
    %i[id state phase description auth_bypass_ids unpublishings.type] -
    %i[api_path withdrawn]

  def reverse_links
    REVERSE_LINKS.values.uniq
  end

  def reverse_link_type(link_type)
    REVERSE_LINKS[link_type.to_sym]
  end

  def reverse_to_direct_link_type(link_type)
    REVERSE_LINKS
      .filter { |_, value| value == link_type.to_sym }
      .keys
  end

  def is_reverse_link_type?(link_type)
    reverse_to_direct_link_type(link_type).present?
  end

  def reverse_to_direct_link_types(link_types)
    return unless link_types

    link_types.flat_map { |type| reverse_to_direct_link_type(type) }.compact
  end

  def reverse_link_types_hash(link_types)
    link_types.each_with_object({}) do |(link_type, content_ids), memo|
      reversed = reverse_link_type(link_type)
      if reversed
        memo[reversed] ||= []
        memo[reversed] += content_ids
      end
    end
  end

  def link_expansion
    @link_expansion ||= ExpansionRules::LinkExpansion.new(self)
  end

  def dependency_resolution
    @dependency_resolution ||= ExpansionRules::DependencyResolution.new(self)
  end

  def expansion_fields(document_type, link_type: nil, draft: true)
    fields = if link_type
               expansion_fields_for_linked_document_type(document_type, link_type)
             else
               expansion_fields_for_document_type(document_type)
             end

    draft ? fields : fields - DRAFT_ONLY_FIELDS
  end

  def expansion_fields_for_document_type(document_type)
    matching_document_types = CUSTOM_EXPANSION_FIELDS.select do |item|
      item[:document_type] == document_type.to_sym
    end

    return DEFAULT_FIELDS unless matching_document_types.any?

    collated_fields = matching_document_types.flat_map { |item| item[:fields] }
    matches_any_link_type = matching_document_types.any? { |item| item[:link_type].nil? }

    collated_fields += DEFAULT_FIELDS unless matches_any_link_type
    collated_fields.uniq
  end

  def expansion_fields_for_linked_document_type(document_type, link_type)
    matching_link = CUSTOM_EXPANSION_FIELDS.find do |item|
      item[:document_type] == document_type.to_sym &&
        item[:link_type] == link_type.to_sym
    end
    return matching_link[:fields] if matching_link

    matching_document_type = CUSTOM_EXPANSION_FIELDS.find do |item|
      item[:document_type] == document_type.to_sym && item[:link_type].nil?
    end
    return matching_document_type[:fields] if matching_document_type

    DEFAULT_FIELDS
  end

  module HashWithDigSet
    refine Hash do
      def dig_set(keys, value)
        keys.each_with_index.inject(self) do |hash, (key, index)|
          if keys.count - 1 == index
            hash[key] = value
          else
            hash[key] ||= {}
          end
        end
      end
    end
  end

  using HashWithDigSet

  def expand_fields(edition_hash, link_type: nil, draft: true)
    fields = expansion_fields(edition_hash[:document_type],
                              link_type: link_type,
                              draft: draft)

    fields.each_with_object({}) do |field, expanded|
      field = Array(field)
      # equivelant to: expanded.dig(*field) = edition_hash.dig(*field)
      expanded.dig_set(field, edition_hash.dig(*field))
    end
  end

  def next_allowed_direct_link_types(next_allowed_link_types, reverse_to_direct: false)
    next_allowed_link_types.each_with_object({}) do |(link_type, allowed_links), memo|
      next if allowed_links.empty?

      links = allowed_links.reject { |link| is_reverse_link_type?(link) }
      next if links.empty?

      if reverse_to_direct && (reverse_link_types = reverse_to_direct_link_type(link_type)).present?
        link_types = reverse_link_types
      else
        link_types = [link_type]
      end

      link_types.each { |type| memo[type] = links }
    end
  end

  def next_allowed_reverse_link_types(next_allowed_link_types, reverse_to_direct: false)
    next_allowed_link_types.each_with_object({}) do |(link_type, allowed_links), memo|
      next if allowed_links.empty?

      links = allowed_links.select { |link| is_reverse_link_type?(link) }
      links = reverse_to_direct_link_types(links) if reverse_to_direct
      next if links.empty?

      if reverse_to_direct && (reverse_link_types = reverse_to_direct_link_type(link_type)).present?
        link_types = reverse_link_types
      else
        link_types = [link_type]
      end

      link_types.each { |type| memo[type] = links }
    end
  end
end
