import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Use requestAnimationFrame to ensure Trix is ready
    requestAnimationFrame(() => this.#replaceContent())
  }

  #replaceContent() {
    try {
      const editor = this.element.editor
      const contentScript = document.getElementById("edit_body_content")
      if (editor && contentScript) {
        const content = JSON.parse(contentScript.textContent)
        console.log("[edit-body] Loading content:", content.substring(0, 200))
        editor.loadHTML(content)
        console.log("[edit-body] Content loaded successfully")
      }
    } catch (e) {
      console.error("[edit-body] Error loading content:", e)
    }
  }
}
