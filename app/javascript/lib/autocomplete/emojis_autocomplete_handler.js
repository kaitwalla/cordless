import BaseAutocompleteHandler from "lib/autocomplete/base_autocomplete_handler"
import { Renderer } from "lib/autocomplete/renderer"

class EmojisRenderer extends Renderer {
  renderAutocompletable(autocompletable) {
    if (autocompletable.type === "unicode") {
      return `
        <button class="autocomplete__btn autocomplete__emoji btn btn--borderless btn--transparent min-width flex-item-grow justify-start" data-value="${autocompletable.value}">
          <span class="autocomplete__emoji-unicode">${autocompletable.emoji}</span>
          <span class="autocomplete__emoji-shortcode">:${autocompletable.value}:</span>
        </button>
      `
    } else {
      return `
        <button class="autocomplete__btn autocomplete__emoji btn btn--borderless btn--transparent min-width flex-item-grow justify-start" data-value="${autocompletable.value}">
          <img src="${autocompletable.image_url}" class="autocomplete__emoji-image" alt=":${autocompletable.value}:" />
          <span class="autocomplete__emoji-shortcode">:${autocompletable.value}:</span>
        </button>
      `
    }
  }
}

export default class extends BaseAutocompleteHandler {
  #renderer = new EmojisRenderer()

  get pattern() {
    return new RegExp(`^:([a-z0-9_-]*)$`)
  }

  insertAutocompletable(autocompletable, range, terminator) {
    if (range) { this.#editor.setSelectedRange(range) }

    if (autocompletable.type === "unicode") {
      // Insert Unicode emoji directly as text
      this.#editor.insertString(autocompletable.emoji + terminator)
    } else {
      // Insert custom emoji as Trix attachment
      const attachment = this.#createCustomEmojiAttachment(autocompletable)
      this.#editor.insertAttachment(attachment)
      this.#editor.insertString(terminator)
    }
  }

  // Override to set selector's position relative to the cursor in the editor
  getOffsetsAtPosition(position) {
    return this.#getOffsetsFromEditorAtPosition(this.#editor, position)
  }

  fetchResultsForQuery(query, callback) {
    this.loadAutocompletables(query, () => {
      const autocompletables = this.autocompletablesMatchingQuery(query)
      const html = this.#renderer.renderAutocompletableSuggestions(autocompletables)
      callback(html)
    })
  }

  #createCustomEmojiAttachment(emoji) {
    const content = `
      <span class="custom-emoji" data-shortcode="${emoji.value}">
        <img src="${emoji.image_url}" alt=":${emoji.value}:" class="custom-emoji__image">
      </span>
    `

    return new Trix.Attachment({
      content: content,
      contentType: "application/vnd.cordless.custom-emoji",
      sgid: emoji.sgid
    })
  }

  get #editor() {
    return this.element.editor
  }

  #getOffsetsFromEditorAtPosition(editor, position) {
    const rect = this.#editor.getClientRectAtPosition(position)
    return rect ? rect : {}
  }
}
