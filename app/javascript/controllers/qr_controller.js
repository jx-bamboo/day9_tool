import { Controller } from "@hotwired/stimulus"
import qrcode from "qrcode-generator"

export default class extends Controller {
  static targets = ["container", "address"]

  connect() {
    console.log("... qr controller connected ...", this.element)

    // this.element 就是 #qrModal
    this.onShow = this.onShow.bind(this)
    this.element.addEventListener("show.bs.modal", this.onShow)
  }

  disconnect() {
    this.element.removeEventListener("show.bs.modal", this.onShow)
  }

  // Bootstrap 打开 modal 时触发，event.relatedTarget 就是触发按钮
  onShow(event) {
    const trigger = event.relatedTarget
    if (!trigger) return

    const address = trigger.dataset.qrAddress || trigger.dataset.address
    if (!address) return

    this.render(address)
  }

  // 保留你原来的方法，方便以后用 Stimulus action 方式调用
  show(event) {
    event.preventDefault()
    const address = event.currentTarget.dataset.qrAddress || event.currentTarget.dataset.address
    if (!address) return

    this.render(address)

    const modalEl = document.getElementById("qrModal")
    bootstrap.Modal.getOrCreateInstance(modalEl).show()
  }

  render(address) {
    const qr = qrcode(0, "M")
    qr.addData(address)
    qr.make()
    this.containerTarget.innerHTML = qr.createImgTag(5, 8)
    this.addressTarget.textContent = address

    // 同步更新“复制地址”按钮的值
    const copyBtn = this.element.querySelector("[data-clipboard-text-value]")
    if (copyBtn) copyBtn.dataset.clipboardTextValue = address
  }
}
