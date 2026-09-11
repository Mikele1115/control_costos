require "test_helper"

class DestinatariosTest < ActionDispatch::IntegrationTest
  test "agregar un correo a la lista" do
    post destinatarios_path, params: { destinatario: { correo: "  CHEF@LaSplendida.CL " } }

    assert_equal ["chef@lasplendida.cl"], Destinatario.correos_activos
    assert_redirected_to edit_configuracion_path
  end

  test "un correo repetido se rechaza sin perder la pantalla" do
    Destinatario.create!(correo: "chef@lasplendida.cl")

    post destinatarios_path, params: { destinatario: { correo: "CHEF@lasplendida.cl" } }

    assert_response :unprocessable_entity
    assert_equal 1, Destinatario.count
    assert_select "li", text: /ya está en la lista/
    # Se vuelve a dibujar la pantalla de ajustes entera, no solo el error.
    assert_select "input[type=number][name=?]", "configuracion[umbral_aviso]"
  end

  test "un correo invalido se rechaza" do
    post destinatarios_path, params: { destinatario: { correo: "el chef" } }

    assert_response :unprocessable_entity
    assert_equal 0, Destinatario.count
    assert_select "li", text: /no parece un correo/
  end

  test "desactivar deja el correo en la lista como registro" do
    destinatario = Destinatario.create!(correo: "exchef@lasplendida.cl")

    patch destinatario_path(destinatario)

    assert_not destinatario.reload.activo?
    assert_equal 1, Destinatario.count, "sigue estando, solo que apagado"
    assert_empty Destinatario.correos_activos
  end

  test "volver a activar" do
    destinatario = Destinatario.create!(correo: "chef@lasplendida.cl", activo: false)

    patch destinatario_path(destinatario)

    assert destinatario.reload.activo?
    assert_equal ["chef@lasplendida.cl"], Destinatario.correos_activos
  end

  test "quitar lo borra de verdad" do
    destinatario = Destinatario.create!(correo: "chef@lasplendida.cl")

    delete destinatario_path(destinatario)

    assert_equal 0, Destinatario.count
    assert_redirected_to edit_configuracion_path
  end

  test "pide sesion" do
    delete session_path

    post destinatarios_path, params: { destinatario: { correo: "colado@lasplendida.cl" } }

    assert_redirected_to new_session_path
    assert_equal 0, Destinatario.count
  end
end
