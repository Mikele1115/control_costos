class InsumosController < ApplicationController
  before_action :set_insumo, only: %i[show edit update destroy]

  def index
    @insumos = Insumo.includes(:precio_insumos).order(:nombre)
  end

  def show
    @precios = @insumo.precio_insumos.order(vigente_desde: :desc)
  end

  def new
    @insumo = Insumo.new
  end

  def edit
  end

  def create
    @insumo = Insumo.new(insumo_params)

    if @insumo.save
      redirect_to @insumo, notice: "Insumo creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @insumo.update(insumo_params)
      redirect_to @insumo, notice: "Insumo actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @insumo.destroy
      redirect_to insumos_path, notice: "Insumo eliminado."
    else
      # dependent: :restrict_with_error dejo el motivo en los errores
      redirect_to @insumo, alert: @insumo.errors.full_messages.to_sentence
    end
  end

  private

  def set_insumo
    @insumo = Insumo.find(params[:id])
  end

  # Parametros fuertes: solo estos tres campos pueden llegar del
  # formulario. Sin esto, cualquiera podria enviar campos que no
  # deberia poder tocar.
  def insumo_params
    params.expect(insumo: %i[nombre unidad_base merma_porcentaje])
  end
end
