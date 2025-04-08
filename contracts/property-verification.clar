;; property-verification.clar
;; This contract validates property ownership and condition

(define-data-var contract-owner principal tx-sender)

;; Property data structure
(define-map properties
  { property-id: uint }
  {
    owner: principal,
    address: (string-utf8 256),
    verified: bool,
    condition-score: uint,
    last-inspection: uint
  }
)

;; Authorized inspectors
(define-map authorized-inspectors
  { inspector: principal }
  { authorized: bool }
)

;; Initialize contract
(define-public (initialize)
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u100))
    (ok true)
  )
)

;; Add a new property
(define-public (register-property (property-id uint) (address (string-utf8 256)))
  (begin
    (asserts! (not (default-to false (get verified (map-get? properties { property-id: property-id })))) (err u101))
    (map-set properties
      { property-id: property-id }
      {
        owner: tx-sender,
        address: address,
        verified: false,
        condition-score: u0,
        last-inspection: u0
      }
    )
    (ok true)
  )
)

;; Authorize an inspector
(define-public (add-inspector (inspector principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u102))
    (map-set authorized-inspectors
      { inspector: inspector }
      { authorized: true }
    )
    (ok true)
  )
)

;; Remove an inspector
(define-public (remove-inspector (inspector principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err u103))
    (map-delete authorized-inspectors { inspector: inspector })
    (ok true)
  )
)

;; Verify a property
(define-public (verify-property (property-id uint) (condition-score uint))
  (let (
    (property (unwrap! (map-get? properties { property-id: property-id }) (err u104)))
    (inspector-status (default-to { authorized: false } (map-get? authorized-inspectors { inspector: tx-sender })))
  )
    (asserts! (get authorized inspector-status) (err u105))
    (asserts! (<= condition-score u10) (err u106))

    (map-set properties
      { property-id: property-id }
      (merge property {
        verified: true,
        condition-score: condition-score,
        last-inspection: block-height
      })
    )
    (ok true)
  )
)

;; Get property details
(define-read-only (get-property (property-id uint))
  (map-get? properties { property-id: property-id })
)

;; Check if inspector is authorized
(define-read-only (is-authorized-inspector (inspector principal))
  (default-to false (get authorized (map-get? authorized-inspectors { inspector: inspector })))
)
