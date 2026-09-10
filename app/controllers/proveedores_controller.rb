class ProveedoresController < ApplicationController
  before_action :set_proveedor, only: %i[show edit update destroy]

  def index
    @proveedores = Proveedor.ordenados.includes(:insumos)
    @sin_proveedor = Insumo.where(proveedor_id: nil).order(:nombre)
  end

  def show
    @insumos = @proveedor.insumos.includes(:precio_insumos).order(:nombre)
  end

  def new
    @proveedor = Proveedor.new
  end

  def edit
  end

  def create
    @proveedor = Proveedor.new(proveedor_params)

    if @proveedor.save
      redirect_to @proveedor, notice: "Proveedor creado. Ahora asignale sus insumos."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @proveedor.update(proveedor_params)
      redirect_to @proveedor, notice: "Proveedor actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    cantidad = @proveedor.cantidad_insumos
    @proveedor.destroy

    aviso = "Proveedor eliminado."
    aviso += " #{helpers.pluralize(cantidad, 'insumo')} quedaron sin proveedor." if cantidad.positive?

    redirect_to proveedores_path, notice: aviso
  end

  private

  def set_proveedor
    @proveedor = Proveedor.find(params[:id])
  end

  def proveedor_params
    params.expect(proveedor: %i[nombre contacto telefono])
  end
end
