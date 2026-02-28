import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "image", "input", "dropzone", "shortcode" ]
  static classes = [ "dragging" ]

  previewImage() {
    const file = this.inputTarget.files[0]
    this.#previewFile(file)
    this.#deriveShortcode(file)
  }

  dragenter(event) {
    event.preventDefault()
    this.#showDragging()
  }

  dragover(event) {
    event.preventDefault()
    event.dataTransfer.dropEffect = "copy"
  }

  dragleave(event) {
    // Only hide if leaving the dropzone entirely
    if (!this.element.contains(event.relatedTarget)) {
      this.#hideDragging()
    }
  }

  drop(event) {
    event.preventDefault()
    this.#hideDragging()

    const file = event.dataTransfer.files[0]
    if (file && file.type.startsWith("image/")) {
      this.#setFile(file)
      this.#previewFile(file)
      this.#deriveShortcode(file)
    }
  }

  #previewFile(file) {
    if (file) {
      this.imageTarget.src = URL.createObjectURL(file)
      this.imageTarget.onload = () => { URL.revokeObjectURL(this.imageTarget.src) }
    }
  }

  #setFile(file) {
    // Create a DataTransfer to set files on the input
    const dataTransfer = new DataTransfer()
    dataTransfer.items.add(file)
    this.inputTarget.files = dataTransfer.files
  }

  #showDragging() {
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.add(this.draggingClass)
    }
  }

  #hideDragging() {
    if (this.hasDropzoneTarget) {
      this.dropzoneTarget.classList.remove(this.draggingClass)
    }
  }

  #deriveShortcode(file) {
    if (!this.hasShortcodeTarget || !file) return
    if (this.shortcodeTarget.value.trim() !== "") return

    // Get filename without extension and sanitize for shortcode
    const name = file.name.replace(/\.[^/.]+$/, "")
    const shortcode = name
      .toLowerCase()
      .replace(/[^a-z0-9_-]/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-|-$/g, "")

    this.shortcodeTarget.value = shortcode
  }
}
