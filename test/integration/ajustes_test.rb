require "test_helper"

class AjustesTest < ActionDispatch::IntegrationTest
  test "la pantalla muestra el umbral, el interruptor y el alta de correos" do
    get edit_configuracion_path

    assert_response :success
    assert_select "input[type=number][name=?]", "configuracion[umbral_aviso]"
    assert_select "input[type=checkbox][name=?]", "configuracion[avisos_activos]"
    assert_select "input[name=?]", "destinatario[correo]"
  end

  test "guarda umbral e interruptor" do
    Destinatario.create!(correo: "duenio@lasplendida.cl")

    patch configuracion_path, params: { configuracion: {
      avisos_activos: "1", umbral_aviso: "42.5"
    } }

    configuracion = Configuracion.actual
    assert_equal BigDecimal("42.5"), configuracion.umbral_aviso
    assert configuracion.avisos_activos?
    assert_redirected_to edit_configuracion_path
  end

  test "un umbral imposible se rechaza con mensaje y no se guarda" do
    patch configuracion_path, params: { configuracion: { umbral_aviso: "0" } }

    assert_response :unprocessable_entity
    assert_equal BigDecimal(35), Configuracion.actual.umbral_aviso
    assert_select "li", text: /debe estar entre/
  end

  test "avisa que no hay nadie en la lista al encender los avisos" do
    patch configuracion_path, params: { configuracion: { avisos_activos: "1" } }

    assert_equal "Ajustes guardados, pero no hay nadie en la lista.", flash[:notice]
    assert Configuracion.actual.avisos_activos?, "el interruptor se guarda igual"
  end

  test "sigue habiendo una sola fila despues de guardar dos veces" do
    patch configuracion_path, params: { configuracion: { umbral_aviso: "40" } }
    patch configuracion_path, params: { configuracion: { umbral_aviso: "45" } }

    assert_equal 1, Configuracion.count
    assert_equal BigDecimal(45), Configuracion.actual.umbral_aviso
  end

  test "pide sesion" do
    delete session_path
    get edit_configuracion_path

    assert_redirected_to new_session_path
  end
end
