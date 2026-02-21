import { Controller } from "@hotwired/stimulus"
import { cable } from "@hotwired/turbo-rails"
import { get } from "@rails/request.js"
import { Room, RoomEvent, Track, VideoPresets } from "livekit-client"

const TOKEN_REFRESH_INTERVAL = 55 * 60 * 1000 // 55 minutes
const PANEL_CONTAINER_ID = "call-panel-container"

export default class extends Controller {
  static values = {
    roomId: Number,
    tokenUrl: String,
    minimizeIconUrl: String,
    maximizeIconUrl: String,
    microphoneIconUrl: String,
    microphoneOffIconUrl: String,
    videoIconUrl: String,
    videoOffIconUrl: String,
    screenShareIconUrl: String,
    screenShareOffIconUrl: String,
    phoneOffIconUrl: String
  }

  connect() {
    // Check if there's an existing call for this room
    this.#checkExistingCall()
  }

  disconnect() {
    // Clean up if this controller instance initiated the call
    if (window.activeCall?.roomId === this.roomIdValue && this.room) {
      this.#cleanup()
    }
  }

  async join() {
    // Guard against concurrent join attempts
    if (this.joining) return
    this.joining = true

    try {
      // Check if already in a call
      if (window.activeCall) {
        if (window.activeCall.roomId === this.roomIdValue) {
          // Already in this room's call, just ensure panel is visible
          this.#showPanel()
          return
        } else {
          // In a different call, leave it first
          await window.activeCall.leave()
        }
      }

      const { token, url, user_name } = await this.#fetchToken()

      this.room = new Room({
        adaptiveStream: true,
        dynacast: true,
        videoCaptureDefaults: {
          resolution: VideoPresets.h720.resolution
        }
      })

      this.participants = new Map()
      this.callStartTime = Date.now()
      this.userName = user_name

      this.#setupRoomEventHandlers()
      this.#createPanel()

      await this.room.connect(url, token)

      // Start with audio only, video off (privacy-respecting default)
      try {
        await this.room.localParticipant.setMicrophoneEnabled(true)
      } catch (e) {
        console.warn("Could not enable microphone:", e)
        // Continue without microphone - user can retry via UI
      }
      await this.room.localParticipant.setCameraEnabled(false)

      this.#startDurationTimer()
      this.#scheduleTokenRefresh()
      this.#notifyCallChannel("joined")

      // Store global reference so other instances can check
      window.activeCall = {
        roomId: this.roomIdValue,
        leave: this.leave.bind(this)
      }
    } catch (error) {
      console.error("Failed to join call:", error)
      this.#cleanup()
    } finally {
      this.joining = false
    }
  }

  async leave() {
    this.#notifyCallChannel("left")
    this.#cleanup()
    this.#removePanel()
    window.activeCall = null
  }

  // Panel action handlers (called via event delegation)
  async handlePanelAction(event) {
    const action = event.target.closest("[data-call-action]")?.dataset.callAction
    if (!action) return

    try {
      switch (action) {
        case "toggleAudio": await this.#toggleAudio(); break
        case "toggleVideo": await this.#toggleVideo(); break
        case "toggleScreenShare": await this.#toggleScreenShare(); break
        case "toggleMini": this.#toggleMini(); break
        case "leave": await this.leave(); break
      }
    } catch (error) {
      console.error(`Failed to execute ${action}:`, error)
    }
  }

  // Private methods

