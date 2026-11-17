import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "fixedBlock", "randBlock",
    "amountInput", "tokenSelect", "recvTable",
    "selectedCount", "summaryCount", "summaryAmount", "summaryUnit", "unitLabel"
  ]

  connect() {
    this.refresh()
    // 监听表单提交，把页面当前值同步到 hidden fields
    const form = document.getElementById("dispatchSubmitForm")
    if (form) {
      form.addEventListener("submit", () => this.syncForm())
    }
  }

  refresh() {
    const mode = document.querySelector("input[name='amount_mode']:checked")?.value || "fixed"
    this.fixedBlockTarget.classList.toggle("d-none", mode !== "fixed")
    this.randBlockTarget.classList.toggle("d-none", mode !== "random")

    const symbol = this.tokenSelectTarget.selectedOptions[0]?.dataset.symbol || "BNB"
    this.unitLabelTarget.textContent = symbol
    this.summaryUnitTarget.textContent = symbol

    const n = this.checkedCount()
    this.selectedCountTarget.textContent = n
    this.summaryCountTarget.textContent = n

    if (mode === "fixed") {
      const amt = parseFloat(this.amountInputTarget.value) || 0
      this.summaryAmountTarget.textContent = (amt * n).toFixed(6)
    } else {
      this.summaryAmountTarget.textContent = "随机"
    }

    this.syncForm()
  }

  syncForm() {
    const mode = document.querySelector("input[name='amount_mode']:checked")?.value || "fixed"
    document.getElementById("form_from_address_id").value = document.getElementById("from_address_select").value
    document.getElementById("form_token_id").value       = document.getElementById("token_select").value
    document.getElementById("form_amount_mode").value    = mode
    document.getElementById("form_fixed_amount").value   = document.getElementById("fixed_amount").value
    document.getElementById("form_min_amount").value     = document.getElementById("min_amount").value
    document.getElementById("form_max_amount").value     = document.getElementById("max_amount").value

    const container = document.getElementById("form_to_address_ids")
    container.innerHTML = ""
    this.checkedBoxes().forEach(cb => {
      const input = document.createElement("input")
      input.type = "hidden"
      input.name = "to_address_ids[]"
      input.value = cb.value
      container.appendChild(input)
    })
  }

  selectAll() {
    this.recvTableTarget.querySelectorAll("input[name='to_address_ids[]']")
      .forEach(cb => { cb.checked = true })
    this.refresh()
  }

  toggleAll(event) {
    this.recvTableTarget.querySelectorAll("input[name='to_address_ids[]']")
      .forEach(cb => { cb.checked = event.target.checked })
    this.refresh()
  }

  checkedBoxes() {
    return Array.from(
      this.recvTableTarget.querySelectorAll("input[name='to_address_ids[]']:checked")
    )
  }

  checkedCount() { return this.checkedBoxes().length }
}
