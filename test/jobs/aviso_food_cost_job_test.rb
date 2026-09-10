require "test_helper"

class AvisoFoodCostJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    crear_usuario(email: "cocina@lasplendida.cl")
    @queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000,
                               cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    @plato = crear_plato(nombre: "Milanesa", precio_venta: 1000)
    agregar(@plato, @queso, 30, "g")   # 30 % sano
  end

  def subir_a(monto)
    crear_precio(@queso, precio: monto, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))
  end

  test "manda un correo a cada usuario cuando algun plato empeoro" do
    crear_usuario(email: "gerencia@lasplendida.cl")

    assert_emails 2 do
      AvisoFoodCostJob.perform_now(subir_a(14_000))   # 30 % -> 42 %
    end
  end

  test "no manda nada si no empeoro nadie" do
    assert_emails 0 do
      AvisoFoodCostJob.perform_now(subir_a(10_500))   # 30 % -> 31,5 %, sigue sano
    end
  end
end
