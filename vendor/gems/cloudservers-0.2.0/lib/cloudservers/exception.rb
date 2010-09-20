module CloudServers
  class Exception

    class CloudServersError < StandardError

      attr_reader :response_body
      attr_reader :response_code

      def initialize(message, code, response_body)
        @response_code=code
        @response_body=response_body
        super(message)
      end

    end
    
    class CloudServersFault           < CloudServersError # :nodoc:
    end
    class ServiceUnavailable          < CloudServersError # :nodoc:
    end
    class Unauthorized                < CloudServersError # :nodoc:
    end
    class BadRequest                  < CloudServersError # :nodoc:
    end
    class OverLimit                   < CloudServersError # :nodoc:
    end
    class BadMediaType                < CloudServersError # :nodoc:
    end
    class BadMethod                   < CloudServersError # :nodoc:
    end
    class ItemNotFound                < CloudServersError # :nodoc:
    end
    class BuildInProgress             < CloudServersError # :nodoc:
    end
    class ServerCapacityUnavailable   < CloudServersError # :nodoc:
    end
    class BackupOrResizeInProgress    < CloudServersError # :nodoc:
    end
    class ResizeNotAllowed            < CloudServersError # :nodoc:
    end
    class NotImplemented              < CloudServersError # :nodoc:
    end
    class Other                       < CloudServersError # :nodoc:
    end
    
    # Plus some others that we define here
    
    class ExpiredAuthToken            < StandardError # :nodoc:
    end
    class MissingArgument             < StandardError # :nodoc:
    end
    class TooManyPersonalityItems     < StandardError # :nodoc:
    end
    class PersonalityFilePathTooLong  < StandardError # :nodoc:
    end
    class PersonalityFileTooLarge     < StandardError # :nodoc:
    end
    class Authentication              < StandardError # :nodoc:
    end
    class Connection                  < StandardError # :nodoc:
    end
        
    # In the event of a non-200 HTTP status code, this method takes the HTTP response, parses
    # the JSON from the body to get more information about the exception, then raises the
    # proper error.  Note that all exceptions are scoped in the CloudServers::Exception namespace.
    def self.raise_exception(response)
      return if response.code =~ /^20.$/
      begin
        fault,info = JSON.parse(response.body).first
        exception_class = self.const_get(fault[0,1].capitalize+fault[1,fault.length])
        raise exception_class.new(info["message"], response.code, response.body)
      rescue NameError
        raise CloudServers::Exception::Other.new("The server returned status #{response.code}", response.code, response.body)
      end
    end
    
  end
end

