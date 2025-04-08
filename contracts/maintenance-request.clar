;; maintenance-request.clar
;; This contract tracks repair needs and resolutions

(define-data-var contract-owner principal tx-sender)

;; Request status enum
(define-constant STATUS-OPEN u0)
(define-constant STATUS-IN-PROGRESS u1)
(define-constant STATUS-COMPLETED u2)
(define-constant STATUS-CANCELLED u3)

;; Priority enum
(define-constant PRIORITY-LOW u0)
(define-constant PRIORITY-MEDIUM u1)
(define-constant PRIORITY-HIGH u2)
(define-constant PRIORITY-EMERGENCY u3)

;; Maintenance request data structure
(define-map maintenance-requests
  { request-id: uint }
  {
    lease-id: uint,
    property-id: uint,
    requester: principal,
    description: (string-utf8 500),
    priority: uint,
    status: uint,
    created-at: uint,
    updated-at: uint,
    assigned-to: (optional principal),
    resolution-notes: (optional (string-utf8 500))
  }
)

;; Request counter
(define-data-var request-counter uint u0)

;; Authorized maintenance providers
(define-map maintenance-providers
  { provider: principal }
  { authorized: bool }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u400))
    (ok true)
  )
)

;; Add a maintenance provider
(define-public (add-maintenance-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u401))
    (map-set maintenance-providers
      { provider: provider }
      { authorized: true }
    )
    (ok true)
  )
)

;; Remove a maintenance provider
(define-public (remove-maintenance-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u402))
    (map-delete maintenance-providers { provider: provider })
    (ok true)
  )
)

;; Create a maintenance request
(define-public (create-request
  (lease-id uint)
  (property-id uint)
  (description (string-utf8 500))
  (priority uint)
)
  (let (
    (request-id (var-get request-counter))
  )
    (asserts! (<= priority PRIORITY-EMERGENCY) (err u403))

    (map-set maintenance-requests
      { request-id: request-id }
      {
        lease-id: lease-id,
        property-id: property-id,
        requester: tx-sender,
        description: description,
        priority: priority,
        status: STATUS-OPEN,
        created-at: block-height,
        updated-at: block-height,
        assigned-to: none,
        resolution-notes: none
      }
    )

    (var-set request-counter (+ request-id u1))

    (ok request-id)
  )
)

;; Assign a request to a maintenance provider
(define-public (assign-request (request-id uint) (provider principal))
  (let (
    (request (unwrap! (map-get? maintenance-requests { request-id: request-id }) (err u404)))
    (provider-status (default-to { authorized: false } (map-get? maintenance-providers { provider: provider })))
  )
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u405))
    (asserts! (get authorized provider-status) (err u406))
    (asserts! (is-eq (get status request) STATUS-OPEN) (err u407))

    (map-set maintenance-requests
      { request-id: request-id }
      (merge request {
        status: STATUS-IN-PROGRESS,
        assigned-to: (some provider),
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Update request status (by assigned provider)
(define-public (update-request-status (request-id uint) (new-status uint) (notes (optional (string-utf8 500))))
  (let (
    (request (unwrap! (map-get? maintenance-requests { request-id: request-id }) (err u408)))
    (assigned-provider (unwrap! (get assigned-to request) (err u409)))
  )
    (asserts! (is-eq tx-sender assigned-provider) (err u410))
    (asserts! (or (is-eq new-status STATUS-IN-PROGRESS) (is-eq new-status STATUS-COMPLETED)) (err u411))

    (map-set maintenance-requests
      { request-id: request-id }
      (merge request {
        status: new-status,
        updated-at: block-height,
        resolution-notes: (if (is-some notes) notes (get resolution-notes request))
      })
    )

    (ok true)
  )
)

;; Cancel a request (by requester)
(define-public (cancel-request (request-id uint))
  (let (
    (request (unwrap! (map-get? maintenance-requests { request-id: request-id }) (err u412)))
  )
    (asserts! (is-eq tx-sender (get requester request)) (err u413))
    (asserts! (is-eq (get status request) STATUS-OPEN) (err u414))

    (map-set maintenance-requests
      { request-id: request-id }
      (merge request {
        status: STATUS-CANCELLED,
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Get request details
(define-read-only (get-request (request-id uint))
  (map-get? maintenance-requests { request-id: request-id })
)

;; Check if provider is authorized
(define-read-only (is-authorized-provider (provider principal))
  (default-to false (get authorized (map-get? maintenance-providers { provider: provider })))
)
