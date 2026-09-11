require "test_helper"

class DestinatarioTest < ActiveSupport::TestCase
  test "limpia el correo antes de guardarlo" do
    destinatario = Destinatario.create!(correo: "  CHEF@LaSplendida.CL  ")

    assert_equal "chef@lasplendida.cl", destinatario.correo
  end

  test "nace activo" do
    assert Destinatario.create!(correo: "chef@lasplendida.cl").activo?
  end

  test "rechaza un correo vacio con un mensaje entendible" do
    destinatario = Destinatario.new(correo: "   ")

    assert_not destinatario.valid?
    assert_equal ["no puede quedar vacío"], destinatario.errors[:correo],
                 "un campo en blanco no deberia quejarse ademas del formato"
  end

  test "rechaza algo que no parece un correo" do
    destinatario = Destinatario.new(correo: "el chef")

    assert_not destinatario.valid?
    assert_includes destinatario.errors[:correo], "no parece un correo"
  end

  test "no deja repetir un correo, ni cambiando mayusculas" do
    Destinatario.create!(correo: "chef@lasplendida.cl")
    repetido = Destinatario.new(correo: "  CHEF@LASPLENDIDA.CL ")

    assert_not repetido.valid?
    assert_includes repetido.errors[:correo], "ya está en la lista"
  end

  test "la base tambien rechaza el repetido" do
    Destinatario.create!(correo: "chef@lasplendida.cl")

    assert_raises ActiveRecord::RecordNotUnique do
      Destinatario.transaction(requires_new: true) do
        Destinatario.new(correo: "chef@lasplendida.cl").save!(validate: false)
      end
    end
  end

  test "activos deja fuera a los desactivados y ordena por correo" do
    Destinatario.create!(correo: "zulema@lasplendida.cl")
    Destinatario.create!(correo: "ana@lasplendida.cl")
    Destinatario.create!(correo: "fuera@lasplendida.cl", activo: false)

    assert_equal ["ana@lasplendida.cl", "zulema@lasplendida.cl"], Destinatario.correos_activos
  end

  test "ordenados pone primero a los activos" do
    Destinatario.create!(correo: "fuera@lasplendida.cl", activo: false)
    Destinatario.create!(correo: "zulema@lasplendida.cl")

    assert_equal ["zulema@lasplendida.cl", "fuera@lasplendida.cl"],
                 Destinatario.ordenados.map(&:correo)
  end
end
