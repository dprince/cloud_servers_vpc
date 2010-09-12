module CloudServers
  class Exception
    
    class CloudServersFault           < StandardError # :nodoc:
    end
    class ServiceUnavailable          < StandardError # :nodoc:
    end
    class Unauthorized                < StandardError # :nodoc:
    end
    class BadRequest                  < StandardError # :nodoc:
    end
    class OverLimit                   < StandardError # :nodoc:
    end
    class BadMediaType                < StandardError # :nodoc:
    end
    class BadMethod                   < StandardError # :nodoc:
    end
    class ItemNotFound                < StandardError # :nodoc:
    end
    class BuildInProgress             < StandardError # :nodoc:
    end
    class ServerCapacityUnavailable   < StandardError # :nodoc:
    end
    class BackupOrResizeInProgress    < StandardError # :nodoc:
    end
    class ResizeNotAllowed            < StandardError # :nodoc:
    end
    class NotImplemented              < StandardError # :nodoc:
    end
    
    # Plus some others that we define here
    
    class Other                       < StandardError # :nodoc:
    end
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
      fault,info = JSON.parse(response.body).first
      begin
        exception_class = self.const_get(fault[0,1].capitalize+fault[1,fault.length])
        raise exception_class, info["message"]
      rescue NameError
        raise CloudServers::Exception::Other, "The server returned status #{response.code}"
      end
    end
    
  end
end

