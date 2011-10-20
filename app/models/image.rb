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

  def self.legacy_defaults(image_id)

    image_arr={
      75 => "linux", #"Debian 6.0 (Squeeze)"
      51 => "linux", #"CentOS 5.5"
      187811 => "linux", #"Centos 5.4"]
      78 => "linux", # "Fedora 15 (Lovelock)"]
      71 => "linux", # "Fedora 14 (Laughlin)"]
      53 => "linux", # "Fedora 13 (Goddard)"]
      14 => "linux", # "Red Hat EL 5.4"]
      62 => "linux", # "Red Hat EL 5.5"]
      76 => "linux", # "Ubuntu 11.04 (natty)"]
      69 => "linux", #"Ubuntu 10.10 (maverick)"]
      49 => "linux", #"Ubuntu 10.04 LTS (lucid)"]
      14362 => "linux", #"Ubuntu 9.10 (karmic)"]
      28 => "windows", #"Windows Server 2008 R2 x64"]
      58 => "windows" #"Windows Server 2008 R2 x64 SQL Server"]
    }

    return image_arr[image_id]

  end

end
