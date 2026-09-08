class CreateRecetas < ActiveRecord::Migration[8.1]
  def change
    create_table :recetas do |t|
      t.string  :nombre, null: false
      t.string  :tipo,   null: false

      # Solo platos
      t.integer :porciones
      t.decimal :precio_venta, precision: 12, scale: 2

      # Solo preparaciones
      t.decimal :rendimiento_cantidad, precision: 12, scale: 4
      t.string  :rendimiento_unidad

      t.timestamps
    end

    add_index :recetas, :nombre, unique: true

    add_check_constraint :recetas,
      "tipo IN ('plato', 'preparacion')", name: "tipo_valido"
    add_check_constraint :recetas,
      "porciones IS NULL OR porciones > 0", name: "porciones_positivas"
    add_check_constraint :recetas,
      "rendimiento_cantidad IS NULL OR rendimiento_cantidad > 0",
      name: "rendimiento_positivo"
    add_check_constraint :recetas,
      "precio_venta IS NULL OR precio_venta >= 0",
      name: "precio_venta_no_negativo"

    # Un plato necesita porciones; una preparacion necesita rendimiento.
    add_check_constraint :recetas, <<~SQL.squish, name: "rendimiento_segun_tipo"
      (tipo = 'plato' AND porciones IS NOT NULL)
      OR
      (tipo = 'preparacion' AND rendimiento_cantidad IS NOT NULL
                            AND rendimiento_unidad IS NOT NULL)
    SQL
  end
end
