import { Controller } from "@hotwired/stimulus"

const EDGE_PADDING = 16
const VALID_CORNERS = ["top-left", "top-right", "bottom-left", "bottom-right"]

export default class extends Controller {
  static targets = ["handle"]

  connect() {
    this.#restorePosition()
  }

  disconnect() {
    document.removeEventListener("mousemove", this.#handleDrag)
    document.removeEventListener("mouseup", this.#handleDragEnd)
  }

  startDrag(event) {
    if (event.button !== 0) return // Only left click

    event.preventDefault()

    this.isDragging = true
    this.startX = event.clientX
    this.startY = event.clientY

    const rect = this.element.getBoundingClientRect()
    this.initialLeft = rect.left
    this.initialTop = rect.top

    document.addEventListener("mousemove", this.#handleDrag)
    document.addEventListener("mouseup", this.#handleDragEnd)

    this.element.style.transition = "none"
    this.element.style.cursor = "grabbing"
  }

  #handleDrag = (event) => {
    if (!this.isDragging) return

    const deltaX = event.clientX - this.startX
    const deltaY = event.clientY - this.startY

    let newLeft = this.initialLeft + deltaX
    let newTop = this.initialTop + deltaY

    // Constrain to viewport
    const rect = this.element.getBoundingClientRect()
    const maxLeft = window.innerWidth - rect.width - EDGE_PADDING
    const maxTop = window.innerHeight - rect.height - EDGE_PADDING

    newLeft = Math.max(EDGE_PADDING, Math.min(newLeft, maxLeft))
    newTop = Math.max(EDGE_PADDING, Math.min(newTop, maxTop))

    this.element.style.left = `${newLeft}px`
    this.element.style.top = `${newTop}px`
    this.element.style.right = "auto"
    this.element.style.bottom = "auto"
  }

  #handleDragEnd = () => {
    if (!this.isDragging) return

    this.isDragging = false

    document.removeEventListener("mousemove", this.#handleDrag)
    document.removeEventListener("mouseup", this.#handleDragEnd)

    this.element.style.transition = ""
    this.element.style.cursor = ""

    this.#snapToCorner()
    this.#savePosition()
  }

  #snapToCorner() {
    const rect = this.element.getBoundingClientRect()
    const centerX = rect.left + rect.width / 2
    const centerY = rect.top + rect.height / 2

    const viewportCenterX = window.innerWidth / 2
    const viewportCenterY = window.innerHeight / 2

    // Determine which corner to snap to
    const isRight = centerX > viewportCenterX
    const isBottom = centerY > viewportCenterY

    // Apply snapped position
    this.element.style.transition = "all 0.2s ease-out"

    if (isRight) {
      this.element.style.left = "auto"
      this.element.style.right = `${EDGE_PADDING}px`
    } else {
      this.element.style.left = `${EDGE_PADDING}px`
      this.element.style.right = "auto"
    }

    if (isBottom) {
      this.element.style.top = "auto"
      this.element.style.bottom = `${EDGE_PADDING}px`
    } else {
      this.element.style.top = `${EDGE_PADDING}px`
      this.element.style.bottom = "auto"
    }

    // Store corner preference
    this.corner = `${isBottom ? "bottom" : "top"}-${isRight ? "right" : "left"}`
  }

  #savePosition() {
    if (this.corner) {
      try {
        localStorage.setItem("call-pip-corner", this.corner)
      } catch {
        // Ignore storage errors (private browsing, quota exceeded, etc.)
      }
    }
  }

  #restorePosition() {
    let corner = "bottom-right"
    try {
      const stored = localStorage.getItem("call-pip-corner")
      if (stored && VALID_CORNERS.includes(stored)) {
        corner = stored
      }
    } catch {
      // Ignore storage errors
    }

    const [vertical, horizontal] = corner.split("-")

    // Reset all positions first
    this.element.style.top = "auto"
    this.element.style.right = "auto"
    this.element.style.bottom = "auto"
    this.element.style.left = "auto"

    // Apply saved corner position
    if (horizontal === "right") {
      this.element.style.right = `${EDGE_PADDING}px`
    } else {
      this.element.style.left = `${EDGE_PADDING}px`
    }

    if (vertical === "bottom") {
      this.element.style.bottom = `${EDGE_PADDING}px`
    } else {
      this.element.style.top = `${EDGE_PADDING}px`
    }

    this.corner = corner
  }
}
