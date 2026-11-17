module TransfersHelper
  def short_address(addr)
    return "" if addr.blank?
    "#{addr[0, 6]}…#{addr[-4..]}"
  end

  def fmt_wei(amount_wei, decimals = 18)
    return "0" if amount_wei.nil?
    (BigDecimal(amount_wei.to_s) / (BigDecimal(10)**decimals.to_i)).to_s("F")
  end

  def transfer_status_badge(status)
    classes = {
      "pending"      => "dim",
      "broadcasting" => "yellow",
      "confirmed"    => "green",
      "failed"       => "red"
    }
    content_tag(:span, status, class: "badge-t #{classes[status] || 'dim'}")
  end
end
