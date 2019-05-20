require 'test_helper'

class Pay2goCvsFetcherTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def setup
    OffsitePayments::Integrations::Pay2goCvs.hash_key = '123456789012345678901234567890123456789012'
    OffsitePayments::Integrations::Pay2goCvs.hash_iv = '1234567890123456'
  end

  def test_encrypted_data
    raw_str = 'abcdefghijklmnop'
    encrypted = OffsitePayments::Integrations::Pay2goCvs::Fetcher.encrypted_data(raw_str)
    assert_equal encrypted, 'b91d3ece42c203729b38ae004e96efb9b64c41eeb074cad7ebafa3973181d233'
  end

  def test_params_validation
    @params = raw_params
    OffsitePayments::Integrations::Pay2goCvs::Fetcher.new(@params)
    assert_raises do
      @params["Amt"] = 1000
      OffsitePayments::Integrations::Pay2goCvs::Fetcher.new(@params)
    end
  end

  private

  def raw_params
    {
      "MerchantOrderNo"=>"236991q0607125134",
      "MerchantID"=>"12012491",
      "Amt"=>"2800",
      "RespondType"=>"JSON",
      "TimeStamp"=>"1464675117",
      "Version"=>"1.0",
      "ProdDesc"=>"Product",
      "Email"=>"abc@example.com",
      "ExpireDate"=>"20160607",
      "CheckValue"=> "3B522904C09F6DAF6DB0235689465F29B20D3F7D48793B08BA430447D9A660B5",
      "id"=>"236991"
    }
  end
end
