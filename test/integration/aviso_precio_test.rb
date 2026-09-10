require "test_helper"

class AvisoPrecioTest < ActionDispatch::IntegrationTest
  test "cargar un precio encola el aviso" do
    insumo = crear_insumo(nombre: "Muzzarella")

    assert_enqueued_with(job: AvisoFoodCostJob) do
      post insumo_precio_insumos_path(insumo), params: {
        precio_insumo: { precio_compra: 10_000, cantidad_compra: 1,
                         unidad_compra: "kg", vigente_desde: Date.new(2026, 6, 1) }
      }
    end
    assert_redirected_to insumo_path(insumo)
  end

  test "un precio invalido no encola nada" do
    insumo = crear_insumo(nombre: "Muzzarella")

    assert_no_enqueued_jobs only: AvisoFoodCostJob do
      post insumo_precio_insumos_path(insumo), params: {
        precio_insumo: { precio_compra: 100, cantidad_compra: 0,
                         unidad_compra: "kg", vigente_desde: Date.new(2026, 6, 1) }
      }
    end
    assert_response 422
  end
end
