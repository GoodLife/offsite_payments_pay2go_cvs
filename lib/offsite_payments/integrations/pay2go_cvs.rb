require "offsite_payments"

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Pay2goCvs
      # 網站內部 controller 接收原始 post data 的 URL
      mattr_accessor :service_url
      # CVS API gateway 的 URL
      mattr_accessor :gateway_url
      mattr_accessor :merchant_id
      mattr_accessor :hash_key
      mattr_accessor :hash_iv
      mattr_accessor :debug

      def self.gateway_url
        mode = OffsitePayments.mode
        case mode
        when :production
          'https://core.spgateway.com/API/gateway/cvs'
        when :development
          'https://ccore.spgateway.com/API/gateway/cvs'
        when :test
          'https://ccore.spgateway.com/API/gateway/cvs'
        else
          raise StandardError, "Integration mode set to an invalid value: #{mode}"
        end
      end

      def self.notification(post)
        Notification.new(post)
      end

      def self.setup
        yield(self)
      end

      def self.fetch_url_encode_data(fields)
        check_fields = [:"Amt", :"MerchantID", :"MerchantOrderNo", :"TimeStamp", :"Version"]
        raw_data = fields.sort.map{|field, value|
          "#{field}=#{value}" if check_fields.include?(field.to_sym)
        }.compact.join('&')

        hash_raw_data = "HashKey=#{OffsitePayments::Integrations::Pay2goCvs.hash_key}&#{raw_data}&HashIV=#{OffsitePayments::Integrations::Pay2goCvs.hash_iv}"

        sha256 = Digest::SHA256.new
        sha256.update hash_raw_data.force_encoding("utf-8")
        sha256.hexdigest.upcase
      end

      class Helper < OffsitePayments::Helper
        ### 常見介面
        # 廠商編號
        mapping :merchant_id, 'MerchantID'
        mapping :account, 'MerchantID' # AM common
        # 回傳格式
        mapping :respond_type, 'RespondType'
        # 時間戳記
        mapping :time_stamp, 'TimeStamp'
        # 串接程式版本
        mapping :version, 'Version'
        # 廠商交易編號
        mapping :merchant_order_no, 'MerchantOrderNo'
        mapping :order, 'MerchantOrderNo' # AM common
        # 交易金額（幣別：新台幣）
        mapping :amt, 'Amt'
        mapping :amount, 'Amt' # AM common
        # 商品資訊（限制長度50字）
        mapping :product_desc, 'ProdDesc'
        # 繳費超商 (not required)
        mapping :allow_store, 'AllowStore'
        # 支付通知網址
        mapping :notify_url, 'NotifyURL'
        # 繳費有限日期，格式範例：20140620 (YYYYmmdd)
        mapping :expire_date, 'ExpireDate'
        # 繳費有限時間，格式範例：235959 (HHMMSS)
        mapping :expire_time, 'ExpireTime'
        # 付款人電子信箱
        mapping :email, 'Email'
        mapping :credential3, 'CustomizedUrl'

        def initialize(order, account, options = {})
          super
          add_field 'MerchantID', OffsitePayments::Integrations::Pay2goCvs.merchant_id
        end

        def credential_based_url
          @fields['CustomizedUrl']
        end

        def encrypted_data
          url_encrypted_data = OffsitePayments::Integrations::Pay2goCvs.fetch_url_encode_data(@fields)
          add_field 'CheckValue', url_encrypted_data
        end
      end

      class Notification < OffsitePayments::Notification
        attr_accessor :_params

        def _params
          if @_params.nil?
            if @params.key?("Result") # result data in json
              @_params = @params
              @_params = @_params.merge(JSON.parse(@_params['Result']))
            else
              @_params = @params
            end
          end
          @_params
        end

        # TODO 使用查詢功能實作 acknowledge
        # 而以 checksum_ok? 代替
        def acknowledge
          checksum_ok?
        end

        def complete?
          case status
          when 'SUCCESS' # 付款/取號成功
            true
          end
        end

        def calculate_checksum
          params_copy = _params.clone

          check_fields = [:"Amt", :"MerchantID", :"MerchantOrderNo", :"TradeNo"]
          raw_data = params_copy.sort.map{|field, value|
            "#{field}=#{value}" if check_fields.include?(field.to_sym)
          }.compact.join('&')

          hash_raw_data = "HashIV=#{OffsitePayments::Integrations::Pay2goCvs.hash_iv}&#{raw_data}&HashKey=#{OffsitePayments::Integrations::Pay2goCvs.hash_key}"

          sha256 = Digest::SHA256.new
          sha256.update hash_raw_data.force_encoding("utf-8")
          sha256.hexdigest.upcase
        end

        def checksum_ok?
          calculate_checksum == check_code.to_s
        end

        def status
          _params['Status']
        end

        def message
          URI.decode(_params['Message'])
        end

        def merchant_id
          _params['MerchantID']
        end

        def amt
          _params['Amt'].to_s
        end

        # 訂單號碼
        def item_id
          merchant_order_no
        end

        # Pay2goCvs 端訂單號碼
        def transaction_id
          trade_no
        end

        def trade_no
          _params['TradeNo']
        end

        def merchant_order_no
          _params['MerchantOrderNo']
        end

        def payment_type
          _params['PaymentType']
        end

        def respond_type
          _params['RespondType']
        end

        def check_code
          _params['CheckCode']
        end

        def pay_time
          URI.decode(_params['PayTime']).gsub("+", " ")
        end

        def ip
          _params['IP']
        end

        def escrow_bank
          _params['EscrowBank']
        end

        # credit card
        def respond_code
          _params['RespondCode']
        end

        def auth
          _params['Auth']
        end

        def card_6no
          _params['Card6No']
        end

        def card_4no
          _params['Card4No']
        end

        def inst
          _params['Inst']
        end

        def inst_first
          _params['InstFirst']
        end

        def inst_each
          _params['InstEach']
        end

        def eci
          _params['ECI']
        end

        def token_use_status
          _params['TokenUseStatus']
        end

        # web atm, atm
        def pay_bank_code
          _params['PayBankCode']
        end

        def payer_account_5code
          _params['PayerAccount5Code']
        end

        # cvs
        def code_no
          _params['CodeNo']
        end

        # barcode
        def barcode_1
          _params['Barcode_1']
        end

        def barcode_2
          _params['Barcode_2']
        end

        def barcode_3
          _params['Barcode_3']
        end

        # other about serials
        def expire_date
          _params['ExpireDate']
        end

      end

      class Fetcher
        attr_accessor :params

        def initialize(params)
          raise 'parameter missmatch' if params['CheckValue'] != OffsitePayments::Integrations::Pay2goCvs.fetch_url_encode_data(params)
          @params = pay2go_params(params)
        end

        def fetch
          result = RestClient.post OffsitePayments::Integrations::Pay2goCvs.gateway_url, {
            MerchantID_: OffsitePayments::Integrations::Pay2goCvs.merchant_id,
            PostData_: self.class.encrypted_data(@params.to_query)
          }
          if @params['RespondType'] == 'JSON'
            JSON.parse(result)
          else
            result
          end
        end

        private

        def pay2go_params(params)
          params.slice(:RespondType, :TimeStamp, :Version, :MerchantOrderNo, :Amt, :ProdDesc, :AllowStore, :NotifyURL, :ExpireDate, :ExpireTime, :Email)
        end

        def self.padding(str, blocksize = 32)
          len = str.size
          pad = blocksize - (len % blocksize)
          str += pad.chr * pad
        end

        def self.encrypted_data(data)
          cipher = OpenSSL::Cipher::AES.new(256, :CBC)
          cipher.encrypt
          cipher.padding = 0
          cipher.key = OffsitePayments::Integrations::Pay2goCvs.hash_key[0..31]
          cipher.iv = OffsitePayments::Integrations::Pay2goCvs.hash_iv
          data = self.padding(data)
          encrypted = cipher.update(data) + cipher.final
          encrypted.unpack('H*').first
        end
      end
    end
  end
end
