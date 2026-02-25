import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers/timing_helpers"

export default class extends Controller {
  static targets = ["menu", "search", "grid", "tabs", "toggle"]
  static outlets = ["composer"]
  static values = {
    url: String,
    customEmojisUrl: String,
    categories: { type: Array, default: ["smileys", "gestures", "people", "hearts", "animals", "nature", "food", "objects", "symbols", "flags", "activities", "travel", "misc"] }
  }

  #emojis = { custom: [], unicode: {} }
  #currentCategory = "smileys"
  #loaded = false
  #loading = false

  initialize() {
    this.search = debounce(this.search.bind(this), 150)
  }

  connect() {
    document.addEventListener("click", this.#handleClickOutside)
    document.addEventListener("keydown", this.#handleKeydown)
  }

  disconnect() {
    document.removeEventListener("click", this.#handleClickOutside)
    document.removeEventListener("keydown", this.#handleKeydown)
  }

  toggle(event) {
    if (this.menuTarget.hasAttribute("hidden")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.menuTarget.removeAttribute("hidden")
    this.#updateAriaExpanded(true)
    if (!this.#loaded && !this.#loading) {
      this.#loadEmojis()
    }
    this.searchTarget.focus()
  }

  close() {
    this.menuTarget.setAttribute("hidden", "")
    this.#updateAriaExpanded(false)
    this.searchTarget.value = ""
    if (this.#loaded) {
      this.#renderCategory(this.#currentCategory)
    }
    this.#showTabs()
  }

  search(event) {
    const query = this.searchTarget.value.trim().toLowerCase()

    if (query.length === 0) {
      this.#renderCategory(this.#currentCategory)
      this.#showTabs()
    } else {
      this.#renderSearchResults(query)
      this.#hideTabs()
    }
  }

  selectCategory(event) {
    const category = event.currentTarget.dataset.category
    this.#currentCategory = category
    this.#updateActiveTab(category)
    this.#renderCategory(category)
  }

  selectEmoji(event) {
    if (!this.hasComposerOutlet) return

    const button = event.currentTarget
    const type = button.dataset.type
    const editor = this.composerOutlet.textTarget?.editor
    if (!editor) return

    if (type === "unicode") {
      editor.insertString(button.dataset.emoji)
    } else {
      const attachment = this.#createCustomEmojiAttachment(button.dataset)
      editor.insertAttachment(attachment)
    }

    this.close()
    this.composerOutlet.textTarget.focus()
  }

  #handleClickOutside = (event) => {
    if (!this.element.contains(event.target) && !this.menuTarget.hasAttribute("hidden")) {
      this.close()
    }
  }

  #handleKeydown = (event) => {
    if (event.key === "Escape" && !this.menuTarget.hasAttribute("hidden")) {
      this.close()
      event.preventDefault()
    }
  }

  async #loadEmojis() {
    this.#loading = true
    try {
      const response = await fetch(`${this.urlValue}?all=true`)
      if (!response.ok) {
        throw new Error(`Failed to fetch emojis: ${response.status}`)
      }
      const data = await response.json()

      this.#emojis.custom = data.custom_emojis || []
      this.#emojis.unicode = data.unicode_emojis || {}

      this.#loaded = true
      this.#renderCategory(this.#currentCategory)
    } catch (error) {
      console.error("Failed to load emojis:", error)
    } finally {
      this.#loading = false
    }
  }

  #renderCategory(category) {
    let html = ""

    if (category === "custom") {
      html = this.#renderCustomEmojis()
    } else {
      const emojis = this.#emojis.unicode[category] || []
      html = emojis.map(emoji => this.#renderUnicodeEmoji(emoji)).join("")
    }

    if (html === "") {
      html = '<div class="emoji-picker__empty">No emojis found</div>'
    }

    this.gridTarget.innerHTML = html
  }

  #renderSearchResults(query) {
    let results = []

    // Search custom emojis
    this.#emojis.custom.forEach(emoji => {
      if (emoji.shortcode.toLowerCase().includes(query)) {
        results.push(this.#renderCustomEmojiButton(emoji))
      }
    })

    // Search unicode emojis across all categories
    Object.values(this.#emojis.unicode).forEach(categoryEmojis => {
      categoryEmojis.forEach(emoji => {
        if (emoji.shortcode.toLowerCase().includes(query)) {
          results.push(this.#renderUnicodeEmoji(emoji))
        }
      })
    })

    if (results.length === 0) {
      this.gridTarget.innerHTML = '<div class="emoji-picker__empty">No emojis found</div>'
    } else {
      this.gridTarget.innerHTML = results.join("")
    }
  }

  #renderCustomEmojis() {
    if (this.#emojis.custom.length === 0) {
      return '<div class="emoji-picker__empty">No custom emojis yet</div>'
    }
    return this.#emojis.custom.map(emoji => this.#renderCustomEmojiButton(emoji)).join("")
  }

  #renderCustomEmojiButton(emoji) {
    return `
      <button type="button" class="emoji-picker__emoji btn btn--borderless"
              data-action="emoji-picker#selectEmoji"
              data-type="custom"
              data-shortcode="${this.#escapeAttr(emoji.shortcode)}"
              data-image-url="${this.#escapeAttr(emoji.image_url)}"
              data-sgid="${this.#escapeAttr(emoji.sgid)}"
              title=":${this.#escapeAttr(emoji.shortcode)}:">
        <img src="${this.#escapeAttr(emoji.image_url)}" alt=":${this.#escapeAttr(emoji.shortcode)}:" class="emoji-picker__custom-image">
      </button>
    `
  }

  #renderUnicodeEmoji(emoji) {
    return `
      <button type="button" class="emoji-picker__emoji btn btn--borderless"
              data-action="emoji-picker#selectEmoji"
              data-type="unicode"
              data-emoji="${this.#escapeAttr(emoji.emoji)}"
              title=":${this.#escapeAttr(emoji.shortcode)}:">
        <span class="emoji-picker__unicode">${this.#escapeAttr(emoji.emoji)}</span>
      </button>
    `
  }

  #createCustomEmojiAttachment(data) {
    const content = `
      <span class="custom-emoji" data-shortcode="${this.#escapeAttr(data.shortcode)}">
        <img src="${this.#escapeAttr(data.imageUrl)}" alt=":${this.#escapeAttr(data.shortcode)}:" class="custom-emoji__image">
      </span>
    `

    return new Trix.Attachment({
      content: content,
      contentType: "application/vnd.cordless.custom-emoji",
      sgid: data.sgid
    })
  }

  #updateActiveTab(category) {
    this.tabsTarget.querySelectorAll("[data-category]").forEach(tab => {
      const isActive = tab.dataset.category === category
      tab.classList.toggle("emoji-picker__tab--active", isActive)
      tab.setAttribute("aria-selected", isActive ? "true" : "false")
    })
  }

  #updateAriaExpanded(expanded) {
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", expanded ? "true" : "false")
    }
  }

  #showTabs() {
    this.tabsTarget.removeAttribute("hidden")
  }

  #hideTabs() {
    this.tabsTarget.setAttribute("hidden", "")
  }

  #escapeAttr(str) {
    if (!str) return ""
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#39;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
  }
}
