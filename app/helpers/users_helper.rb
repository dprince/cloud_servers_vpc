module UsersHelper

  def reservation_image_name(obj)
    if obj.image then
      obj.image.name
    else
      ""
    end
  end

end
