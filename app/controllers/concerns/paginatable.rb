# frozen_string_literal: true

module Paginatable
  extend ActiveSupport::Concern

  # Paginate a collection and return pagination metadata
  # @param collection [ActiveRecord::Relation] The collection to paginate
  # @param default_per_page [Integer] Default items per page (default: 20)
  # @return [Hash] { collection: paginated_collection, pagination: metadata }
  def paginate_collection(collection, default_per_page: 20)
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : default_per_page

    # Cap per_page at 100 to prevent performance issues
    per_page = [ per_page, 100 ].min

    paginated = collection.paginate(page: page, per_page: per_page)

    {
      collection: paginated,
      pagination: pagination_metadata(paginated, page, per_page)
    }
  end

  private

  def pagination_metadata(collection, page, per_page)
    {
      current_page: page,
      per_page: per_page,
      total_entries: collection.total_entries,
      total_pages: collection.total_pages,
      next_page: collection.next_page,
      previous_page: collection.previous_page
    }
  end
end
