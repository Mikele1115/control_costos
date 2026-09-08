ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Constructores de datos de prueba.
#
# No usamos fixtures: se insertan con SQL crudo, saltandose validaciones
# y callbacks. En este dominio eso significaria escribir a mano valores
# que el sistema deriva (como costo_por_unidad_base), y acabariamos
# comprobando nuestra propia aritmetica en vez de la del codigo.
module Constructores
  def crear_insumo(nombre: nil, unidad_base: "g", merma: 0)
    Insumo.create!(
      nombre: nombre || "Insumo #{SecureRandom.hex(4)}",
      unidad_base: unidad_base,
      merma_porcentaje: merma
    )
  end

  def crear_precio(insumo, precio:, cantidad:, unidad:, desde: Date.new(2026, 1, 1))
    PrecioInsumo.create!(
      insumo: insumo,
      precio_compra: precio,
      cantidad_compra: cantidad,
      unidad_compra: unidad,
      vigente_desde: desde
    )
  end

  def insumo_con_precio(precio:, cantidad:, unidad:, nombre: nil,
                        unidad_base: "g", merma: 0, desde: Date.new(2026, 1, 1))
    insumo = crear_insumo(nombre: nombre, unidad_base: unidad_base, merma: merma)
    crear_precio(insumo, precio: precio, cantidad: cantidad, unidad: unidad, desde: desde)
    insumo
  end

  def crear_plato(nombre: nil, porciones: 4, precio_venta: nil)
    Receta.create!(
      nombre: nombre || "Plato #{SecureRandom.hex(4)}",
      tipo: "plato",
      porciones: porciones,
      precio_venta: precio_venta
    )
  end

  def crear_preparacion(nombre: nil, rinde: 1000, unidad: "g")
    Receta.create!(
      nombre: nombre || "Preparacion #{SecureRandom.hex(4)}",
      tipo: "preparacion",
      rendimiento_cantidad: rinde,
      rendimiento_unidad: unidad
    )
  end

  def agregar(receta, insumable, cantidad, unidad)
    Ingrediente.create!(
      receta: receta, insumable: insumable, cantidad: cantidad, unidad: unidad
    )
  end
end

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    include Constructores
  end
end
