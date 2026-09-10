class Insumo < ApplicationRecord
  class SinPrecio < StandardError; end

  UNIDADES_BASE = %w[g ml unidad].freeze

  belongs_to :proveedor, optional: true

  has_many :precio_insumos, dependent: :restrict_with_error

  validates :nombre, presence: true,
                     uniqueness: { case_sensitive: false }

  validates :unidad_base, inclusion: {
    in: UNIDADES_BASE,
    message: "debe ser g, ml o unidad"
  }

  validates :merma_porcentaje, numericality: {
    greater_than_or_equal_to: 0,
    less_than: 100,
    message: "debe estar entre 0 y 99,99"
  }

  # --- Precios ------------------------------------------------------

  def precio_vigente(fecha = Date.current)
    precio_insumos.vigentes_al(fecha).first
  end

  # Costo de UNA unidad base (1 g, 1 ml o 1 unidad) en esa fecha
  def costo_unitario(fecha = Date.current)
    precio_vigente(fecha)&.costo_por_unidad_base
  end

  def con_precio?(fecha = Date.current)
    costo_unitario(fecha).present?
  end

  # --- Costeo -------------------------------------------------------

  # Lo que cuesta usar `cantidad` `unidad` de este insumo en una receta,
  # con la merma ya compensada.
  def costo_de(cantidad, unidad, fecha: Date.current)
    unitario = costo_unitario(fecha)
    if unitario.nil?
      raise SinPrecio, "#{nombre} no tiene precio cargado al #{fecha}"
    end

    convertir_a_base(cantidad, unidad) * unitario * factor_merma
  end

  # --- Unidades y merma ---------------------------------------------

  # Cuanto hay que COMPRAR para obtener 1 unidad utilizable.
  # Merma 20% => de cada 100 g comprados solo sirven 80 g,
  # asi que para usar 1 g hay que comprar 100/80 = 1,25 g.
  def factor_merma
    BigDecimal(100) / (BigDecimal(100) - merma_porcentaje)
  end

  def unidades_permitidas
    Unidad.compatibles_con(unidad_base)
  end

  def convertir_a_base(cantidad, unidad)
    Unidad.convertir(cantidad, desde: unidad, hasta_base: unidad_base)
  end
end
