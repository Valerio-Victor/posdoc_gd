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
### Ao todo são 10 recursos. No entanto, para obter as instalações
### o segundo recurso é o importante, portanto, deve-se obter a url deste recurso.
### com o id "b1bd71e7-d0ad-4214-9053-cbd58e9564a7".

info <- ckanr::resource_show(id = 'b1bd71e7-d0ad-4214-9053-cbd58e9564a7')


# IMPORTAÇÃO DOS DADOS: ---------------------------------------------------
url_dados <- ckanr::resource_show(id = 'b1bd71e7-d0ad-4214-9053-cbd58e9564a7')
url_dados$url

### RESULTADO:
### Pode-se observar que os dados estão em formato csv. Portanto, vou usar o readr
### considerandoque os dados são brasileiros, o separador decimal é diferente do
### padrão internacional

url_final <- (url_dados$url)

tictoc::tic()
# dados <- readr::read_csv2(file = url_final,
#                           locale = readr::locale(encoding = 'ASCII'),
#                           col_names = TRUE)


dados <- readr::read_delim(file = url_final,
                           delim = ';',
                           escape_double = FALSE,
                           col_types = readr::cols(
                             DatGeracaoConjuntoDados =
                               readr::col_date(format = '%Y-%m-%d'),
                             AnmPeriodoReferencia =
                               readr::col_date(format = '%m/%Y'),
                             DthAtualizaCadastralEmpreend =
                               readr::col_date(format = '%Y-%m-%d'),
                             NumCoordNEmpreendimento =
                               readr::col_character(),
                             NumCoordEEmpreendimento =
                               readr::col_character()),
                           locale = readr::locale(encoding = 'ISO-8859-1'),
                           trim_ws = TRUE)
tictoc::toc()


# BREVE ARRUMAÇÃO DE DADOS: -----------------------------------------------
dados <- dados %>%
  tibble::as_tibble()

tibble::glimpse(dados)


# FILTROS (SE NECESSÁRIO): ------------------------------------------------
rm(info,
   url_aneel,
   url_dados,
   url_final)


dados_mg <- dados %>%
  dplyr::filter(SigUF == 'MG')


# EXPORTAÇÃO DOS DADOS: ---------------------------------------------------
tictoc::tic()

write.csv2(dados,
           file = './dados/dados_gd.csv',
           fileEncoding = 'UTF-8')

write.csv2(dados_mg,
           file = './dados/dados_gd_mg.csv',
           fileEncoding = 'UTF-8')

tictoc::toc()

beepr::beep(sound = 8)

