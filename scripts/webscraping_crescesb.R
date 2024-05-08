# PACOTES NECESSÁRIOS: ----------------------------------------------------
library(magrittr)


# LATITUDE E LONGITUDE DOS MUNICÍPIOS: ------------------------------------
coordenadas_municipios <- geobr::read_municipal_seat(year = 2010,
                                                     showProgress = TRUE)



municipios <- coordenadas_municipios %>%
  as.data.frame() %>%
  dplyr::mutate(geom = as.character(geom)) %>%
  tidyr::separate(col = geom,
                  into = c('long', 'lat'),
                  sep = ',') %>%
  dplyr::mutate(long =  stringr::str_replace(long,
                                             pattern = 'c',
                                             replacement = '')) %>%
  dplyr::mutate(long =  stringr::str_replace(long,
                                             pattern = '[(]',
                                             replacement = '')) %>%
  dplyr::mutate(lat =  stringr::str_replace(lat,
                                            pattern = '[)]',
                                            replacement = ''))


# WEBSCRAPING RECURSO SOLAR: ----------------------------------------------
for (i in 1:nrow(municipios)) {

  lat <- -as.numeric(municipios[i,9])
  lng <- -as.numeric(municipios[i,8])


  # Definição da URL base de requisição:
  url_base <- 'http://www.cresesb.cepel.br/index.php'


  # Parâmetros da requisição post com referência a latitude e longitude:
  parametros <- list(latitude_dec = lat,
                     latitude = -lat,
                     hemi_lat = 0,
                     longitude_dec = lng,
                     longitude = -lng,
                     formato = 1,
                     lang = 'pt',
                     section = 'sundata')


  # Requisição da Página (com impressão do html na pasta0):
  pagina <- httr::POST(url_base,
                       body = parametros,
                       httr::write_disk('./script_recursos_brasil/crescesb.html',
                                        overwrite = TRUE))


  # Definição do XML path para as tabelas com os dados de recurso solar:
  tab_sundata <- '//*[@class="tb_sundata"]'


  # Arrumação dos dados para organização da tabela:
  crescesb <- xml2::read_html('./script_recursos_brasil/crescesb.html') %>%
    xml2::xml_find_first(tab_sundata) %>%
    rvest::html_table() %>%
    janitor::clean_names() %>%
    tibble::as_tibble() %>%
    dplyr::select(!number)


  nomes <- crescesb[1, ]
  colnames(crescesb) <- nomes


  crescesb <- crescesb %>%
    janitor::clean_names() %>%
    dplyr::select(!c(na, na_2)) %>%
    dplyr::filter(angulo != 'Ângulo') %>%
    tibble::as_tibble()


  # Criando o data frame complexo com listas
  municipios$recurso_solar[i] <- list(crescesb)
}


municipios_rs <- municipios %>%
  tidyr::unnest(recurso_solar)

writexl::write_xlsx(x = municipios_rs,
                    path = './script_recursos_brasil/crescesb_solar.xlsx')

