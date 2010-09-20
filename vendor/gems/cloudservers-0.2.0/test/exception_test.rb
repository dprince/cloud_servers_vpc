require File.dirname(__FILE__) + '/test_helper'

class CloudServersExceptionTest < Test::Unit::TestCase
  
  def test_400_cloud_servers_fault
    response = mock()
    response.stubs(:code => "400", :body => "{\"cloudServersFault\":{\"message\":\"422 Unprocessable Entity: We could not process your request at this time. We have been notified and are looking into the issue.  [E03]\",\"details\":\"com.rackspace.cloud.service.servers.CloudServersFault: Fault occured\",\"code\":400}}" )
    exception=nil
    begin
      CloudServers::Exception.raise_exception(response)
    rescue Exception => e
      exception=e
    end
    assert_equal(CloudServers::Exception::CloudServersFault, e.class)
    assert_equal("400", e.response_code)
    assert_not_nil(e.response_body)
  end

  def test_413_over_limit
    response = mock()
    response.stubs(:code => "413", :body => "{\"overLimit\":{\"message\":\"Too many requests...\",\"code\":413,\"retryAfter\":\"2010-08-25T10:47:57.890-05:00\"}}")
    exception=nil
    begin
      CloudServers::Exception.raise_exception(response)
    rescue Exception => e
      exception=e
    end
    assert_equal(CloudServers::Exception::OverLimit, e.class)
    assert_equal("413", e.response_code)
    assert_not_nil(e.response_body)
  end

  def test_other
    response = mock()
    response.stubs(:code => "500", :body => "{\"blahblah\":{\"message\":\"Failed...\",\"code\":500}}")
    exception=nil
    begin
      CloudServers::Exception.raise_exception(response)
    rescue Exception => e
      exception=e
    end
    assert_equal(CloudServers::Exception::Other, e.class)
    assert_equal("500", e.response_code)
    assert_not_nil(e.response_body)
  end



=begin

500 Internal Server Error
{"cloudServersFault":{"message":"Could not send Message.","details":"javax.xml.ws.soap.SOAPFaultException: Could not send Message.","code":500}}

500 Internal Server Error
{"cloudServersFault":{"message":"Response was of unexpected text\/html ContentType.  Incoming portion of HTML stream: <!DOCTYPE HTML PUBLIC \"-\/\/W3C\/\/DTD HTML 4.01\/\/EN\" \"http:\/\/www.w3.org\/TR\/html4\/strict.dtd\">\n<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text\/html;charset=utf-8\">\n<title>Service Unavailable<\/title>\n<style type=\"text\/css\">\nbody, p, h1 {\n  font-family: Verdana, Arial, Helvetica, sans-serif;\n}\nh2 {\n  font-family: Arial, Helvetica, sans-serif;\n  color: #b10b29;\n}\n<\/style>\n<\/head>\n<body>\n<h2>Service Unavailable<\/h2>\n<p>The service is temporarily unavailable. Please try again later.<\/p>\n<\/body>\n<\/html>","details":"javax.xml.ws.soap.SOAPFaultException: Response was of unexpected text\/html ContentType.  Incoming portion of HTML stream: <!DOCTYPE HTML PUBLIC \"-\/\/W3C\/\/DTD HTML 4.01\/\/EN\" \"http:\/\/www.w3.org\/TR\/html4\/strict.dtd\">\n<html>\n<head>\n<meta http-equiv=\"Content-Type\" content=\"text\/html;charset=utf-8\">\n<title>Service Unavailable<\/title>\n<style type=\"text\/css\">\nbody, p, h1 {\n  font-family: Verdana, Arial, Helvetica, sans-serif;\n}\nh2 {\n  font-family: Arial, Helvetica, sans-serif;\n  color: #b10b29;\n}\n<\/style>\n<\/head>\n<body>\n<h2>Service Unavailable<\/h2>\n<p>The service is temporarily unavailable. Please try again later.<\/p>\n<\/body>\n<\/html>","code":500}}
=end
    
end
