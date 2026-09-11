# Quien recibe los avisos de food cost.
#
# Queda la lista completa y no solo los vigentes: desactivar a alguien
# deja constancia de que estuvo, que es justo lo que se pidio. Borrarlo
# sigue siendo posible, pero es una decision aparte.
class Destinatario < ApplicationRecord
  # `.presence` convierte "" en nil para que el mensaje que ve el
  # usuario sea "no puede quedar vacio" y no "no parece un correo".
  normalizes :correo, with: ->(correo) { correo.strip.downcase.presence }

  validates :correo, presence: { message: "no puede quedar vacío" }

  validates :correo,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "no parece un correo" },
            uniqueness: { message: "ya está en la lista" },
            allow_nil: true

  scope :activos,   -> { where(activo: true).order(:correo) }
  scope :ordenados, -> { order(activo: :desc, correo: :asc) }

  def self.correos_activos = activos.pluck(:correo)
end
