class PrecioInsumosController < ApplicationController
  before_action :set_insumo

  def new
    # Valores por defecto sensatos: hoy, y la unidad en que se mide.
    @precio = @insumo.precio_insumos.new(
      vigente_desde: Date.current,
      unidad_compra: @insumo.unidad_base
    )
  end

  def create
    @precio = @insumo.precio_insumos.new(precio_params)

    if @precio.save
      # En segundo plano: comparar el antes y el despues de todos
      # los platos lleva su tiempo y guardar un precio tiene que
      # seguir siendo instantaneo.
      AvisoFoodCostJob.perform_later(@precio)

      redirect_to @insumo,
        notice: "Precio cargado: #{helpers.moneda(@precio.costo_por_unidad_base)} " \
                "por #{@insumo.unidad_base}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @insumo.precio_insumos.find(params[:id]).destroy
    redirect_to @insumo, notice: "Precio eliminado."
  end

  private

  def set_insumo
    @insumo = Insumo.find(params[:insumo_id])
  end

  def precio_params
    params.expect(precio_insumo: %i[precio_compra cantidad_compra
                                    unidad_compra vigente_desde])
  end
end
