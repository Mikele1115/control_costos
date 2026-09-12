require "test_helper"

class AvisoFoodCostJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @queso = insumo_con_precio(nombre: "Muzzarella", precio: 10_000,
                               cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    @plato = crear_plato(nombre: "Milanesa", precio_venta: 1000)
    agregar(@plato, @queso, 30, "g")   # 30 % de food cost
  end

  def subir_a(monto)
    crear_precio(@queso, precio: monto, cantidad: 1, unidad: "kg", desde: Date.new(2026, 6, 1))
  end

  test "manda un correo a toda la lista activa" do
    configurar_avisos(correo: "duenio@lasplendida.cl")
    Destinatario.create!(correo: "chef@lasplendida.cl")

    assert_emails 1 do
      AvisoFoodCostJob.perform_now(subir_a(14_000))   # 30 % -> 42 %
    end
    assert_equal [ "chef@lasplendida.cl", "duenio@lasplendida.cl" ],
                 ActionMailer::Base.deliveries.last.to
  end

  test "no manda nada con los avisos apagados" do
    Destinatario.create!(correo: "duenio@lasplendida.cl")

    assert_emails 0 do
      AvisoFoodCostJob.perform_now(subir_a(14_000))
    end
  end

  test "no manda nada si la lista esta vacia" do
    Configuracion.actual.update!(avisos_activos: true)

    assert_emails 0 do
      AvisoFoodCostJob.perform_now(subir_a(14_000))
    end
  end

  test "no manda nada si todos estan desactivados" do
    Configuracion.actual.update!(avisos_activos: true)
    Destinatario.create!(correo: "duenio@lasplendida.cl", activo: false)

    assert_emails 0 do
      AvisoFoodCostJob.perform_now(subir_a(14_000))
    end
  end

  test "no manda nada si no empeoro nadie" do
    configurar_avisos

    assert_emails 0 do
      AvisoFoodCostJob.perform_now(subir_a(10_500))   # 30 % -> 31,5 %
    end
  end
end
