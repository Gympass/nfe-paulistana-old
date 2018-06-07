require 'savon'

module NfePaulistana
  class Gateway
    METHODS = {
      envio_rps: "EnvioRPSRequest",
      envio_lote_rps: "EnvioLoteRPSRequest",
      teste_envio_lote_rps: "TesteEnvioLoteRPSRequest",
      cancelamento_n_fe: "CancelamentoNFeRequest",
      consulta_cnpj: "ConsultaCNPJRequest",
      consulta_n_fe: "ConsultaNFeRequest",
      consulta_n_fe_recebidas: "ConsultaNFeRecebidasRequest",
      consulta_n_fe_emitidas: "ConsultaNFeEmitidasRequest",
      consulta_lote: "ConsultaLoteRequest",
      consulta_informacoes_lote: "ConsultaInformacoesLoteRequest"
    }

    def initialize(options = {})
      @options = {
        cert_path: "",
        cert_pass: "",
        wsdl: 'https://nfe.prefeitura.sp.gov.br/ws/lotenfe.asmx?wsdl'
      }.merge(options)
    end

    def envio_rps(data = {})
      request(:envio_rps, data)
    end

    def envio_lote_rps(data = {})
      request(:envio_lote_rps, data)
    end

    def teste_envio_lote_rps(data = {})
      request(:teste_envio_lote_rps, data)
    end

    def cancelamento_nfe(data = {})
      request(:cancelamento_n_fe, data)
    end

    def consulta_nfe(data = {})
      request(:consulta_n_fe, data)
    end

    def consulta_nfe_recebidas(data = {})
      request(:consulta_n_fe_recebidas, data)
    end

    def consulta_nfe_emitidas(data = {})
      request(:consulta_n_fe_emitidas, data)
    end

    def consulta_lote(data = {})
      request(:consulta_lote, data)
    end

    def consulta_informacoes_lote(data = {})
      request(:consulta_informacoes_lote, data)
    end

    def consulta_cnpj(data = {})
      request(:consulta_cnpj, data)
    end

    private

    def certificate
      OpenSSL::PKCS12.new(File.read(@options[:cert_path]), @options[:cert_pass])
    end

    def request(method, data = {})
      certificado = certificate
      client      = get_client(certificado)

      response = client.call(method, message: {
        header: { "SOAPAction" => "\"urn:#{METHODS[method]}\"" },
        namespaces: {
          "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/",
          "xmlns:xsi"  => "http://www.w3.org/2001/XMLSchema-instance",
          "xmlns:xsd"  => "http://www.w3.org/2001/XMLSchema"
        },
        input: [ METHODS[method], {"xmlns" => "http://www.prefeitura.sp.gov.br/nfe"} ],
        body:  XmlBuilder.new.xml_for(method, data, certificado),
        version: 1
      })

      method_response = (method.to_s + "_response").to_sym
      Response.new(xml: response.to_hash[method_response][:retorno_xml], method: method)
    rescue Savon::Error => error
      error
    end

    def get_client(certificado)
      Savon.client(
        soap_version: 1,
        ssl_verify_mode: :peer,
        wsdl: @options[:wsdl],
        ssl_cert_key: certificado.key,
        ssl_cert: certificado.certificate
      )
    end
  end
end
