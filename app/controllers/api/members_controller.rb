class Api::MembersController < APIController

  def index
    search = User.ransack(search_params)
    render json: search.results, each_serializer: MembershipSerializer::MemberSerializer
  end

  def index_params
    # filter out members, by requiring the organization_id
  end

  private

  def search_params
    params[:q][:confirmed_at_not_null] = true

    params[:q]
  end

end
