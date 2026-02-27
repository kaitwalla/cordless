import { Controller } from "@hotwired/stimulus"

const unfurled_attachment_selector = ".og-embed"

export default class extends Controller {
  static targets = [ "body", "link", "author" ]
  static outlets = [ "composer" ]

  connect() {
    this.#formatLinkTargets()
  }

  reply() {
    if (this.#hasAttachment && this.#hasThumbnail) {
      this.composerOutlet.replaceWithReplyAttachment(this.#replyAttachmentData)
    } else {
      const content = this.#hasAttachment
        ? this.#attachmentReplyContent
        : this.#textReplyContent

      this.composerOutlet.replaceMessageContent(content)
    }
  }

  get #hasThumbnail() {
    return this.bodyTarget.dataset.replyThumbnailUrl !== undefined
  }

  get #replyAttachmentData() {
    return {
      sgid: this.bodyTarget.dataset.replySgid,
      thumbnailUrl: this.bodyTarget.dataset.replyThumbnailUrl,
      filename: this.bodyTarget.dataset.replyAttachmentName,
      author: this.authorTarget.textContent,
      href: this.linkTarget.href
    }
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
    const filename = this.#escapeHtml(this.bodyTarget.dataset.replyAttachmentName)
    return `<blockquote><a href="${this.linkTarget.href}">${filename}</a></blockquote><cite>${this.authorTarget.innerHTML} ${this.#linkToOriginal}</cite><br>`
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
    return this.#stripReplyAttachments(this.#stripMentionAttachments(this.#stripUnfurledAttachments(body))).innerHTML
  }

  #stripReplyAttachments(node) {
    node.querySelectorAll(".reply-attachment").forEach(reply => reply.remove())
    return node
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
