import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"

export default class extends Controller {
  static targets = ["count", "indicator"]
  static values = { roomId: Number }
  static classes = ["active"]

  connect() {
    this.participantCount = 0
    this.isDisconnected = false
    this.#fetchInitialState()
    this.#subscribeToCallChannel()
  }

  disconnect() {
    this.isDisconnected = true
    this.channel?.unsubscribe()
  }

  async #fetchInitialState() {
    try {
      const response = await fetch("/rooms/call_statuses")
      if (response.ok) {
        const data = await response.json()
        const roomData = data[this.roomIdValue]
        if (roomData) {
          this.participantCount = roomData.participant_count
          this.#updateIndicator()
        }
      }
    } catch (error) {
      console.warn("Failed to fetch call status:", error)
    }
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
    if (data.type === "call_joined" || data.type === "call_left") {
      // Use server-provided count if available, otherwise increment/decrement
      if (typeof data.participant_count === "number") {
        this.participantCount = data.participant_count
      } else if (data.type === "call_joined") {
        this.participantCount++
      } else {
        this.participantCount = Math.max(0, this.participantCount - 1)
      }
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
