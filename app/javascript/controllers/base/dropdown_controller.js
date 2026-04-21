import ApplicationController from "controllers/application_controller"

export default class extends ApplicationController {
  connect() {
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    document.addEventListener("click", this.handleOutsideClick)
    document.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleKeydown)
  }

  closeOthers() {
    if (!this.element.open) return
    this.peers().forEach(el => { if (el !== this.element) el.open = false })
  }

  handleOutsideClick(event) {
    if (!this.element.open) return
    if (this.element.contains(event.target)) return
    this.element.open = false
  }

  handleKeydown(event) {
    if (event.key !== "Escape" || !this.element.open) return
    this.element.open = false
    this.element.querySelector("summary")?.focus()
  }

  peers() {
    return document.querySelectorAll("details[data-controller~='base--dropdown']")
  }
}
