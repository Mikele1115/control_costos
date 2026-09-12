class RecetasController < ApplicationController
  before_action :set_receta, only: %i[show edit update destroy duplicar]

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

  def duplicar
    copia = @receta.duplicar
    redirect_to copia, notice: "Copia creada. Ajustá lo que necesites."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @receta, alert: "No se pudo duplicar: #{e.message}"
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
    params.expect(receta: %i[nombre tipo categoria precio_venta
                             rendimiento_cantidad rendimiento_unidad])
  end

  # Lo que se puede agregar a esta receta: todos los insumos, y las
  # preparaciones que no generarian un ciclo. El modelo las rechazaria
  # igual, pero una interfaz no deberia ofrecer opciones invalidas.
  #
  # Cada opcion viaja con sus unidades compatibles en un data attribute:
  # el navegador ya no necesita preguntar nada.
  def opciones_insumables
    insumos = Insumo.order(:nombre).map do |insumo|
      [ insumo.nombre, "Insumo:#{insumo.id}",
       { data: { unidades: unidades_json(insumo) } } ]
    end

    preparaciones = Receta.preparaciones.order(:nombre)
                          .reject { |prep| prep == @receta || prep.depende_de?(@receta) }
                          .map do |prep|
      [ prep.nombre, "Receta:#{prep.id}",
       { data: { unidades: unidades_json(prep) } } ]
    end

    [ [ "Insumos", insumos ], [ "Preparaciones", preparaciones ] ]
  end

  # {"g":"gramos","kg":"kilogramos"} — valor y etiqueta ya traducida,
  # para que el navegador no tenga que saber de idiomas.
  def unidades_json(objeto)
    objeto.unidades_permitidas
          .index_with { |unidad| I18n.t("costeo.unidades.#{unidad}") }
          .to_json
  end
end
