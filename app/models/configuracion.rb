# Los ajustes del restaurante: cuando avisar. A quien avisar vive en
# Destinatario, que es una lista.
#
# Es una sola fila: la base lo garantiza con la columna `unica`, y
# `Configuracion.actual` la crea la primera vez que alguien entra.
class Configuracion < ApplicationRecord
  validates :umbral_aviso,
            numericality: {
              greater_than: 0,
              less_than_or_equal_to: 100,
              message: "debe estar entre 0,01 y 100"
            }

  def self.actual = first_or_create!

  # Encendido y con alguien a quien escribirle: recien ahi tiene
  # sentido costear la carta entera.
  def avisar? = avisos_activos? && Destinatario.activos.exists?
end
