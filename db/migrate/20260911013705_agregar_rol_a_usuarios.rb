class AgregarRolAUsuarios < ActiveRecord::Migration[8.1]
  def change
    # El default es el rol mas limitado a proposito: si alguien crea un
    # usuario sin decir nada, que nazca sin poder tocar nada.
    add_column :users, :rol, :string, null: false, default: "observador"

    add_check_constraint :users,
      "rol IN ('administrador', 'digitador', 'observador')",
      name: "rol_valido"

    # Las cuentas que ya existen son las duenias del sistema. Si
    # quedaran como observadoras nadie podria entrar a Ajustes, y no
    # habria forma de arreglarlo desde la propia aplicacion.
    reversible do |direccion|
      direccion.up { execute "UPDATE users SET rol = 'administrador'" }
    end
  end
end
