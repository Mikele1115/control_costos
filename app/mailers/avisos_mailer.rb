class AvisosMailer < ApplicationMailer
  default from: "avisos@lasplendida.cl"

  def food_cost_alto(configuracion, precio)
    @configuracion = configuracion
    @precio        = precio
    @insumo        = precio.insumo
    @cruces        = CruceDeUmbral.new(precio, umbral: configuracion.umbral_aviso).cruces

    destinatarios = Destinatario.correos_activos

    # Sin cruces o sin nadie a quien escribirle no se llama a `mail`:
    # ActionMailer devuelve un envio vacio y no sale nada.
    return if @cruces.empty? || destinatarios.empty?

    mail to: destinatarios,
         subject: t("avisos.food_cost.asunto", count: @cruces.size)
  end
end
