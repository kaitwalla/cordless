import { Controller } from "@hotwired/stimulus"

const unfurled_attachment_selector = ".og-embed"

export default class extends Controller {
  static targets = [ "body", "link", "author" ]
  static outlets = [ "composer" ]

  connect() {
    this.#formatLinkTargets()
  }

  reply() {
    const content = this.#hasAttachment
      ? this.#attachmentReplyContent
      : this.#textReplyContent

    this.composerOutlet.replaceMessageContent(content)
  }

  #formatLinkTargets() {
    this.bodyTarget.querySelectorAll("a").forEach(link => {
      const sameDomain = link.href.startsWith(window.location.origin)
      link.target = sameDomain ? "_top" : "_blank"
    })
  }

  get #hasAttachment() {
    return this.bodyTarget.dataset.replyAttachmentName !== undefined
  }

  get #attachmentReplyContent() {
    const thumbnailUrl = this.bodyTarget.dataset.replyThumbnailUrl
    const filename = this.#escapeHtml(this.bodyTarget.dataset.replyAttachmentName)

    if (thumbnailUrl) {
      return `<blockquote><a href="${this.linkTarget.href}"><img src="${this.#escapeHtml(thumbnailUrl)}" alt="${filename}" class="reply-thumbnail"></a></blockquote><cite>${this.authorTarget.innerHTML} ${this.#linkToOriginal}</cite><br>`
    } else {
      return `<blockquote><a href="${this.linkTarget.href}">${filename}</a></blockquote><cite>${this.authorTarget.innerHTML} ${this.#linkToOriginal}</cite><br>`
    }
  }

  #escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  get #textReplyContent() {
    return `<blockquote>${this.#bodyContent}</blockquote><cite>${this.authorTarget.innerHTML} ${this.#linkToOriginal}</cite><br>`
  }

  get #bodyContent() {
    const body = this.bodyTarget.querySelector(".trix-content").cloneNode(true)
    return this.#stripMentionAttachments(this.#stripUnfurledAttachments(body)).innerHTML
  }

  #stripMentionAttachments(node) {
    node.querySelectorAll(".mention").forEach(mention => mention.outerHTML = mention.textContent.trim())
    return node
  }

  #stripUnfurledAttachments(node) {
    const firstUnfurledLink = node.querySelector(`${unfurled_attachment_selector} a`)?.href
    node.querySelectorAll(unfurled_attachment_selector).forEach(embed => embed.remove())

    // Use unfurled link as the content when the node has no additional text
    if (firstUnfurledLink && !node.textContent.trim()) node.textContent = firstUnfurledLink

    return node
  }

  get #linkToOriginal() {
    return `<a href="${this.linkTarget.href}">#</a>`
  }
}
