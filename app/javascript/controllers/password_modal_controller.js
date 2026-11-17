// import { Controller } from "@hotwired/stimulus"
//
// export default class extends Controller {
//   static targets = ["title", "desc", "password", "confirmBtn"]
//
//   open(event) {
//     event.preventDefault()
//     const btn = event.currentTarget
//     const title = btn.dataset.execTitle || "确认执行"
//     const desc  = btn.dataset.execDesc || ""
//     const form  = btn.dataset.formId
//
//     this.titleTarget.textContent = title
//     this.descTarget.textContent = desc
//     this.passwordTarget.value = ""
//     this.confirmBtnTarget.dataset.formId = form
//
//     bootstrap.Modal.getOrCreateInstance(this.element).show()
//   }
//
//   confirm() {
//     if (this.passwordTarget.value.length < 8) {
//       alert("请输入至少 8 位执行密码")
//       return
//     }
//     const formId = this.confirmBtnTarget.dataset.formId
//     const form = formId ? document.getElementById(formId) : document.querySelector("form[data-dispatch-form]")
//     if (!form) return
//
//     // 把密码注入表单隐藏域
//     let hidden = form.querySelector("input[name='execution_password']")
//     if (!hidden) {
//       hidden = document.createElement("input")
//       hidden.type = "hidden"
//       hidden.name = "execution_password"
//       form.appendChild(hidden)
//     }
//     hidden.value = this.passwordTarget.value
//     bootstrap.Modal.getInstance(this.element).hide()
//     form.submit()
//   }
// }
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["title", "desc", "password", "confirmBtn"]

  // 由 Bootstrap 的 show.bs.modal 事件触发
  // event.relatedTarget 就是触发按钮本身
  onShow(event) {
    const btn = event.relatedTarget
    if (!btn) return

    this.titleTarget.textContent = btn.dataset.execTitle || "确认执行"
    this.descTarget.textContent  = btn.dataset.execDesc  || ""
    this.passwordTarget.value = ""
    this.confirmBtnTarget.dataset.formId = btn.dataset.formId || ""
    this.confirmBtnTarget.disabled = false
    this.confirmBtnTarget.textContent = "确认执行"

    setTimeout(() => this.passwordTarget.focus(), 200)
  }

  confirm(event) {
    event?.preventDefault()

    const pwd = this.passwordTarget.value
    if (pwd.length < 8) {
      alert("请输入至少 8 位执行密码")
      return
    }

    const formId = this.confirmBtnTarget.dataset.formId
    const form = formId ? document.getElementById(formId) : null
    if (!form) {
      alert("未找到表单：" + formId)
      return
    }

    // 先填入密码
    const pwdField = document.getElementById("form_execution_password")
    if (pwdField) pwdField.value = pwd

    // 防重复提交
    this.confirmBtnTarget.disabled = true
    this.confirmBtnTarget.textContent = "提交中…"

    // 关闭弹窗
    bootstrap.Modal.getInstance(this.element)?.hide()

    // ★ 用 requestSubmit 而不是 submit：
    //   requestSubmit 会触发 submit 事件 → dispatch controller 的 syncForm 被调用 → 其他字段同步
    //   submit 不会触发 submit 事件
    form.requestSubmit()
  }
}
