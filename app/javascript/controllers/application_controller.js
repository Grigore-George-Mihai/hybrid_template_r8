import { Controller } from "@hotwired/stimulus"

export default class ApplicationController extends Controller {
  debounce(fn, wait = 200) {
    let timer
    return (...args) => {
      clearTimeout(timer)
      timer = setTimeout(() => fn.apply(this, args), wait)
    }
  }

  dispatchCustomEvent(name, detail = {}) {
    this.element.dispatchEvent(
      new CustomEvent(name, { bubbles: true, cancelable: true, detail })
    )
  }
}
