module ApplicationHelper
  def nav_link(label, path)
    active = current_page?(path) || request.path.start_with?(path.sub(/\/$/, ""))
    css = "nav-link #{'active' if active}"
    content_tag(:li, class: "nav-item") do
      link_to label, path, class: css
    end
  end

  def short_address(addr) = "#{addr[0, 6]}…#{addr[-4..]}"

  def fmt_wei(amount_wei, decimals = 18)
    (BigDecimal(amount_wei.to_s) / (BigDecimal(10)**decimals)).to_s("F")
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
