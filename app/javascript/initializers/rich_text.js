import Unfurler from "lib/rich_text/unfurl/unfurler"

// Support a `cite` block for attribution links
Trix.config.blockAttributes.cite = {
  tagName: "cite",
  inheritable: false,
}

// Support a `small` text style for smaller text
Trix.config.textAttributes.small = {
  tagName: "small",
  inheritable: true,
  parser: (element) => {
    const style = window.getComputedStyle(element)
    return element.tagName.toLowerCase() === "small" || style.fontSize === "smaller"
  }
}

// Add keyboard shortcut for small text (Cmd/Ctrl + Shift + -)
addEventListener("trix-initialize", (event) => {
  const editor = event.target
  const { toolbarElement } = editor

  // Add small button to text-tools group
  const textToolsGroup = toolbarElement.querySelector(".trix-button-group--text-tools")
  if (textToolsGroup) {
    const smallButton = document.createElement("button")
    smallButton.type = "button"
    smallButton.className = "trix-button trix-button--icon trix-button--icon-small"
    smallButton.dataset.trixAttribute = "small"
    smallButton.title = "Small (⌘⇧-)"
    smallButton.tabIndex = -1
    smallButton.textContent = "Small"
    textToolsGroup.appendChild(smallButton)
  }

  // Add keyboard shortcut
  editor.addEventListener("keydown", (e) => {
    if ((e.metaKey || e.ctrlKey) && e.shiftKey && e.key === "-") {
      e.preventDefault()
      const editorController = editor.editorController
      if (editorController.composition.currentAttributes.small) {
        editorController.deactivateAttribute("small")
      } else {
        editorController.activateAttribute("small")
      }
    }
  })
})

const unfurler = new Unfurler()
unfurler.install()
