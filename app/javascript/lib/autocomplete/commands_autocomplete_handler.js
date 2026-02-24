import BaseAutocompleteHandler from "lib/autocomplete/base_autocomplete_handler"
import { Renderer } from "lib/autocomplete/renderer"

class CommandsRenderer extends Renderer {
  renderAutocompletable(autocompletable) {
    return `
      <button class="autocomplete__btn autocomplete__command btn btn--borderless btn--transparent min-width flex-item-grow justify-start" data-value="${autocompletable.value}">
        <span class="autocomplete__command-name txt-bold">${autocompletable.name}</span>
        <span class="autocomplete__command-description txt-subtle txt-small">${autocompletable.description}</span>
      </button>
    `
  }
}

export default class extends BaseAutocompleteHandler {
  #renderer = new CommandsRenderer()

  get pattern() {
    return new RegExp(`^\\/([a-z0-9_]*)$`)
  }

  // Only show autocomplete at the start of a message
  shouldAutocompleteWithContentAndPosition(content, position) {
    // Check if the / is at the beginning of the content
    return content.trimStart().startsWith("/") && position <= content.indexOf("/") + content.match(/\/[a-z0-9_]*/)?.[0]?.length + 1
  }

  insertAutocompletable(autocompletable, range, terminator) {
    if (range) { this.#editor.setSelectedRange(range) }
    // Insert the command name with the slash
    this.#editor.insertString(`/${autocompletable.value}${terminator}`)
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

  get #editor() {
    return this.element.editor
  }

  #getOffsetsFromEditorAtPosition(editor, position) {
    const rect = this.#editor.getClientRectAtPosition(position)
    return rect ? rect : {}
  }
}
