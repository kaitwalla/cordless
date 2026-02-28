const EMOJI_PATTERN = /\p{Emoji_Presentation}|\p{Extended_Pictographic}/gu
const EMOJI_ONLY_MATCHER = /^(\p{Emoji_Presentation}|\p{Extended_Pictographic}|\uFE0F)+$/u

const SOUND_NAMES = [ "56k", "ballmer", "bell", "bezos", "bueller", "butts", "clowntown", "cottoneyejoe", "crickets", "curb", "dadgummit", "dangerzone", "danielsan", "deeper", "donotwant", "drama", "flawless", "glados", "gogogo", "greatjob", "greyjoy", "guarantee", "heygirl", "honk", "horn", "horror", "inconceivable", "letitgo", "live", "loggins", "makeitso", "noooo", "nyan", "ohmy", "ohyeah", "pushit", "rimshot", "rollout", "rumble", "sax", "secret", "sexyback", "story", "tada", "tmyk", "totes", "trololo", "trombone", "unix", "vuvuzela", "what", "whoomp", "wups", "yay", "yeah", "yodel" ]

export default class ClientMessage {
  #template

  constructor(template) {
    this.#template = template
  }

  render(clientMessageId, node) {
    const now = new Date()
    const body = this.#contentFromNode(node)

    return this.#createFromTemplate({
      clientMessageId,
      body,
      messageTimestamp: Math.floor(now.getTime()),
      messageDatetime: now.toISOString(),
      messageClasses: this.#emojiMessageClasses(node),
    })
  }

  update(clientMessageId, body) {
    const element = this.#findWithId(clientMessageId).querySelector(".message__body-content")

    if (element) {
      element.innerHTML = body
    }
  }

  failed(clientMessageId) {
    const element = this.#findWithId(clientMessageId)

    if (element) {
      element.classList.add("message--failed")
    }
  }

  #findWithId(clientMessageId) {
    return document.querySelector(`#message_${clientMessageId}`)
  }

  #contentFromNode(node) {
    if (this.#isPlayCommand(node)) {
      return `<span class="pending">Playing ${this.#matchPlayCommand(node)}…</span>`
    } else if (this.#isRichText(node)) {
      return this.#richTextContent(node)
    } else {
      return node
    }
  }


  #isPlayCommand(node) {
    return this.#matchPlayCommand(node)
  }

  #matchPlayCommand(node) {
    return this.#stripWrapperElement(node)?.match(new RegExp(`^/play (${SOUND_NAMES.join("|")})`))?.[1]
  }

  #stripWrapperElement(node) {
    return node.innerHTML?.replace(/<div>(?:<!--[\s\S]*?-->)*([\s\S]*?)<\/div>/i, '$1')
  }


  #isRichText(node) {
    return typeof(node) != "string"
  }

  #richTextContent(node) {
    return `<div class="trix-content">${node.innerHTML}</div>`
  }


  #createFromTemplate(data) {
    let html = this.#template.innerHTML

    for (const key in data) {
      html = html.replaceAll(`$${key}$`, data[key])
    }

    return html
  }

  #emojiMessageClasses(node) {
    if (!node) return ""

    // Count custom emoji attachments
    const customEmojiCount = this.#countCustomEmoji(node)

    // Get text content and remove custom emoji placeholder text
    let text = node.textContent || ""
    // Include non-breaking space (\u00A0) in whitespace removal
    const stripped = text.replace(/[\s\u00A0]/g, "")

    if (customEmojiCount > 0 && !stripped) {
      // Only custom emojis
      return this.#emojiClassForCount(customEmojiCount)
    } else if (customEmojiCount === 0) {
      // Only regular emojis
      if (!stripped || !stripped.match(EMOJI_ONLY_MATCHER)) return ""
      return this.#emojiClassForCount(this.#countEmoji(stripped))
    } else {
      // Mix of custom and regular emojis
      if (!stripped.match(EMOJI_ONLY_MATCHER)) return ""
      const totalCount = customEmojiCount + this.#countEmoji(stripped)
      return this.#emojiClassForCount(totalCount)
    }
  }

  #emojiClassForCount(count) {
    switch (count) {
      case 1: return "message--emoji message--emoji-1"
      case 2: return "message--emoji message--emoji-2"
      case 3: return "message--emoji message--emoji-3"
      default: return "message--emoji"
    }
  }

  #countEmoji(text) {
    // Reset lastIndex for global regex
    EMOJI_PATTERN.lastIndex = 0
    const matches = text.match(EMOJI_PATTERN)
    return matches ? matches.length : 0
  }

  #countCustomEmoji(node) {
    if (!node.querySelectorAll) return 0
    return node.querySelectorAll('figure[data-trix-attachment*="custom-emoji"], .custom-emoji').length
  }
}
