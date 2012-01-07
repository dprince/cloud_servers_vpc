require 'digest/sha1'

class User < ActiveRecord::Base

    validates_presence_of :username, :first_name, :last_name
    validates_presence_of :password, :if => Proc.new { |user| user.new_record? }
    validates_uniqueness_of :username
    validates_format_of :username, :with => /^[^ ]*$/, :message => "Username may not contain spaces."
    validates_confirmation_of :password, :message => "Passwords do not match.", :if => :password
    validates_length_of :password, :in => 6..32, :allow_blank => false, :message => "Password must be between 6 and 32 characters.", :if => :password
    has_many :ssh_public_keys, :dependent => :destroy, :order => "description"
    has_one :account
    #validates_associated :account, :if => Proc.new { |user| user.new_record? }
    accepts_nested_attributes_for :account, :update_only => true

    attr_accessor :password_confirmation

    before_save :handle_before_save
    def handle_before_save

        if self.account.nil? then
            self.account = Account.create
        end

    end

    validate :handle_validate_on_create, :on => :create
    def handle_validate_on_create

        if self.account.nil? then
            errors[:base] << "A valid account is required."
        else
            begin
                acct=self.account
                acct.get_connection
            rescue Exception => e
                errors[:base] << "Unable to connect with cloud account credentials: #{e.message}"
            end
        end

    end

    def self.authenticate(username, password)

        user = self.find(:first, :conditions => ["username = ?", username ])

        if user.nil? then
            return nil
        else
            if user
                expected_password = encrypted_password(password, user.salt)
                if user.hashed_password == expected_password
                    return user
                else
                    return nil
                end
            end
        end

    end

    def password
        @password
    end

    def password=(pwd)
        @password = pwd
        self.salt = self.object_id.to_s + rand.to_s
        self.hashed_password = User.encrypted_password(self.password, self.salt)
    end

    private
    def self.encrypted_password(password, salt)
        string_to_hash = password + "cloud_control" + salt
        Digest::SHA1.hexdigest(string_to_hash)
    end

end
