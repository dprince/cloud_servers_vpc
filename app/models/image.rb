class Image < ActiveRecord::Base

  validates_presence_of :name, :image_ref
  validates_length_of :name, :maximum => 255
  validates_inclusion_of :os_type, :in => %w( linux windows ), :message => "OS Type must be either 'linux' or 'windows'.", :if => :os_type

  belongs_to :account

  def self.sync(user)
    acct=user.account
    conn = CloudServersUtil.new(acct.cloud_servers_username, acct.cloud_servers_api_key)
    
    image_refs = []

    conn.all_images.each do |image|

      image_refs << (image[:id].to_s)

      img = Image.find(:first, :conditions => ["account_id = ? and image_ref = ?", acct.id, image[:id]])
      if not img then
        os_type = legacy_defaults(image[:id])
        is_active = os_type.nil? ? false : true
        Image.create(:name => image[:name], :image_ref => image[:id], :account_id => acct.id, :os_type => os_type, :is_active => is_active)
      end


    end

    Image.find(:all, :conditions => ["account_id = ?", acct.id] ).each do |img|
      if not image_refs.include?(img.image_ref.to_s) then
        img.destroy
      end
    end
 
  end

  # image id defaults for Cloud Servers (legacy)
  def self.legacy_defaults(image_id)

    image_arr={
      104 => "linux", #"Debian 6.0 (Squeeze)"
      114 => "linux", #"Centos 5.6"]
      118 => "linux", #"Centos 6.0"]
      116 => "linux", # "Fedora 15 (Lovelock)"]
      106 => "linux", # "Fedora 14 (Laughlin)"]
      110 => "linux", # "Red Hat EL 5.5"]
      111 => "linux", # "Red Hat EL 6.0"]
      119 => "linux", # "Ubuntu 11.10 (oneiric)"]
      115 => "linux", # "Ubuntu 11.04 (natty)"]
      112 => "linux", #"Ubuntu 10.04 LTS (lucid)"]
      28 => "windows", #"Windows Server 2008 R2 x64"]
      58 => "windows" #"Windows Server 2008 R2 x64 SQL Server"]
    }

    return image_arr[image_id]

  end

end
