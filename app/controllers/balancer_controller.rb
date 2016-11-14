class BalancerController < ApplicationController
  def resolve_host
    params.require(:ip)
    balancer = Balancer.new(
      ip: params[:ip],
      current_country: params[:current_country])
    render json: { host: balancer.resolve_host }
  end
end
