require "test_helper"

class ConfiguracionTest < ActiveSupport::TestCase
  test "actual devuelve siempre la misma fila" do
    primera = Configuracion.actual
    assert_equal primera.id, Configuracion.actual.id
    assert_equal 1, Configuracion.count
  end

  test "el umbral nace en 35" do
    assert_equal BigDecimal(35), Configuracion.actual.umbral_aviso
  end

  test "acepta cualquier porcentaje, con decimales" do
    configuracion = Configuracion.actual

    assert configuracion.update(umbral_aviso: 38.5)
    assert_equal BigDecimal("38.5"), configuracion.reload.umbral_aviso
  end

  test "rechaza un umbral fuera de rango" do
    configuracion = Configuracion.actual

    assert_not configuracion.update(umbral_aviso: 0), "0 % avisaria de todo"
    assert_includes configuracion.errors[:umbral_aviso], "debe estar entre 0,01 y 100"

    assert_not configuracion.update(umbral_aviso: 140), "sobre 100 % no significa nada"
    assert_not configuracion.update(umbral_aviso: -5)
  end

  test "la base tambien rechaza un umbral fuera de rango" do
    configuracion = Configuracion.actual

    assert_raises ActiveRecord::StatementInvalid do
      Configuracion.transaction(requires_new: true) do
        configuracion.update_column(:umbral_aviso, 250)
      end
    end
  end

  test "avisar? pide el interruptor encendido Y alguien activo en la lista" do
    configuracion = Configuracion.actual
    assert_not configuracion.avisar?, "recien creada no deberia avisar"

    destinatario = Destinatario.create!(correo: "duenio@lasplendida.cl")
    assert_not configuracion.avisar?, "con lista pero apagado tampoco"

    configuracion.update!(avisos_activos: true)
    assert configuracion.avisar?

    destinatario.update!(activo: false)
    assert_not configuracion.avisar?, "todos desactivados es como no tener a nadie"
  end
end
