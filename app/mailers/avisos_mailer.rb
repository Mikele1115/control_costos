class AvisosMailer < ApplicationMailer
  default from: "avisos@lasplendida.cl"

  def food_cost_alto(usuario, precio)
    @usuario = usuario
    @precio  = precio
    @insumo  = precio.insumo
    @cruces  = CruceDeUmbral.new(precio).cruces
    @umbral  = Receta::UMBRAL_ALTO

    # Sin cruces no se llama a `mail`: ActionMailer devuelve un envio
    # vacio y no sale nada.
    return if @cruces.empty?

    mail to: usuario.email_address,
         subject: t("avisos.food_cost.asunto", count: @cruces.size)
  end
end
