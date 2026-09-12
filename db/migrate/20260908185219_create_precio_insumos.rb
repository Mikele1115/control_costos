class CreatePrecioInsumos < ActiveRecord::Migration[8.1]
  def change
    create_table :precio_insumos do |t|
      t.references :insumo, null: false, foreign_key: true

      t.decimal :precio_compra,         precision: 12, scale: 2, null: false
      t.decimal :cantidad_compra,       precision: 12, scale: 4, null: false
      t.string  :unidad_compra,         null: false
      t.decimal :costo_por_unidad_base, precision: 14, scale: 6, null: false
      t.date    :vigente_desde,         null: false

      t.timestamps
    end

    add_index :precio_insumos, [ :insumo_id, :vigente_desde ], unique: true

    add_check_constraint :precio_insumos, "precio_compra >= 0",
      name: "precio_no_negativo"
    add_check_constraint :precio_insumos, "cantidad_compra > 0",
      name: "cantidad_positiva"
    add_check_constraint :precio_insumos, "costo_por_unidad_base >= 0",
      name: "costo_no_negativo"
  end
end
