require "test_helper"

# Cuantas preguntas le hace cada pantalla a PostgreSQL.
#
# No mide velocidad: en local la base esta al lado y el trabajo no se
# nota. Mide CANTIDAD, por dos motivos distintos:
#
#   - las consultas reales pagan un viaje de red en un servidor de
#     verdad, donde la base esta en otra maquina;
#   - las cacheadas no viajan, pero Rails igual arma el SQL y vuelve a
#     construir los objetos, que es trabajo de CPU.
#
# Los presupuestos son holgados a proposito: no vigilan el numero
# exacto, avisan si algo vuelve a dispararse. Antes de memoizar
# Receta#costo_total el panel hacia 518.
class ConsultasTest < ActionDispatch::IntegrationTest
  setup do
    # Sin azar: si los datos cambian entre corridas, los numeros no se
    # pueden comparar.
    @insumos = 20.times.map do |i|
      insumo_con_precio(nombre: "Insumo #{i}", precio: 1000 + i * 100,
                        cantidad: 1, unidad: "kg", desde: Date.new(2026, 1, 1))
    end

    @preparaciones = 3.times.map do |i|
      preparacion = crear_preparacion(nombre: "Preparacion #{i}", rinde: 1000, unidad: "g")
      @insumos[(i * 4), 4].each { |insumo| agregar(preparacion, insumo, 100, "g") }
      preparacion
    end

    # Los tres primeros platos llevan una sub-receta: ahi es donde el
    # costeo se vuelve recursivo y las consultas se multiplican.
    @platos = 6.times.map do |i|
      plato = crear_plato(nombre: "Plato #{i}", precio_venta: 5000 + i * 500)
      @insumos[i, 4].each { |insumo| agregar(plato, insumo, 50, "g") }
      agregar(plato, @preparaciones[i % 3], 100, "g") if i < 3
      plato
    end
  end

  def contar_consultas
    total = 0
    suscriptor = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, datos|
      total += 1 unless %w[SCHEMA TRANSACTION].include?(datos[:name])
    end
    yield
    total
  ensure
    ActiveSupport::Notifications.unsubscribe(suscriptor)
  end

  def assert_consultas_bajo(presupuesto, pantalla)
    consultas = contar_consultas { yield }

    assert_response :success
    assert_operator consultas, :<=, presupuesto,
                    "#{pantalla} hizo #{consultas} consultas, mas del presupuesto de #{presupuesto}"
  end

  test "el panel se mantiene bajo presupuesto" do
    assert_consultas_bajo(120, "El panel") { get root_path }
  end

  test "el comparativo de margenes se mantiene bajo presupuesto" do
    assert_consultas_bajo(100, "Margenes") { get margenes_path }
  end

  test "el listado de recetas se mantiene bajo presupuesto" do
    assert_consultas_bajo(120, "Recetas") { get recetas_path }
  end

  test "el listado de insumos se mantiene bajo presupuesto" do
    assert_consultas_bajo(40, "Insumos") { get insumos_path }
  end

  test "la ficha de un plato se mantiene bajo presupuesto" do
    assert_consultas_bajo(60, "La ficha del plato") { get receta_path(@platos.first) }
  end
end
