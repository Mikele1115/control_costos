module CosteoHelper
  # --- Navegacion ---------------------------------------------------

  def enlace_nav(texto, ruta)
    activo = current_page?(ruta) ||
             (ruta != root_path && request.path.start_with?(ruta))

    clases = activo ? "bg-slate-900 text-white" : "text-slate-600 hover:bg-slate-100"
    link_to texto, ruta, class: "rounded-md px-3 py-1.5 #{clases}"
  end

  # --- Formato ------------------------------------------------------

  def moneda(valor)
    return content_tag(:span, "—", class: "text-slate-400") if valor.nil?
    number_to_currency(valor)
  end

  def cantidad(valor, decimales = 2)
    return "—" if valor.nil?
    number_with_precision(valor, precision: decimales, strip_insignificant_zeros: true)
  end

  # Un solo lugar decide como se escribe un porcentaje. Sin esto,
  # la insignia mostraba "80,0 %" y la fila de al lado "80 %".
  def porcentaje(valor, decimales: 1)
    return "—" if valor.nil?

    "#{number_with_precision(valor, precision: decimales)} %"
  end

  # --- Resumen de precios -------------------------------------------

  # Elige la frase segun lo que dicen los datos. La decision esta aca
  # y no en la plantilla porque es una bifurcacion, no maquetado.
  def frase_resumen_precios(resumen)
    fecha = l(resumen.primero.vigente_desde, format: :long)

    return t("costeo.resumen.unico", insumo: resumen.insumo.nombre, fecha: fecha) if resumen.unico?

    clave = if resumen.subio? then "aumento"
    elsif resumen.bajo? then "baja"
    else "estable"
    end

    t("costeo.resumen.#{clave}",
      insumo:    resumen.insumo.nombre,
      fecha:     fecha,
      variacion: "#{number_with_precision(resumen.variacion.abs, precision: 1)} %",
      cambios:   pluralize(resumen.cambios, "cambio"))
  end

  # --- Semaforo del food cost ---------------------------------------
  #
  # Los umbrales son de Receta: aca solo se decide el color.

  # El color dice de un vistazo cuanto puede tocar cada cuenta: oscuro
  # el que manda, azul el que carga datos, gris el que solo mira.
  COLORES_ROL = {
    "administrador" => "bg-slate-900 text-white",
    "digitador"     => "bg-sky-100 text-sky-800",
    "observador"    => "bg-slate-100 text-slate-500"
  }.freeze

  def insignia_rol(usuario)
    content_tag :span, t("usuarios.roles.#{usuario.rol}"),
      class: "inline-flex rounded-full px-2 py-0.5 text-xs font-semibold #{COLORES_ROL.fetch(usuario.rol)}"
  end

  COLORES_BANDA = {
    perdida: "bg-rose-200 text-rose-900",
    critico: "bg-rose-100 text-rose-800",
    alto:    "bg-amber-100 text-amber-900",
    sano:    "bg-emerald-100 text-emerald-800",
    bajo:    "bg-sky-100 text-sky-800"
  }.freeze

  ETIQUETAS_BANDA = {
    perdida: "se vende bajo costo",
    critico: "crítico",
    alto:    "alto",
    sano:    "sano",
    bajo:    "bajo"
  }.freeze

  def clase_food_cost(valor)
    COLORES_BANDA.fetch(Receta.banda_para(valor), "bg-slate-100 text-slate-500")
  end

  def etiqueta_food_cost(valor)
    ETIQUETAS_BANDA.fetch(Receta.banda_para(valor), "sin datos")
  end

  # Margen y food cost son complementarios: suman 100. El color sale
  # del food cost equivalente, para que un 66 % de margen se vea igual
  # de sano que un 34 % de food cost.
  def insignia_margen(valor)
    texto = porcentaje(valor)
    clase = valor.nil? ? clase_food_cost(nil) : clase_food_cost(100 - valor)

    content_tag :span, texto,
      class: "inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold #{clase}"
  end

  def insignia_food_cost(valor)
    texto = porcentaje(valor)
    content_tag :span, texto,
      class: "inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold #{clase_food_cost(valor)}"
  end
end
