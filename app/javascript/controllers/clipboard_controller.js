import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy(event) {
    event.preventDefault()
    const btn = event.currentTarget

    // 优先用 value，为空则退回 DOM 属性；两者其实是同一个属性，这里只是兜底
    const text = this.textValue || btn.dataset.clipboardTextValue || ""

    if (!text) {
      console.warn("clipboard: 要复制的内容为空，检查 data-clipboard-text-value 是否被赋值")
      return
    }

    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(text)
      } else {
        // 非安全上下文（如 http://192.168.x.x）的降级方案
        const ta = document.createElement("textarea")
        ta.value = text
        ta.style.position = "fixed"
        ta.style.opacity = "0"
        document.body.appendChild(ta)
        ta.select()
        document.execCommand("copy")
        document.body.removeChild(ta)
      }

      const orig = btn.textContent
      btn.textContent = "✓ 已复制"
      setTimeout(() => { btn.textContent = orig }, 1500)
    } catch (e) {
      console.error("copy failed:", e)
    }
  }
}
