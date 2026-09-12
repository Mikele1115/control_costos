class CreateIngredientes < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredientes do |t|
      t.references :receta, null: false, foreign_key: true

      # Polimorfico: apunta a un Insumo O a otra Receta.
      # No admite foreign_key porque referencia dos tablas distintas.
      t.references :insumable, polymorphic: true, null: false

      t.decimal :cantidad, precision: 12, scale: 4, null: false
      t.string  :unidad,   null: false

      t.timestamps
    end

    # Un mismo ingrediente no puede repetirse dentro de una receta
    add_index :ingredientes,
      [ :receta_id, :insumable_type, :insumable_id ],
      unique: true, name: "index_ingredientes_unicos"

    add_check_constraint :ingredientes,
      "cantidad > 0", name: "cantidad_positiva"
    add_check_constraint :ingredientes,
      "insumable_type IN ('Insumo', 'Receta')",
      name: "insumable_type_valido"
  end
end
