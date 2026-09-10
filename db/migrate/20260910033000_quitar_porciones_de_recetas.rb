class QuitarPorcionesDeRecetas < ActiveRecord::Migration[8.1]
  # Se escribe up/down en vez de change porque quitar una columna con
  # restricciones alrededor no es reversible de forma automatica:
  # Rails no puede adivinar el tipo ni las reglas que habia.
  def up
    remove_check_constraint :recetas, name: "rendimiento_segun_tipo"
    remove_check_constraint :recetas, name: "porciones_positivas"
    remove_column :recetas, :porciones

    # Un plato ya no exige nada extra: la receta ES el plato.
    # Una preparacion sigue necesitando su rendimiento para poder
    # dosificarse dentro de otra receta.
    add_check_constraint :recetas, <<~SQL.squish, name: "rendimiento_segun_tipo"
      tipo = 'plato'
      OR (tipo = 'preparacion' AND rendimiento_cantidad IS NOT NULL
                               AND rendimiento_unidad IS NOT NULL)
    SQL
  end

  def down
    remove_check_constraint :recetas, name: "rendimiento_segun_tipo"
    add_column :recetas, :porciones, :integer
    add_check_constraint :recetas, "porciones IS NULL OR porciones > 0",
      name: "porciones_positivas"
    add_check_constraint :recetas, <<~SQL.squish, name: "rendimiento_segun_tipo"
      (tipo = 'plato' AND porciones IS NOT NULL)
      OR (tipo = 'preparacion' AND rendimiento_cantidad IS NOT NULL
                               AND rendimiento_unidad IS NOT NULL)
    SQL
  end
end
