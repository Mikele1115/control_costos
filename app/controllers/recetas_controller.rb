class RecetasController < ApplicationController
  before_action :set_receta, only: %i[show edit update destroy]

  def index
    @fecha   = fecha_solicitada
    @recetas = Receta.order(:tipo, :nombre)
  end

  def show
    @fecha        = fecha_solicitada
    @ingredientes = @receta.ingredientes.includes(:insumable)
    @costeable    = @receta.costeable?(fecha: @fecha)
    @ingrediente  = @receta.ingredientes.new
    @opciones     = opciones_insumables
  end

  def new
    @receta = Receta.new(tipo: "plato")
  end

  def edit
  end

  def create
    @receta = Receta.new(receta_params)

    if @receta.save
      redirect_to @receta, notice: "Receta creada. Ahora agregá sus ingredientes."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @receta.update(receta_params)
      redirect_to @receta, notice: "Receta actualizada."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @receta.destroy
      redirect_to recetas_path, notice: "Receta eliminada."
    else
      redirect_to @receta, alert: @receta.errors.full_messages.to_sentence
    end
  end

  private

  def set_receta
    @receta = Receta.find(params[:id])
  end

  def receta_params
    params.expect(receta: %i[nombre tipo precio_venta
                             rendimiento_cantidad rendimiento_unidad])
  end

  # Lo que se puede agregar a esta receta: todos los insumos, y las
  # preparaciones que no generarian un ciclo. El modelo las rechazaria
  # igual, pero una interfaz no deberia ofrecer opciones invalidas.
  def opciones_insumables
    insumos = Insumo.order(:nombre).map { |i| [i.nombre, "Insumo:#{i.id}"] }

    preparaciones = Receta.preparaciones.order(:nombre)
                          .reject { |p| p == @receta || p.depende_de?(@receta) }
                          .map { |p| [p.nombre, "Receta:#{p.id}"] }

    [["Insumos", insumos], ["Preparaciones", preparaciones]]
  end
end
