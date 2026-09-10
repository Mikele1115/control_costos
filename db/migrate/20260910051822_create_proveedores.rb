class CreateProveedores < ActiveRecord::Migration[8.1]
  def change
    create_table :proveedores do |t|
      t.string :nombre,   null: false
      t.string :contacto
      t.string :telefono

      t.timestamps
    end

    add_index :proveedores, :nombre, unique: true

    # on_delete: :nullify y no :restrict.
    #
    # Un precio sin insumo no significa nada, por eso alli bloqueamos
    # el borrado. Un insumo sin proveedor si significa algo: es un
    # insumo del que no anotaste a quien se lo compras. Borrar un
    # proveedor no deberia obligarte a reasignar veinte insumos.
    add_reference :insumos, :proveedor, foreign_key: { on_delete: :nullify }
  end
end
