# encoding: utf-8
# author: Boris Barroso
# email: boriscyber@gmail.com
module ApplicationHelper
  # Checks if is set the organisation session
  # @return [True, False]
  def organisation?
    session[:organisation] and session[:organisation].size > 0
  end


  # Presens the logo of an organisation based on the session
  # @return [String]
  def organisation_logo
    session[:organisation][:name]
  end

  def verdad?(val)
    val ? "Si": "No"
  end

  # Presents number to currency
  def ntc(val = nil)
    val ||= 0
    number_to_currency(val)
  end

  # Format addres to present on the
  def nl2br(val)
    val.gsub!("\n", "<br/>").html_safe unless val.nil?
  end

  # Changes the <br/> for a \n
  def br2nl(val)
    val.gsub!("<br/>", "\n") unless val.nil?
  end

  # Used for localization
  def lo(val)
    localize(val) unless val.nil?
  end
end
