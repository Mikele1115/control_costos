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

  # --- Semaforo del food cost ---------------------------------------
  #
  # Los umbrales son de Receta: aca solo se decide el color.

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
    texto = valor.nil? ? "—" : "#{number_with_precision(valor, precision: 1)} %"
    clase = valor.nil? ? clase_food_cost(nil) : clase_food_cost(100 - valor)

    content_tag :span, texto,
      class: "inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold #{clase}"
  end

  def insignia_food_cost(valor)
    texto = valor.nil? ? "—" : "#{number_with_precision(valor, precision: 1)} %"
    content_tag :span, texto,
      class: "inline-flex rounded-full px-2.5 py-0.5 text-xs font-semibold #{clase_food_cost(valor)}"
  end
end
