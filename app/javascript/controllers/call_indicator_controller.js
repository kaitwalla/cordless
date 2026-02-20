import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["count", "indicator"]
  static values = { roomId: Number }
  static classes = ["active"]

  connect() {
    this.participantCount = 0
    this.isDisconnected = false
    this.#subscribeToCallChannel()
  }

  disconnect() {
    this.isDisconnected = true
    this.channel?.unsubscribe()
  }

  async #subscribeToCallChannel() {
    const channel = await cable.subscribeTo(
      { channel: "RoomChannel", room_id: this.roomIdValue },
      { received: this.#handleMessage.bind(this) }
    )

    if (this.isDisconnected) {
      channel.unsubscribe()
      return
    }

    this.channel = channel
  }

  #handleMessage(data) {
    if (data.type === "call_joined") {
      this.participantCount++
      this.#updateIndicator()
    } else if (data.type === "call_left") {
      this.participantCount = Math.max(0, this.participantCount - 1)
      this.#updateIndicator()
    }
  }

  #updateIndicator() {
    const hasParticipants = this.participantCount > 0

    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.toggle(this.activeClass, hasParticipants)
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = this.participantCount
      this.countTarget.hidden = !hasParticipants
    }
  }
}
