class DependencyResolution::LinkReference
  def links_by_link_type(
    content_id:,
    link_types_path: [],
    parent_content_ids: []
  )
    if link_types_path.empty?
      root_links(content_id)
    else
      descendant_links(content_id, link_types_path, parent_content_ids)
    end
  end

  def edition_links_by_link_type(
    content_id:,
    locale:,
    with_drafts:,
    link_types_path: []
  )
    return {} unless link_types_path.empty?

    edition_links(content_id,
      locale: locale,
      with_drafts: with_drafts
    )
  end

  def valid_link_node?(node)
    return true if node.link_types_path.length == 1
    return true if node.links.present?

    rules.valid_dependency_resolution_link_types_path?(node.link_types_path)
  end

private

  def root_links(content_id)
    direct = direct_links(content_id)
    reverse = reverse_links(content_id,
      allowed_reverse_link_types: rules.root_reverse_links,
    )
    reverse.merge(direct)
  end

  def descendant_links(content_id, link_types_path, parent_content_ids)
    descendant_link_types = rules.next_dependency_resolution_link_types(link_types_path)

    return {} if descendant_link_types.empty?

    reverse_types, direct_types = descendant_link_types.partition do |link_type|
      rules.is_reverse_link_type?(link_type)
    end

    direct = direct_links(content_id,
      allowed_link_types: direct_types,
      parent_content_ids: parent_content_ids,
    )

    reverse = reverse_links(content_id,
      allowed_reverse_link_types: reverse_types,
      parent_content_ids: parent_content_ids,
    )
    reverse.merge(direct)
  end

  def direct_links(content_id,
    allowed_link_types: nil,
    parent_content_ids: []
  )
    Queries::LinksTo.(content_id,
      allowed_link_types: allowed_link_types,
      parent_content_ids: parent_content_ids
    )
  end

  def reverse_links(content_id,
    allowed_reverse_link_types: nil,
    parent_content_ids: []
  )
    links = Queries::LinksFrom.(content_id,
      allowed_link_types: rules.un_reverse_link_types(allowed_reverse_link_types),
      parent_content_ids: parent_content_ids
    )

    rules.reverse_link_types_hash(links)
  end

  def edition_links(content_id, locale: nil, with_drafts:)
    from_links = Queries::EditionLinksFrom.(content_id,
      locale: locale,
      with_drafts: with_drafts,
      allowed_link_types: rules.un_reverse_link_types(rules.root_reverse_links),
    )
    from_links = rules.reverse_link_types_hash(from_links)

    to_links = Queries::EditionLinksTo.(content_id,
      locale: locale,
      with_drafts: with_drafts,
      allowed_link_types: nil,
    )

    to_links.merge(from_links)
  end

  def rules
    LinkExpansion::Rules
  end
end
