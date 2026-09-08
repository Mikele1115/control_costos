require "test_helper"

class UnidadTest < ActiveSupport::TestCase
  test "convierte dentro de la misma magnitud" do
    assert_equal BigDecimal(2000), Unidad.convertir(2, desde: "kg", hasta_base: "g")
    assert_equal BigDecimal(1500), Unidad.convertir("1.5", desde: "l", hasta_base: "ml")
    assert_equal BigDecimal(12),   Unidad.convertir(1, desde: "docena", hasta_base: "unidad")
  end

  test "normaliza mayusculas y espacios sobrantes" do
    assert_equal BigDecimal(1000), Unidad.convertir(1, desde: "  KG  ", hasta_base: "g")
  end

  test "se niega a cruzar magnitudes distintas" do
    error = assert_raises(Unidad::Incompatible) do
      Unidad.convertir(2, desde: "l", hasta_base: "g")
    end
    assert_match(/magnitudes distintas/, error.message)
  end

  test "rechaza unidades que no conoce" do
    assert_raises(Unidad::Desconocida) do
      Unidad.convertir(1, desde: "cucharada", hasta_base: "g")
    end
  end

  test "no acumula error decimal al sumar" do
    suma = 10.times.sum { Unidad.convertir("0.1", desde: "kg", hasta_base: "g") }
    assert_equal BigDecimal(1000), suma
  end

  test "sabe que unidades son compatibles con cada base" do
    assert_equal %w[g kg],          Unidad.compatibles_con("g")
    assert_equal %w[ml l],          Unidad.compatibles_con("ml")
    assert_equal %w[unidad docena], Unidad.compatibles_con("unidad")
  end
end
