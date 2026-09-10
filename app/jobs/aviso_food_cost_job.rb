class AvisoFoodCostJob < ApplicationJob
  queue_as :default

  def perform(precio)
    return unless CruceDeUmbral.new(precio).alguno?

    User.find_each do |usuario|
      AvisosMailer.food_cost_alto(usuario, precio).deliver_now
    end
  end
end
