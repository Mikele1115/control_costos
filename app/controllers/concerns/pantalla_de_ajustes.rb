# Ajustes es una sola pantalla con tres formularios: cuando falla
# cualquiera de ellos hay que volver a dibujarla entera, asi que los
# tres controladores necesitan exactamente el mismo estado.
#
# Los `||=` son a proposito: si el controlador ya dejo el objeto con
# errores, este metodo no lo pisa con uno limpio.
module PantallaDeAjustes
  extend ActiveSupport::Concern

  private
    def cargar_ajustes
      @configuracion   = Configuracion.actual
      @destinatarios   = Destinatario.ordenados
      @destinatario  ||= Destinatario.new
      @usuarios        = User.ordenados
      @usuario_nuevo ||= User.new
    end
end
