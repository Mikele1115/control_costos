class AvisoFoodCostJob < ApplicationJob
  queue_as :default

  def perform(precio)
    configuracion = Configuracion.actual

    # Con los avisos apagados o sin destinatario no hay nada que hacer,
    # y de paso nos ahorramos costear la carta entera.
    return unless configuracion.avisar?

    AvisosMailer.food_cost_alto(configuracion, precio).deliver_now
  end
end
