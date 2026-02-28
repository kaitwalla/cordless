import { Controller } from "@hotwired/stimulus"
import { debounce } from "helpers/timing_helpers"

export default class extends Controller {
  static targets = ["panel", "grid", "search", "tabs", "toggle", "form", "content", "submit"]
  static values = {
    url: String,
    messageId: Number,
    categories: { type: Array, default: ["smileys", "gestures", "people", "hearts", "animals", "nature", "food", "objects", "symbols", "flags", "activities", "travel", "misc"] }
  }

  #emojis = { custom: [], unicode: {} }
  #currentCategory = "smileys"
  #loaded = false
  #loading = false
  #expanded = false

  initialize() {
    this.search = debounce(this.search.bind(this), 150)
  }

  connect() {
    document.addEventListener("keydown", this.#handleKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.#handleKeydown)
  }

  toggle() {
    if (this.#expanded) {
      this.collapse()
    } else {
      this.expand()
    }
  }

  expand() {
    this.#expanded = true
    this.panelTarget.removeAttribute("hidden")
    this.toggleTarget.setAttribute("aria-expanded", "true")

    if (!this.#loaded && !this.#loading) {
      this.#loadEmojis()
    }

    if (this.hasSearchTarget) {
      this.searchTarget.focus()
    }
  }

  collapse() {
    this.#expanded = false
    this.panelTarget.setAttribute("hidden", "")
    this.toggleTarget.setAttribute("aria-expanded", "false")
    if (this.hasSearchTarget) {
      this.searchTarget.value = ""
    }
    if (this.#loaded) {
      this.#renderCategory(this.#currentCategory)
      this.#showTabs()
    }
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
    const button = event.currentTarget
    const emoji = button.dataset.emoji

    // Set the hidden input value and click the submit button
    this.contentTarget.value = emoji
    this.submitTarget.click()
  }

  #handleKeydown = (event) => {
    if (event.key === "Escape" && this.#expanded) {
      this.collapse()
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
      this.gridTarget.innerHTML = '<div class="boost-emoji-picker__empty">Failed to load emojis</div>'
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
      html = '<div class="boost-emoji-picker__empty">No emojis found</div>'
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
      this.gridTarget.innerHTML = '<div class="boost-emoji-picker__empty">No emojis found</div>'
    } else {
      this.gridTarget.innerHTML = results.join("")
    }
  }

  #renderCustomEmojis() {
    const addButton = this.#renderAddCustomEmojiButton()
    const emojis = this.#emojis.custom.map(emoji => this.#renderCustomEmojiButton(emoji)).join("")
    return addButton + emojis
  }

  #renderAddCustomEmojiButton() {
    const url = this.gridTarget.dataset.addCustomUrl
    const icon = this.gridTarget.dataset.addCustomIcon
    if (!url || !icon) return ""
    return `
      <a href="${this.#escapeAttr(url)}" class="boost-emoji-picker__emoji boost-emoji-picker__add-btn btn btn--borderless" title="Add custom emoji" target="_top">
        <img src="${this.#escapeAttr(icon)}" alt="Add" class="boost-emoji-picker__add-blob colorize--black">
      </a>
    `
  }

  #renderCustomEmojiButton(emoji) {
    return `
      <button type="button" class="boost-emoji-picker__emoji btn btn--borderless"
              data-action="boost-emoji-picker#selectEmoji"
              data-emoji=":${this.#escapeAttr(emoji.shortcode)}:"
              title=":${this.#escapeAttr(emoji.shortcode)}:">
        <img src="${this.#escapeAttr(emoji.image_url)}" alt=":${this.#escapeAttr(emoji.shortcode)}:" class="boost-emoji-picker__custom-image">
      </button>
    `
  }

  #renderUnicodeEmoji(emoji) {
    return `
      <button type="button" class="boost-emoji-picker__emoji btn btn--borderless"
              data-action="boost-emoji-picker#selectEmoji"
              data-emoji="${this.#escapeAttr(emoji.emoji)}"
              title=":${this.#escapeAttr(emoji.shortcode)}:">
        <span class="boost-emoji-picker__unicode">${this.#escapeAttr(emoji.emoji)}</span>
      </button>
    `
  }

  #updateActiveTab(category) {
    this.tabsTarget.querySelectorAll("[data-category]").forEach(tab => {
      const isActive = tab.dataset.category === category
      tab.classList.toggle("boost-emoji-picker__tab--active", isActive)
      tab.setAttribute("aria-selected", isActive ? "true" : "false")
    })
  }

  #showTabs() {
    if (this.hasTabsTarget) {
      this.tabsTarget.removeAttribute("hidden")
    }
  }

  #hideTabs() {
    if (this.hasTabsTarget) {
      this.tabsTarget.setAttribute("hidden", "")
    }
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
