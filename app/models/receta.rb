class Receta < ApplicationRecord
  class NoDosificable < StandardError; end

  TIPOS = %w[plato preparacion].freeze
  FOOD_COST_OBJETIVO = 30 # % de referencia en gastronomia

  has_many :ingredientes, dependent: :destroy
  has_many :usos, as: :insumable, class_name: "Ingrediente",
                  dependent: :restrict_with_error

  validates :nombre, presence: true,
                     uniqueness: { case_sensitive: false }
  validates :tipo, inclusion: {
    in: TIPOS, message: "debe ser plato o preparacion"
  }
  validates :rendimiento_cantidad, numericality: { greater_than: 0 }, allow_nil: true
  validates :precio_venta, numericality: { greater_than_or_equal_to: 0 },
                           allow_nil: true

  validate :coherencia_segun_tipo

  scope :platos,        -> { where(tipo: "plato") }
  scope :preparaciones, -> { where(tipo: "preparacion") }

  def plato?       = tipo == "plato"
  def preparacion? = tipo == "preparacion"

  # --- Unidades -----------------------------------------------------

  # rinde 2000 "g" -> su unidad base es "g"; rinde 3 "l" -> "ml"
  def unidad_base
    return nil unless preparacion? && rendimiento_unidad.present?
    Unidad::EQUIVALENCIAS.dig(rendimiento_unidad.to_s.strip.downcase, 0)
  end

  # Unidades en las que se puede dosificar esta preparacion.
  # Insumo ya responde a esto: ahora ambos comparten tambien esta
  # parte de la interfaz, y el desplegable puede tratarlos igual.
  def unidades_permitidas
    return [] unless preparacion?
    Unidad.compatibles_con(unidad_base)
  end

  # --- Costeo -------------------------------------------------------

  # Un plato ES un plato: esto es lo que cuesta servirlo.
  # Una preparacion: lo que cuesta la tanda entera.
  def costo_total(fecha: Date.current)
    ingredientes.includes(:insumable)
                .map { |i| i.costo(fecha: fecha) }
                .sum(BigDecimal(0))
  end

  # Solo preparaciones: lo que cuesta 1 g / 1 ml / 1 unidad de esto
  def costo_por_unidad_base(fecha: Date.current)
    return nil unless preparacion?

    rendimiento_base = Unidad.convertir(
      rendimiento_cantidad, desde: rendimiento_unidad, hasta_base: unidad_base
    )
    costo_total(fecha: fecha) / rendimiento_base
  end

  # LA INTERFAZ COMUN CON Insumo: por esto un Ingrediente no necesita
  # saber si apunta a un insumo o a una preparacion.
  # Una receta no lleva merma propia: ya viene incluida en sus insumos.
  def costo_de(cantidad, unidad, fecha: Date.current)
    unless preparacion?
      raise NoDosificable, "#{nombre} es un plato: no se dosifica en otra receta"
    end

    Unidad.convertir(cantidad, desde: unidad, hasta_base: unidad_base) *
      costo_por_unidad_base(fecha: fecha)
  end

  # --- Indicadores de negocio ---------------------------------------

  # Que porcentaje del precio de venta se va en materia prima.
  # En gastronomia se busca entre 25% y 35%.
  def food_cost(fecha: Date.current)
    return nil unless plato? && precio_venta.to_f.positive?
    (costo_total(fecha: fecha) / precio_venta) * 100
  end

  def margen_bruto(fecha: Date.current)
    return nil unless plato? && precio_venta.present?
    precio_venta - costo_total(fecha: fecha)
  end

  # El calculo inverso: a que precio deberia venderse para alcanzar
  # el food cost objetivo.
  def precio_sugerido(objetivo: FOOD_COST_OBJETIVO, fecha: Date.current)
    return nil unless plato?
    costo_total(fecha: fecha) * 100 / BigDecimal(objetivo.to_s)
  end

  def costeable?(fecha: Date.current)
    costo_total(fecha: fecha)
    true
  rescue Insumo::SinPrecio
    false
  end

  # Detalle renglon a renglon, para mostrar en pantalla
  def desglose(fecha: Date.current)
    ingredientes.includes(:insumable).map do |i|
      {
        nombre:   i.nombre_insumable,
        tipo:     i.insumable_type,
        cantidad: i.cantidad,
        unidad:   i.unidad,
        costo:    i.costo(fecha: fecha)
      }
    end
  end

  # --- Integridad del grafo -----------------------------------------

  # Consulta la base y no la asociacion: un objeto con `ingredientes`
  # ya cargado devolveria una lista obsoleta y dejaria pasar ciclos.
  def depende_de?(objetivo, visitadas = Set.new)
    return false if id.nil? || objetivo&.id.nil?
    return false if visitadas.include?(id)
    visitadas << id

    sub_ids = Ingrediente.where(receta_id: id, insumable_type: "Receta")
                         .pluck(:insumable_id)
    return false if sub_ids.empty?
    return true  if sub_ids.include?(objetivo.id)

    Receta.where(id: sub_ids).any? { |sub| sub.depende_de?(objetivo, visitadas) }
  end

  private

  # Un plato no exige nada extra: la receta es el plato.
  # Una preparacion necesita rendimiento para poder dosificarse.
  def coherencia_segun_tipo
    return unless preparacion?

    if rendimiento_cantidad.blank?
      errors.add(:rendimiento_cantidad, "es obligatorio en una preparacion")
    end

    if rendimiento_unidad.blank?
      errors.add(:rendimiento_unidad, "es obligatorio en una preparacion")
    elsif unidad_base.nil?
      errors.add(:rendimiento_unidad,
        "no es una unidad valida (#{Unidad.todas.join(', ')})")
    end
  end
end
