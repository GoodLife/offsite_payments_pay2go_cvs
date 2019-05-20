require 'test_helper'

class Pay2goCvsModuleTest < Test::Unit::TestCase
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Pay2goCvs::Notification, Pay2goCvs.notification('name=cody')
  end
end
