class IngredientesController < ApplicationController
  before_action :set_receta

  def create
    @ingrediente = @receta.ingredientes.new(ingrediente_params)
    @ingrediente.insumable = insumable_elegido

    if @ingrediente.save
      redirect_to @receta, notice: "#{@ingrediente.nombre_insumable} agregado."
    else
      redirect_to @receta, alert: @ingrediente.errors.full_messages.to_sentence
    end
  end

  def destroy
    ingrediente = @receta.ingredientes.find(params[:id])
    nombre = ingrediente.nombre_insumable
    ingrediente.destroy
    redirect_to @receta, notice: "#{nombre} quitado de la receta."
  end

  private

  def set_receta
    @receta = Receta.find(params[:receta_id])
  end

  def ingrediente_params
    params.expect(ingrediente: %i[cantidad unidad])
  end

  # El desplegable manda "Insumo:12" o "Receta:5".
  #
  # constantize sobre datos del usuario seria una puerta abierta a
  # instanciar cualquier clase de la aplicacion: por eso se comprueba
  # contra la lista blanca ANTES de convertir.
  def insumable_elegido
    tipo, id = params.dig(:ingrediente, :insumable).to_s.split(":", 2)
    return nil unless Ingrediente::TIPOS_INSUMABLE.include?(tipo)

    tipo.constantize.find_by(id: id)
  end
end
