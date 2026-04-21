import ApplicationController from "controllers/application_controller"

export default class extends ApplicationController {
  static values = { duration: { type: Number, default: 3000 } }

  connect() {
    this.element.classList.add("transition-opacity", "duration-200")
    this.timeout = setTimeout(() => this.close(), this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  close() {
    this.element.classList.add("opacity-0")
    this.element.addEventListener("transitionend", () => this.element.remove(), { once: true })
  }
}
