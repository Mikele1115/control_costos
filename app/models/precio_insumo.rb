class PrecioInsumo < ApplicationRecord
  belongs_to :insumo

  validates :precio_compra,   numericality: { greater_than_or_equal_to: 0 }
  validates :cantidad_compra, numericality: { greater_than: 0 }
  validates :unidad_compra,   presence: true
  validates :vigente_desde,   presence: true
  validates :vigente_desde, uniqueness: {
    scope: :insumo_id,
    message: "ya tiene un precio cargado para esa fecha"
  }

  validate :unidad_compra_debe_ser_compatible
  before_validation :calcular_costo_por_unidad_base

  # Precios que ya estaban vigentes en una fecha, del mas nuevo al mas viejo
  scope :vigentes_al, ->(fecha) {
    where(vigente_desde: ..fecha).order(vigente_desde: :desc)
  }

  # "$30.000 por 25 kg" -> "1,20 $/g"
  def descripcion_compra
    "#{precio_compra.to_s('F')} por #{cantidad_compra.to_s('F')} #{unidad_compra}"
  end

  private

  def calcular_costo_por_unidad_base
    return if insumo.blank? || precio_compra.blank? ||
              cantidad_compra.blank? || unidad_compra.blank?

    cantidad_base = Unidad.convertir(
      cantidad_compra, desde: unidad_compra, hasta_base: insumo.unidad_base
    )
    self.costo_por_unidad_base = precio_compra / cantidad_base
  rescue Unidad::Desconocida, Unidad::Incompatible
    # El error lo reporta la validacion de abajo con un mensaje legible
    self.costo_por_unidad_base = nil
  end

  def unidad_compra_debe_ser_compatible
    return if insumo.blank? || unidad_compra.blank?

    Unidad.convertir(1, desde: unidad_compra, hasta_base: insumo.unidad_base)
  rescue Unidad::Desconocida, Unidad::Incompatible => e
    errors.add(:unidad_compra, e.message)
  end
end