  #checkExistingCall() {
    if (window.activeCall && window.activeCall.roomId === this.roomIdValue) {
      this.element.classList.add("call-button--in-call")
    }
  }

  async #fetchToken() {
    const response = await get(this.tokenUrlValue, { responseKind: "json" })

    if (response.ok) {
      return response.json
    } else {
      throw new Error("Failed to fetch token")
    }
  }

  #setupRoomEventHandlers() {
    this.room
      .on(RoomEvent.ParticipantConnected, this.#handleParticipantConnected.bind(this))
      .on(RoomEvent.ParticipantDisconnected, this.#handleParticipantDisconnected.bind(this))
      .on(RoomEvent.TrackSubscribed, this.#handleTrackSubscribed.bind(this))
      .on(RoomEvent.TrackUnsubscribed, this.#handleTrackUnsubscribed.bind(this))
      .on(RoomEvent.LocalTrackPublished, this.#handleLocalTrackPublished.bind(this))
      .on(RoomEvent.LocalTrackUnpublished, this.#handleLocalTrackUnpublished.bind(this))
      .on(RoomEvent.Disconnected, this.#handleDisconnected.bind(this))
  }

  #handleParticipantConnected(participant) {
    this.participants.set(participant.identity, participant)
    this.#renderParticipant(participant)
    this.#updateParticipantCount()
  }

  #handleParticipantDisconnected(participant) {
    this.participants.delete(participant.identity)
    this.#removeParticipantElement(participant.identity)
    this.#updateParticipantCount()
  }

  #handleTrackSubscribed(track, publication, participant) {
    const element = this.#getOrCreateParticipantElement(participant.identity)

    if (track.kind === Track.Kind.Video) {
      const video = element.querySelector("video")
      if (video) track.attach(video)
    } else if (track.kind === Track.Kind.Audio) {
      const audio = element.querySelector("audio")
      if (audio) track.attach(audio)
    }
  }

  #handleTrackUnsubscribed(track) {
    track.detach()
  }

  #handleLocalTrackPublished(publication) {
    const track = publication.track
    if (!track) return

    const localVideo = this.panel?.querySelector("[data-local-video]")
    if (track.kind === Track.Kind.Video && localVideo) {
      track.attach(localVideo)
      localVideo.closest(".call-participant")?.classList.remove("call-participant--no-video")
    }
  }

  #handleLocalTrackUnpublished(publication) {
    const track = publication.track
    if (track) {
      track.detach()
      if (track.kind === Track.Kind.Video) {
        const localVideo = this.panel?.querySelector("[data-local-video]")
        localVideo?.closest(".call-participant")?.classList.add("call-participant--no-video")
      }
    }
  }

  #handleDisconnected() {
    this.#cleanup()
    this.#removePanel()
    window.activeCall = null
  }

  #renderParticipant(participant) {
    this.#getOrCreateParticipantElement(participant.identity)

    // Attach existing tracks
    participant.trackPublications.forEach((publication) => {
      if (publication.isSubscribed && publication.track) {
        this.#handleTrackSubscribed(publication.track, publication, participant)
      }
    })
  }

  #getOrCreateParticipantElement(identity) {
    const container = this.panel?.querySelector("[data-participants]")
    if (!container) return null

    const escapedIdentity = CSS.escape(identity)
    let element = container.querySelector(`[data-participant-id="${escapedIdentity}"]`)

    if (!element) {
      element = document.createElement("div")
      element.className = "call-participant"
      element.dataset.participantId = identity
      element.innerHTML = `
        <div class="call-participant__media">
          <video autoplay playsinline></video>
          <audio autoplay></audio>
        </div>
        <div class="call-participant__name"></div>
      `
      container.appendChild(element)

      const participant = this.participants.get(identity)
      if (participant) {
        element.querySelector(".call-participant__name").textContent = participant.name || identity
      }
    }

    return element
  }

  #removeParticipantElement(identity) {
    const container = this.panel?.querySelector("[data-participants]")
    const escapedIdentity = CSS.escape(identity)
    const element = container?.querySelector(`[data-participant-id="${escapedIdentity}"]`)
    element?.remove()
  }

  #updateParticipantCount() {
    const countEl = this.panel?.querySelector("[data-participant-count]")
    if (countEl) {
      const count = this.participants.size + 1
      countEl.textContent = count
    }
  }

  async #toggleAudio() {
    if (!this.room) return

    const enabled = this.room.localParticipant.isMicrophoneEnabled
    await this.room.localParticipant.setMicrophoneEnabled(!enabled)

    const btn = this.panel?.querySelector("[data-call-action='toggleAudio']")
    btn?.classList.toggle("call-control--muted", enabled)
    btn?.setAttribute("aria-pressed", !enabled)
  }

  async #toggleVideo() {
    if (!this.room) return

    const enabled = this.room.localParticipant.isCameraEnabled
    await this.room.localParticipant.setCameraEnabled(!enabled)

    const btn = this.panel?.querySelector("[data-call-action='toggleVideo']")
    btn?.classList.toggle("call-control--off", enabled)
    btn?.setAttribute("aria-pressed", !enabled)
  }

  async #toggleScreenShare() {
    if (!this.room) return

    const enabled = this.room.localParticipant.isScreenShareEnabled
    await this.room.localParticipant.setScreenShareEnabled(!enabled)

    const btn = this.panel?.querySelector("[data-call-action='toggleScreenShare']")
    btn?.classList.toggle("call-control--active", !enabled)
    btn?.setAttribute("aria-pressed", !enabled)
  }

  #toggleMini() {
    this.panel?.classList.toggle("call-pip--mini")
    try {
      localStorage.setItem("call-panel-mini", this.panel?.classList.contains("call-pip--mini"))
    } catch {
      // Ignore storage errors
    }
  }

  #startDurationTimer() {
    this.#updateDuration()
    this.durationTimer = setInterval(() => this.#updateDuration(), 1000)
  }

  #updateDuration() {
    const durationEl = this.panel?.querySelector("[data-duration]")
    if (durationEl && this.callStartTime) {
      const elapsed = Math.floor((Date.now() - this.callStartTime) / 1000)
      const minutes = Math.floor(elapsed / 60)
      const seconds = elapsed % 60
      durationEl.textContent = `${minutes}:${seconds.toString().padStart(2, "0")}`
    }
  }

  #scheduleTokenRefresh() {
    this.tokenRefreshTimer = setTimeout(async () => {
      if (this.room) {
        try {
          const { token } = await this.#fetchToken()
          // Apply the new token to the room
          if (this.room.state === "connected") {
            await this.room.refreshToken(token)
          }
          this.#scheduleTokenRefresh()
        } catch (error) {
          console.error("Failed to refresh token:", error)
        }
      }
    }, TOKEN_REFRESH_INTERVAL)
  }

  async #notifyCallChannel(action) {
    if (!this.callChannel) {
      this.callChannel = await cable.subscribeTo(
        { channel: "CallChannel", room_id: this.roomIdValue },
        { received: () => {} }
      )
    }

    this.callChannel.send({ action })
  }

  #createPanel() {
    const container = document.getElementById(PANEL_CONTAINER_ID)
    if (!container) return

    // Remove any existing panel
    container.innerHTML = ""

    this.panel = document.createElement("div")
    this.panel.className = "call-pip call-pip--active"
    this.panel.dataset.controller = "call-pip"
    this.panel.addEventListener("click", this.handlePanelAction.bind(this))

    // Restore mini state preference
    try {
      if (localStorage.getItem("call-panel-mini") === "true") {
        this.panel.classList.add("call-pip--mini")
      }
    } catch {
      // Ignore storage errors
    }

    // Use asset URLs from values if available, fallback to basic paths
    const minimizeIcon = this.hasMinimizeIconUrlValue ? this.minimizeIconUrlValue : "/assets/minimize.svg"
    const maximizeIcon = this.hasMaximizeIconUrlValue ? this.maximizeIconUrlValue : "/assets/maximize.svg"
    const microphoneIcon = this.hasMicrophoneIconUrlValue ? this.microphoneIconUrlValue : "/assets/microphone.svg"
    const microphoneOffIcon = this.hasMicrophoneOffIconUrlValue ? this.microphoneOffIconUrlValue : "/assets/microphone-off.svg"
    const videoIcon = this.hasVideoIconUrlValue ? this.videoIconUrlValue : "/assets/video.svg"
    const videoOffIcon = this.hasVideoOffIconUrlValue ? this.videoOffIconUrlValue : "/assets/video-off.svg"
    const screenShareIcon = this.hasScreenShareIconUrlValue ? this.screenShareIconUrlValue : "/assets/screen-share.svg"
    const screenShareOffIcon = this.hasScreenShareOffIconUrlValue ? this.screenShareOffIconUrlValue : "/assets/screen-share-off.svg"
    const phoneOffIcon = this.hasPhoneOffIconUrlValue ? this.phoneOffIconUrlValue : "/assets/phone-off.svg"

    this.panel.innerHTML = `
      <div class="call-pip__header" data-call-pip-target="handle" data-action="mousedown->call-pip#startDrag">
        <span class="call-pip__duration" data-duration>0:00</span>
        <span class="call-pip__participant-count">
          <span data-participant-count>1</span> in call
        </span>
        <button class="btn btn--small call-pip__toggle-size" data-call-action="toggleMini" aria-label="Toggle panel size">
          <img src="${minimizeIcon}" width="16" height="16" alt="" class="call-pip__minimize-icon">
          <img src="${maximizeIcon}" width="16" height="16" alt="" class="call-pip__maximize-icon">
        </button>
      </div>

      <div class="call-pip__video-grid">
        <div class="call-participant call-participant--local call-participant--no-video">
          <div class="call-participant__media">
            <video data-local-video autoplay playsinline muted></video>
          </div>
          <div class="call-participant__name">${this.#escapeHtml(this.userName || "You")}</div>
        </div>
        <div class="call-pip__participants" data-participants></div>
      </div>

      <div class="call-pip__controls">
        <button class="btn call-control" data-call-action="toggleAudio" aria-label="Toggle microphone" aria-pressed="true">
          <img src="${microphoneIcon}" width="20" height="20" alt="" class="call-control__on-icon">
          <img src="${microphoneOffIcon}" width="20" height="20" alt="" class="call-control__off-icon">
        </button>

        <button class="btn call-control call-control--off" data-call-action="toggleVideo" aria-label="Toggle camera" aria-pressed="false">
          <img src="${videoIcon}" width="20" height="20" alt="" class="call-control__on-icon">
          <img src="${videoOffIcon}" width="20" height="20" alt="" class="call-control__off-icon">
        </button>

        <button class="btn call-control" data-call-action="toggleScreenShare" aria-label="Toggle screen share" aria-pressed="false">
          <img src="${screenShareIcon}" width="20" height="20" alt="" class="call-control__on-icon">
          <img src="${screenShareOffIcon}" width="20" height="20" alt="" class="call-control__off-icon">
        </button>

        <button class="btn call-control call-control--leave" data-call-action="leave" aria-label="Leave call">
          <img src="${phoneOffIcon}" width="20" height="20" alt="">
        </button>
      </div>
    `

    container.appendChild(this.panel)
  }

  #showPanel() {
    this.panel?.classList.add("call-pip--active")
  }

  #removePanel() {
    this.panel?.remove()
    this.panel = null
  }

  #cleanup() {
    clearInterval(this.durationTimer)
    clearTimeout(this.tokenRefreshTimer)

    if (this.room) {
      this.room.disconnect()
      this.room = null
    }

    this.callChannel?.unsubscribe()
    this.callChannel = null

    this.participants?.clear()
    this.callStartTime = null

    this.element.classList.remove("call-button--in-call")
  }

  #escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
