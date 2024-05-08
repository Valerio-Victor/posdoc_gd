# PACOTES UTILIZADOS: -----------------------------------------------------
  library(magrittr, include.only = '%>%')


# CONEXÃO COM A BASE DE DADOS DA ANEEL: -----------------------------------
url_aneel <- 'https://dadosabertos.aneel.gov.br/'
ckanr::ckanr_setup(url_aneel)


# INICIANDO PESQUISA DA SÉRIE DE INSTALAÇÕES GD: --------------------------
# Quais os grupos da base de dados da ANEEL?
ckanr::group_list()

### RESULTADO:
### Ao todo são 13 grupos. O grupo 5 denominado "geracao-distribuida" possui dois
### pacotes e seu id é "c00d34c7-5bf8-4c04-a332-e5af4f86286f"

# Quais os pacotes relacionados ao grupo "geracao-distribuida"?
ckanr::group_show(id = 'c00d34c7-5bf8-4c04-a332-e5af4f86286f',
                  as = 'table') %>%
  purrr::pluck('packages') %>%
  dplyr::select('name', 'id')

### RESULTADO:
### Ao todo são 2 pacotes dentro do grupo. No entanto, para as instalações o pacote
### importante é "relacao-de-empreendimentos-de-geracao-distribuida", com o id
### a ser utilizado "5e0fafd2-21b9-4d5b-b622-40438d40aba2"

# Quais os recursos relacionados ao pacote
# "relacao-de-empreendimentos-de-geracao-distribuida"?
ckanr::package_show(id = '5e0fafd2-21b9-4d5b-b622-40438d40aba2',
                    as = 'table') %>%
  purrr::pluck('resources') %>%
  dplyr::select('name', 'id')

### RESULTADO:
### Ao todo são 10 recursos. No entanto, para obter informações técnicas importa
### o sexto recurso, portanto, deve-se obter a url deste recurso.
### com o id "49fa9ca0-f609-4ae3-a6f7-b97bd0945a3a".

info <- ckanr::resource_show(id = '49fa9ca0-f609-4ae3-a6f7-b97bd0945a3a')


# IMPORTAÇÃO DOS DADOS: ---------------------------------------------------
url_dados <- ckanr::resource_show(id = '49fa9ca0-f609-4ae3-a6f7-b97bd0945a3a')
url_dados$url

### RESULTADO:
### Pode-se observar que os dados estão em formato csv. Portanto, vou usar o readr
### considerandoque os dados são brasileiros, o separador decimal é diferente do
### padrão internacional

url_final <- (url_dados$url)

tictoc::tic()

dados <- readr::read_delim(file = url_final,
                           delim = ';',
                           escape_double = FALSE,
                           locale = readr::locale(encoding = 'ISO-8859-1'),
                           trim_ws = TRUE)
tictoc::toc()


# BREVE ARRUMAÇÃO DE DADOS: -----------------------------------------------
dados <- dados %>%
  tibble::as_tibble()

tibble::glimpse(dados)


# EXPORTAÇÃO DOS DADOS: ---------------------------------------------------
tictoc::tic()

write.csv2(dados,
           file = './dados/dados_gd_info.csv',
           fileEncoding = 'UTF-8')

tictoc::toc()

beepr::beep(sound = 8)

