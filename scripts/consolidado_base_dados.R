# PACOTES: ----------------------------------------------------------------
library(magrittr)


# IMPORTAÇÃO DOS DADOS: ---------------------------------------------------
instalacoes <- readr::read_csv2('./dados/dados_gd_mg.csv')

cnpj <- readr::read_csv2('./dados/cnpj_mg.csv') %>% 
  as.data.frame() %>% 
  janitor::clean_names()

tradutor <- readxl::read_xls('./dados/tradutor.xls') %>% 
  janitor::clean_names()

recurso_solar <- readxl::read_xlsx('./dados/crescesb_solar.xlsx')

dplyr::summarise()
# ARRUMAÇÃO DOS DADOS: ----------------------------------------------------
instalacoes_mg <- instalacoes %>% 
  janitor::clean_names() %>% 
  dplyr::filter(sig_tipo_geracao == 'UFV') %>% 
  dplyr::select(dth_atualiza_cadastral_empreend,
                cod_municipio_ibge,
                nom_municipio,
                dsc_classe_consumo,
                dsc_sub_grupo_tarifario,
                sig_tipo_consumidor,
                num_cpfcnpj,
                dsc_modalidade_habilitado,
                qtd_uc_recebe_credito,
                mda_potencia_instalada_kw) %>% 
  dplyr::mutate(cnpj = stringr::str_remove_all(num_cpfcnpj, '[*.-]')) %>% 
  dplyr::mutate(cnpj = as.numeric(cnpj))


recurso_solar <- recurso_solar %>% 
  dplyr::filter(angulo == 'Plano Horizontal') %>% 
  dplyr::select(code_muni, 
                long, 
                lat, 
                inclinacao,
                media)


cnpj_mg <- cnpj %>% 
  dplyr::select(cnpj, 
                cnae_fiscal_principal)

consolidado <- dplyr::left_join(instalacoes_mg, 
                                cnpj_mg,
                                by = c('cnpj' = 'cnpj'))

consolidado <- dplyr::left_join(consolidado,
                                recurso_solar,
                                by = c('cod_municipio_ibge' = 'code_muni')) %>% 
  dplyr::select(-cnpj) %>% 
  dplyr::mutate(media = stringr::str_replace_all(media,
                                                 pattern = ',', 
                                                 replacement = '.')) %>% 
  dplyr::mutate(producao_kwh = as.numeric(media)*as.numeric(mda_potencia_instalada_kw))


consolidado <- consolidado %>% 
  dplyr::mutate(cnae_fiscal_principal_04d = 
                  stringr::str_sub(cnae_fiscal_principal,
                                   start = 1,
                                   end = 4)) %>% 
  dplyr::full_join(
    tradutor, 
    by = c('cnae_fiscal_principal_04d' = 'classe_cnae_2_0_4_digitos'))

consolidado <- consolidado %>% 
  dplyr::rename('nome_setor_economico' = x2,
                'nome_cnae' = x4)


# EXPORTAÇÃO DE DADOS: ----------------------------------------------------
writexl::write_xlsx(x = consolidado,
                    path = './dados/consolidado.xlsx')


