require "test_helper"

class DemoLoginTest < ActionDispatch::IntegrationTest
  setup { sign_out }

  test "sin DEMO no se muestran credenciales" do
    get new_session_path
    assert_response :success
    assert_not_includes response.body, "demo@lasplendida.cl"
  end

  test "con DEMO se anuncian las credenciales en el login" do
    ENV["DEMO"] = "1"
    get new_session_path
    assert_includes response.body, "Esto es una demostración"
    assert_includes response.body, "demo@lasplendida.cl"
    assert_includes response.body, "demo1234"
  ensure
    ENV.delete("DEMO")
  end

  test "el usuario de la demostracion puede entrar" do
    usuario = crear_usuario(email: "demo@lasplendida.cl", password: "demo1234")

    post session_path, params: {
      email_address: "demo@lasplendida.cl", password: "demo1234"
    }
    assert_redirected_to root_path

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Panel de costos"
  end
end
