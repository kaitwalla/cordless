import { Controller } from "@hotwired/stimulus"
import MentionsAutocompleteHandler from "lib/autocomplete/mentions_autocomplete_handler"
import EmojisAutocompleteHandler from "lib/autocomplete/emojis_autocomplete_handler"
import CommandsAutocompleteHandler from "lib/autocomplete/commands_autocomplete_handler"
import { debounce } from "helpers/timing_helpers"

export default class extends Controller {
  static values = { url: String, emojisUrl: String, commandsUrl: String }

  initialize() {
    this.handlers = []
    this.search = debounce(this.search.bind(this), 300)
  }

  connect() {
    if (this.element == document.activeElement) {
      this.#installHandlers()
    }
  }

  focus(event) {
    this.#installHandlers()
  }

  search(event) {
    const content = this.editor.getDocument().toString()
    const position = this.editor.getPosition()
    this.handlers.forEach(handler => handler.updateWithContentAndPosition(content, position))
  }

  blur(event) {
    this.#uninstallHandlers()
  }

  #installHandlers() {
    this.#uninstallHandlers()
    this.handlers = [
      new MentionsAutocompleteHandler(this.element, this.urlValue)
    ]
    if (this.emojisUrlValue) {
      this.handlers.push(new EmojisAutocompleteHandler(this.element, this.emojisUrlValue))
    }
    if (this.commandsUrlValue) {
      this.handlers.push(new CommandsAutocompleteHandler(this.element, this.commandsUrlValue))
    }
  }

  #uninstallHandlers() {
    this.handlers.forEach(handler => handler.destroy())
    this.handlers = []
  }

  get editor() {
    return this.element.editor
  }
}
