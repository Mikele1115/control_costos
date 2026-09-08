# Las equivalencias entre unidades son constantes fisicas, no datos
# de negocio: un kilo son mil gramos hoy y siempre. Por eso viven en
# el codigo y no en la base de datos.
class Unidad
  class Desconocida  < StandardError; end
  class Incompatible < StandardError; end

  # unidad => [unidad base a la que pertenece, cuantas equivale 1]
  EQUIVALENCIAS = {
    "g"      => ["g",      1],
    "kg"     => ["g",      1000],
    "ml"     => ["ml",     1],
    "l"      => ["ml",     1000],
    "unidad" => ["unidad", 1],
    "docena" => ["unidad", 12]
  }.freeze

  def self.todas
    EQUIVALENCIAS.keys
  end

  # Unidades que se pueden usar con un insumo cuya base es, p.ej., "g"
  def self.compatibles_con(unidad_base)
    EQUIVALENCIAS.select { |_, (base, _)| base == unidad_base.to_s }.keys
  end

  # Convierte una cantidad a la unidad base indicada.
  # Se niega a adivinar entre magnitudes distintas (peso vs volumen).
  def self.convertir(cantidad, desde:, hasta_base:)
    clave = desde.to_s.strip.downcase
    definicion = EQUIVALENCIAS[clave]

    if definicion.nil?
      raise Desconocida,
        "Unidad desconocida: #{desde.inspect}. Validas: #{todas.join(', ')}"
    end

    base, factor = definicion

    unless base == hasta_base.to_s
      raise Incompatible,
        "No se puede convertir #{clave} (#{base}) a #{hasta_base}: " \
        "son magnitudes distintas y la densidad varia segun el insumo"
    end

    BigDecimal(cantidad.to_s) * factor
  end
end
