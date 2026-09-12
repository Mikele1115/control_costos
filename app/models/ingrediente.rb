class Ingrediente < ApplicationRecord
  TIPOS_INSUMABLE = %w[Insumo Receta].freeze

  belongs_to :receta
  belongs_to :insumable, polymorphic: true

  validates :cantidad, numericality: { greater_than: 0 }
  validates :unidad,   presence: true
  validates :insumable_type, inclusion: { in: TIPOS_INSUMABLE }
  validates :insumable_id, uniqueness: {
    scope: [ :receta_id, :insumable_type ],
    message: "ya esta en esta receta"
  }

  validate :insumable_debe_ser_costeable
  validate :unidad_debe_ser_compatible
  validate :no_debe_generar_ciclo

  # El corazon del sistema. Sin un solo `if`: tanto Insumo como Receta
  # saben responder `costo_de`, cada uno a su manera.
  def costo(fecha: Date.current)
    insumable.costo_de(cantidad, unidad, fecha: fecha)
  end

  def nombre_insumable = insumable&.nombre

  def unidad_base_del_insumable
    insumable.respond_to?(:unidad_base) ? insumable.unidad_base : nil
  end

  private

  def insumable_debe_ser_costeable
    return if insumable.blank?
    return unless insumable.is_a?(Receta) && insumable.plato?

    errors.add(:insumable,
      "un plato no puede usarse como ingrediente: convertilo en preparacion")
  end

  def unidad_debe_ser_compatible
    base = unidad_base_del_insumable
    return if insumable.blank? || unidad.blank? || base.blank?

    Unidad.convertir(1, desde: unidad, hasta_base: base)
  rescue Unidad::Desconocida, Unidad::Incompatible => e
    errors.add(:unidad, e.message)
  end

  def no_debe_generar_ciclo
    return unless insumable.is_a?(Receta) && receta.present?

    if insumable == receta
      errors.add(:insumable, "una receta no puede contenerse a si misma")
    elsif insumable.depende_de?(receta)
      errors.add(:insumable,
        "generaria un ciclo: #{insumable.nombre} ya depende de #{receta.nombre}")
    end
  end
end
