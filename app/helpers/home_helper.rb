module HomeHelper
  def qr_button(address)
      tag.button(
        class: "btn-t ghost sm icon-only",
        title: "二维码",
        data: { action: "qr#show", qr_address: address }
      ) { "QR" }
    end
end
