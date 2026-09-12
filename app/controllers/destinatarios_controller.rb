class DestinatariosController < ApplicationController
  include PantallaDeAjustes
  solo_administradores
  before_action :set_destinatario, only: %i[update destroy]

  def create
    @destinatario = Destinatario.new(destinatario_params)

    if @destinatario.save
      redirect_to edit_configuracion_path,
                  notice: "#{@destinatario.correo} recibirá los avisos."
    else
      cargar_ajustes
      render "configuraciones/edit", status: :unprocessable_entity
    end
  end

  # Un boton que alterna. No recibe el estado nuevo por parametro para
  # que no se pueda pedir "activalo" dos veces desde pestanas distintas
  # y quedar sin saber cual gano.
  def update
    @destinatario.update!(activo: !@destinatario.activo?)

    verbo = @destinatario.activo? ? "vuelve a recibir" : "deja de recibir"
    redirect_to edit_configuracion_path, notice: "#{@destinatario.correo} #{verbo} los avisos."
  end

  def destroy
    @destinatario.destroy
    redirect_to edit_configuracion_path, notice: "#{@destinatario.correo} salió de la lista."
  end

  private

  def set_destinatario
    @destinatario = Destinatario.find(params[:id])
  end

  def destinatario_params
    params.expect(destinatario: [ :correo ])
  end
end
